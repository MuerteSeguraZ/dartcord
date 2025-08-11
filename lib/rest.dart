import 'dart:convert';
import 'package:http/http.dart' as http;
import 'gateway.dart';

class DiscordRest {
  final String token;
  final String baseUrl = "https://discord.com/api/v10";
  final DiscordGateway gateway;

  DiscordRest(this.token, this.gateway);

  Map<String, String> get _headers => {
        "Authorization": "Bot $token",
        "Content-Type": "application/json",
      };

  // -*- Message Management Functions -*-

  Future<void> sendMessage(String channelId, String content, {List<Map<String, dynamic>>? embeds}) async {
    final url = Uri.parse("$baseUrl/channels/$channelId/messages");

    final body = <String, dynamic>{
      "content": content,
    };

    if (embeds != null && embeds.isNotEmpty) {
      body["embeds"] = embeds;
    }

    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Failed to send message: ${res.body}");
    }
  }

  Future<List<dynamic>> fetchMessages(String channelId, {int limit = 50}) async {
    final url = Uri.parse("$baseUrl/channels/$channelId/messages?limit=$limit");
    final res = await http.get(url, headers: _headers);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to fetch messages: ${res.body}");
    }
  }

  Future<void> editMessage(String channelId, String messageId, String newContent, {List<Map<String, dynamic>>? embeds}) async {
    final url = Uri.parse("$baseUrl/channels/$channelId/messages/$messageId");

    final body = <String, dynamic>{
      "content": newContent,
    };

    if (embeds != null && embeds.isNotEmpty) {
      body["embeds"] = embeds;
    }

    final res = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to edit message: ${res.body}");
    }
  }

  Future<void> deleteMessage(String channelId, String messageId) async {
    final url = Uri.parse("$baseUrl/channels/$channelId/messages/$messageId");
    final res = await http.delete(url, headers: _headers);

    if (res.statusCode != 204) {
      throw Exception("Failed to delete message: ${res.body}");
    }
  }

  // -*- Reaction Management Functions -*-

  Future<void> addReaction(String channelId, String messageId, String emoji) async {
    final encodedEmoji = Uri.encodeComponent(emoji);
    final url = Uri.parse("$baseUrl/channels/$channelId/messages/$messageId/reactions/$encodedEmoji/@me");

    final res = await http.put(url, headers: _headers);

    if (res.statusCode != 204) {
      throw Exception("Failed to add reaction: ${res.body}");
    }
  }

  Future<void> removeReaction(String channelId, String messageId, String emoji) async {
    final encodedEmoji = Uri.encodeComponent(emoji);
    final url = Uri.parse("$baseUrl/channels/$channelId/messages/$messageId/reactions/$encodedEmoji/@me");

    final res = await http.delete(url, headers: _headers);

    if (res.statusCode != 204) {
      throw Exception("Failed to remove reaction: ${res.body}");
    }
  }

  // -*- Guild Management Functions -*-

  Future<Map<String, dynamic>> getGuild(String guildId) async {
  final url = Uri.parse("$baseUrl/guilds/$guildId");
  final res = await http.get(url, headers: _headers);

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Failed to get guild info: ${res.body}");
  }
}

  Future<List<dynamic>> getGuildMembers(String guildId, {int limit = 1000, String? after}) async {
  final queryParameters = <String, String>{
    'limit': limit.toString(),
    if (after != null) 'after': after,
  };

  final url = Uri.parse("$baseUrl/guilds/$guildId/members").replace(queryParameters: queryParameters);
  final res = await http.get(url, headers: _headers);

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Failed to get guild members: ${res.body}");
  }
}

  Future<List<dynamic>> getGuildChannels(String guildId) async {
  final url = Uri.parse("$baseUrl/guilds/$guildId/channels");
  final res = await http.get(url, headers: _headers);

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Failed to get guild channels: ${res.body}");
  }
}

  Future<List<dynamic>> getGuildRoles(String guildId) async {
  final url = Uri.parse("$baseUrl/guilds/$guildId/roles");
  final res = await http.get(url, headers: _headers);

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Failed to get guild roles: ${res.body}");
  }
}

  Future<Map<String, dynamic>> getGuildMember(String guildId, String userId) async {
  final url = Uri.parse("$baseUrl/guilds/$guildId/members/$userId");
  final res = await http.get(url, headers: _headers);

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Failed to get guild member info: ${res.body}");
  }
}

// -*- Role Management Functions -*-

  Future<Map<String, dynamic>> createRole(String guildId, Map<String, dynamic> roleData) async {
  final url = Uri.parse("$baseUrl/guilds/$guildId/roles");

  final res = await http.post(
    url,
    headers: _headers,
    body: jsonEncode(roleData),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Failed to create role: ${res.body}");
  }
}

  Future<Map<String, dynamic>> modifyRole(String guildId, String roleId, Map<String, dynamic> roleData) async {
  final url = Uri.parse("$baseUrl/guilds/$guildId/roles/$roleId");

  final res = await http.patch(
    url,
    headers: _headers,
    body: jsonEncode(roleData),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Failed to modify role: ${res.body}");
  }
}

  Future<void> deleteRole(String guildId, String roleId) async {
  final url = Uri.parse("$baseUrl/guilds/$guildId/roles/$roleId");

  final res = await http.delete(url, headers: _headers);

  if (res.statusCode != 204) {
    throw Exception("Failed to delete role: ${res.body}");
  }
}

  Future<void> addRoleToMember(String guildId, String userId, String roleId) async {
  final url = Uri.parse("$baseUrl/guilds/$guildId/members/$userId/roles/$roleId");

  final res = await http.put(url, headers: _headers);

  if (res.statusCode != 204) {
    throw Exception("Failed to add role to member: ${res.body}");
  }
}

  Future<void> removeRoleFromMember(String guildId, String userId, String roleId) async {
  final url = Uri.parse("$baseUrl/guilds/$guildId/members/$userId/roles/$roleId");

  final res = await http.delete(url, headers: _headers);

  if (res.statusCode != 204) {
    throw Exception("Failed to remove role from member: ${res.body}");
  }
}

  // -*- Channel Management Functions -*-
  Future<Map<String, dynamic>> createChannel(String guildId, Map<String, dynamic> channelData) async {
    final url = Uri.parse("$baseUrl/guilds/$guildId/channels");

    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode(channelData),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to create channel: ${res.body}");
    }
  }

  Future<Map<String, dynamic>> modifyChannel(String channelId, Map<String, dynamic> channelData) async {
  final url = Uri.parse("$baseUrl/channels/$channelId");

  final res = await http.patch(
    url,
    headers: _headers,
    body: jsonEncode(channelData),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Failed to modify channel: ${res.body}");
  }
}

  Future<void> deleteChannel(String channelId) async {
  final response = await http.delete(
    Uri.parse('https://discord.com/api/channels/$channelId'),
    headers: {
      'Authorization': 'Bot $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode >= 200 && response.statusCode < 300) {
    // Success - remove from cache
    gateway.removeChannel(channelId);
  } else {
    throw Exception('Failed to delete channel: ${response.body}');
    }
  }

  Future<String> createCategory(String guildId, String name, {int? position}) async {
    final body = {
      "name": name,
      "type": 4,
    };
    if (position != null) {
      body["position"] = position;
    }

    final response = await http.post(
      Uri.parse('https://discord.com/api/guilds/$guildId/channels'),
      headers: {
        'Authorization': 'Bot $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else {
      throw Exception('Failed to create category: ${response.body}');
    }
  }

  Future<void> modifyCategory(String categoryId, {String? name, int? position}) async {
  final body = <String, dynamic>{};
  if (name != null) body['name'] = name;
  if (position != null) body['position'] = position;

  final response = await http.patch(
    Uri.parse('https://discord.com/api/channels/$categoryId'),
    headers: {
      'Authorization': 'Bot $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Failed to modify category: ${response.body}');
  }
}

  Future<void> deleteCategory(String categoryId) async {
  final response = await http.delete(
    Uri.parse('https://discord.com/api/channels/$categoryId'),
    headers: {
      'Authorization': 'Bot $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Failed to delete category: ${response.body}');
  }

  gateway.removeChannel(categoryId); // update your cache accordingly
}

// -*- Webhook Management Functions -*-

  Future<Map<String, dynamic>> createWebhook(String channelId, String name, {String? avatar}) async {
  final body = {
    'name': name,
  };
  if (avatar != null) {
    body['avatar'] = avatar; // base64 encoded image string or null
  }

  final response = await http.post(
    Uri.parse('https://discord.com/api/channels/$channelId/webhooks'),
    headers: {
      'Authorization': 'Bot $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Failed to create webhook: ${response.body}');
  }

  return jsonDecode(response.body);
}

  Future<void> modifyWebhook(String webhookId, {String? name, String? avatar}) async {
  final body = <String, dynamic>{};
  if (name != null) body['name'] = name;
  if (avatar != null) body['avatar'] = avatar;

  final response = await http.patch(
    Uri.parse('https://discord.com/api/webhooks/$webhookId'),
    headers: {
      'Authorization': 'Bot $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Failed to modify webhook: ${response.body}');
  }
}

  Future<void> deleteWebhook(String webhookId) async {
  final response = await http.delete(
    Uri.parse('https://discord.com/api/webhooks/$webhookId'),
    headers: {
      'Authorization': 'Bot $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Failed to delete webhook: ${response.body}');
  }
}

  Future<List<dynamic>> getWebhooks(String channelId) async {
  final response = await http.get(
    Uri.parse('https://discord.com/api/channels/$channelId/webhooks'),
    headers: {
      'Authorization': 'Bot $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Failed to fetch webhooks: ${response.body}');
  }

  return jsonDecode(response.body) as List<dynamic>;
  }
}
