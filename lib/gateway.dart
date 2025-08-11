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

    // Update sequence number for resuming
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

      case 1: // Heartbeat request from server
        _sendHeartbeat();
        break;

      case 0: // Dispatch
        _handleDispatch(t, d);
        // Save session ID on READY event
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
        Future.delayed(Duration(seconds: 5), () {
          _identify();
        });
        break;

      default:
        print('Unhandled OP code: $op');
    }
  }

  Future<void> _handleDispatch(String? type, dynamic data) async {
  print("DISPATCH: $type");
  if (type == 'READY') {
    bot.triggerReady();
  } else if (type == 'MESSAGE_CREATE') {
    print("MESSAGE_CREATE: $data");
    bot.triggerMessage(data);
  } else if (type == 'MESSAGE_UPDATE') {
    print("MESSAGE_UPDATE: $data");
    bot.triggerMessageUpdate(data);
  } else if (type == 'MESSAGE_REACTION_ADD') {
    print("MESSAGE_REACTION_ADD: $data");
    bot.triggerReactionAdd(data);
  } else if (type == 'MESSAGE_REACTION_REMOVE') {
    print("MESSAGE_REACTION_REMOVE: $data");
    bot.triggerReactionRemove(data);
  } else if (type == 'GUILD_ROLE_CREATE') {
    print("GUILD_ROLE_CREATE: $data");
    final guildId = data['guild_id'];
    final roleData = data['role'];
    print("Role created: ${roleData['name']} (ID: ${roleData['id']}) in guild $guildId");
  } else if (type == 'GUILD_ROLE_UPDATE') {
    print("GUILD_ROLE_UPDATE: $data");
    final guildId = data['guild_id'];
    final roleId = data['role']['id'];
    final roleData = data['role'];
    print("Role updated: ${roleData['name']} (ID: ${roleData['id']}) in guild $guildId");
  } else if (type == 'GUILD_ROLE_DELETE') {
    print("GUILD_ROLE_DELETE: $data");
    final guildId = data['guild_id'];
    final roleId = data['role_id'];
    print("Role deleted: $roleId in guild $guildId");
  }
}

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _receivedHeartbeatAck = true;

    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: _heartbeatInterval!),
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
      "op": 1,
      "d": _lastSequence
    };
    _ws!.sink.add(jsonEncode(payload));
    print('Heartbeat sent with sequence $_lastSequence');
  }

  void _identify() {
    print('Sending Identify payload...');
    final payload = {
      "op": 2,
      "d": {
        "token": token,
        "intents": 1 | 512 | 32768, // GUILDS + GUILD_MESSAGES + MESSAGE_CONTENT
        "properties": {
          "\$os": "linux",
          "\$browser": "dartcord",
          "\$device": "dartcord"
        }
      }
    };
    _ws!.sink.add(jsonEncode(payload));
  }

  void _resume() {
    print('Attempting to resume session...');
    final payload = {
      "op": 6,
      "d": {
        "token": token,
        "session_id": _sessionId,
        "seq": _lastSequence
      }
    };
    _ws!.sink.add(jsonEncode(payload));
  }

  void _handleDisconnect() {
    print('Disconnected from Gateway, attempting to reconnect...');
    _reconnect();
  }

  void _reconnect() async {
    _heartbeatTimer?.cancel();
    await Future.delayed(Duration(seconds: 5)); // wait a bit before reconnect
    await connect();
  }
}
