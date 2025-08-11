import 'dart:async';
import 'gateway.dart';
import 'rest.dart';

typedef EventCallback = FutureOr<void> Function([dynamic data]);

class DiscordBot {
  final String token;
  late DiscordGateway gateway;
  late DiscordRest rest;

  final Map<String, List<EventCallback>> _eventListeners = {};

  DiscordBot(this.token) {
  gateway = DiscordGateway(token, this);
  rest = DiscordRest(token, gateway);
}

  void on(String eventName, EventCallback callback) {
    _eventListeners.putIfAbsent(eventName, () => []).add(callback);
  }

  Future<void> _triggerEvent(String eventName, [dynamic data]) async {
    final listeners = _eventListeners[eventName];
    if (listeners != null) {
      for (final listener in listeners) {
        await listener(data);
      }
    }
  }

  // Event registration helpers
  void onReady(EventCallback callback) => on('ready', callback);
  void onMessage(EventCallback callback) => on('message_create', callback);
  void onGuildCreate(EventCallback callback) => on('guild_create', callback);
  void onMessageUpdate(EventCallback callback) => on('message_update', callback);
  void onEmbed(EventCallback callback) => on('embed_create', callback);

  // Event triggers
  Future<void> triggerReady() => _triggerEvent('ready');

  Future<void> triggerMessage(dynamic message) async {
    await _triggerEvent('message_create', message);

    if (message is Map && message['embeds'] is List && (message['embeds'] as List).isNotEmpty) {
      for (final embed in message['embeds']) {
        await _triggerEvent('embed_create', embed);
      }
    }
  }

  Future<void> triggerGuildCreate(dynamic guild) =>
      _triggerEvent('guild_create', guild);

  Future<void> triggerMessageUpdate(dynamic message) async {
    await _triggerEvent('message_update', message);

    if (message is Map && message['embeds'] is List && (message['embeds'] as List).isNotEmpty) {
      for (final embed in message['embeds']) {
        await _triggerEvent('embed_create', embed);
      }
    }
  }

  void triggerReactionAdd(dynamic data) {
    final userId = data['user_id'];
    final emoji = data['emoji'];
    final channelId = data['channel_id'];
    final messageId = data['message_id'];

    print('User $userId added reaction ${emoji['name']} to message $messageId in channel $channelId');
  }

  void triggerReactionRemove(dynamic data) {
    final userId = data['user_id'];
    final emoji = data['emoji'];
    final channelId = data['channel_id'];
    final messageId = data['message_id'];

    print('User $userId removed reaction ${emoji['name']} from message $messageId in channel $channelId');
  }

  Future<Map<String, dynamic>> getGuild(String guildId) => rest.getGuild(guildId);

  Future<List<dynamic>> getGuildMembers(String guildId, {int limit = 1000, String? after}) =>
      rest.getGuildMembers(guildId, limit: limit, after: after);

  Future<List<dynamic>> getGuildChannels(String guildId) => rest.getGuildChannels(guildId);

  Future<List<dynamic>> getGuildRoles(String guildId) => rest.getGuildRoles(guildId);

  Future<Map<String, dynamic>> getGuildMember(String guildId, String userId) =>
      rest.getGuildMember(guildId, userId);

  Future<Map<String, dynamic>> createGuildRole(String guildId, Map<String, dynamic> roleData) =>
      rest.createRole(guildId, roleData);

  Future<Map<String, dynamic>> modifyGuildRole(String guildId, String roleId, Map<String, dynamic> roleData) =>
      rest.modifyRole(guildId, roleId, roleData);

  Future<void> deleteGuildRole(String guildId, String roleId) =>
      rest.deleteRole(guildId, roleId);

  Future<void> addRoleToGuildMember(String guildId, String userId, String roleId) =>
      rest.addRoleToMember(guildId, userId, roleId);

  Future<void> removeRoleFromGuildMember(String guildId, String userId, String roleId) =>
      rest.removeRoleFromMember(guildId, userId, roleId);

  void triggerChannelCreate(Map<String, dynamic> data) {
    print('Channel created: ${data['name']}');
  }

  void triggerChannelUpdate(Map<String, dynamic> data) {
    print('Channel updated: ${data['name']}');
  }

  void triggerChannelDelete(Map<String, dynamic> data) {
    print('Channel deleted: ID ${data['id']}');
  }

  Future<Map<String, dynamic>> createChannel(String guildId, Map<String, dynamic> channelData) async {
    final channel = await rest.createChannel(guildId, channelData);
    gateway.addOrUpdateChannel(channel['id'], channel);
    return channel;
  }

  Future<Map<String, dynamic>> modifyChannel(String channelId, Map<String, dynamic> channelData) async {
    final channel = await rest.modifyChannel(channelId, channelData);
    gateway.addOrUpdateChannel(channel['id'], channel);
    return channel;
  }

  Future<void> deleteChannel(String channelId) async {
  try {
    await rest.deleteChannel(channelId);
  } catch (e) {
    // Log error but still remove from cache since channel likely deleted
    print('Warning: deleteChannel REST failed: $e');
  }
  gateway.removeChannel(channelId);
}


  Future<void> login() async {
    await gateway.connect();
  }
}
