import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'client.dart';

class DiscordGateway {
  final String token;
  final DiscordBot bot;

  WebSocketChannel? _ws;
  Timer? _heartbeatTimer;
  int? _heartbeatInterval;
  int? _lastSequence;
  String? _sessionId;

  bool _receivedHeartbeatAck = true;

  DiscordGateway(this.token, this.bot);

  Future<void> connect() async {
    print('Connecting to Discord Gateway...');
    _ws = WebSocketChannel.connect(
      Uri.parse("wss://gateway.discord.gg/?v=10&encoding=json"),
    );

    _ws!.stream.listen(
      (data) => _handleEvent(jsonDecode(data)),
      onDone: _handleDisconnect,
      onError: (error) {
        print('WebSocket error: $error');
        _reconnect();
      },
      cancelOnError: true,
    );
  }

  void _handleEvent(Map<String, dynamic> event) {
    final op = event['op'];
    final t = event['t'];
    final d = event['d'];
    final s = event['s'];

    if (s != null) _lastSequence = s;

    switch (op) {
      case 10: // Hello
        _heartbeatInterval = d['heartbeat_interval'];
        _startHeartbeat();
        if (_sessionId != null) {
          _resume();
        } else {
          _identify();
        }
        break;

      case 11: // Heartbeat ACK
        _receivedHeartbeatAck = true;
        print('Heartbeat acknowledged');
        break;

      case 1: // Heartbeat request
        _sendHeartbeat();
        break;

      case 0: // Dispatch
        _handleDispatch(t, d);
        if (t == 'READY') {
          _sessionId = d['session_id'];
        }
        break;

      case 7: // Reconnect
        print('Server requested reconnect.');
        _reconnect();
        break;

      case 9: // Invalid Session
        print('Invalid session, re-identifying...');
        _sessionId = null;
        _lastSequence = null;
        Future.delayed(Duration(seconds: 5), _identify);
        break;

      default:
        print('Unhandled OP code: $op');
    }
  }

  final Map<String, Map<String, dynamic>> _channels = {};

  Map<String, Map<String, dynamic>> get channels => _channels;

  Future<void> _handleDispatch(String? type, dynamic data) async {
    print("DISPATCH: $type");
    switch (type) {
      case 'READY':
        await bot.triggerReady();
        break;
      case 'MESSAGE_CREATE':
        print("MESSAGE_CREATE: $data");
        await bot.triggerMessage(data);
        break;
      case 'MESSAGE_UPDATE':
        print("MESSAGE_UPDATE: $data");
        await bot.triggerMessageUpdate(data);
        break;
      case 'MESSAGE_REACTION_ADD':
        print("MESSAGE_REACTION_ADD: $data");
        bot.triggerReactionAdd(data);
        break;
      case 'MESSAGE_REACTION_REMOVE':
        print("MESSAGE_REACTION_REMOVE: $data");
        bot.triggerReactionRemove(data);
        break;
      case 'GUILD_ROLE_CREATE':
        print("GUILD_ROLE_CREATE: $data");
        final guildId = data['guild_id'];
        final roleData = data['role'];
        print("Role created: ${roleData['name']} (ID: ${roleData['id']}) in guild $guildId");
        break;
      case 'GUILD_ROLE_UPDATE':
        print("GUILD_ROLE_UPDATE: $data");
        final guildId = data['guild_id'];
        final roleData = data['role'];
        print("Role updated: ${roleData['name']} (ID: ${roleData['id']}) in guild $guildId");
        break;
      case 'GUILD_ROLE_DELETE':
        print("GUILD_ROLE_DELETE: $data");
        final guildId = data['guild_id'];
        final roleId = data['role_id'];
        print("Role deleted: $roleId in guild $guildId");
        break;
      case 'CHANNEL_CREATE':
        final channelId = data['id'];
        _channels[channelId] = data;
        print('Channel created: ${data['name']} (ID: $channelId)');
        bot.triggerChannelCreate(data);
        break;
      case 'CHANNEL_UPDATE':
        final channelId = data['id'];
        _channels[channelId] = data;
        print('Channel updated: ${data['name']} (ID: $channelId)');
        bot.triggerChannelUpdate(data);
        break;
      case 'CHANNEL_DELETE':
        final channelId = data['id'];
        _channels.remove(channelId);
        print('Channel deleted: ID $channelId');
        bot.triggerChannelDelete(data);
        break;
      case 'THREAD_CREATE':
        final threadId = data['id'];
        _channels[threadId] = data;
        print('Thread created: ${data['name']} (ID: $threadId)');
        bot.triggerThreadCreate(data);
        break;
      case 'THREAD_UPDATE':
        final threadId = data['id'];
        _channels[threadId] = data;
        print('Thread updated: ${data['name']} (ID: $threadId)');
        bot.triggerThreadUpdate(data);
        break;
      case 'THREAD_DELETE':
        final threadId = data['id'];
        _channels.remove(threadId);
        print('Thread deleted: ID $threadId');
        bot.triggerThreadDelete(data);
        break;
      default:
        // Ignore unknown dispatches or add logging if needed
        break;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _receivedHeartbeatAck = true;

    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: _heartbeatInterval ?? 0),
      (_) {
        if (!_receivedHeartbeatAck) {
          print('Heartbeat ACK not received, reconnecting...');
          _reconnect();
          return;
        }
        _sendHeartbeat();
        _receivedHeartbeatAck = false;
      },
    );
  }

  void _sendHeartbeat() {
    final payload = {
      'op': 1,
      'd': _lastSequence,
    };
    _ws?.sink.add(jsonEncode(payload));
    print('Sent heartbeat');
  }

  void _identify() {
    final identifyPayload = {
      "op": 2,
      "d": {
        "token": token,
        "intents": 1 | 512 | 32768,
        "properties": {
          "\$os": "linux",
          "\$browser": "disco",
          "\$device": "disco"
        }
      }
    };
    _ws?.sink.add(jsonEncode(identifyPayload));
    print('Sent identify');
  }

  void _resume() {
    final resumePayload = {
      "op": 6,
      "d": {
        "token": token,
        "session_id": _sessionId,
        "seq": _lastSequence,
      }
    };
    _ws?.sink.add(jsonEncode(resumePayload));
    print('Sent resume');
  }

  void _handleDisconnect() {
    print('Disconnected from gateway, reconnecting...');
    _reconnect();
  }

  void _reconnect() {
    _heartbeatTimer?.cancel();
    _ws?.sink.close();
    _ws = null;
    _sessionId = null;
    _lastSequence = null;
    // Try reconnecting after a short delay
    Future.delayed(Duration(seconds: 5), () => connect());
  }

  void addOrUpdateChannel(String id, Map<String, dynamic> channelData) {
  _channels[id] = channelData;
}

  void removeChannel(String id) {
  _channels.remove(id);
}
}
