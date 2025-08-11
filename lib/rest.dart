import 'dart:convert';
import 'package:http/http.dart' as http;

class DiscordRest {
  final String token;
  final String baseUrl = "https://discord.com/api/v10";

  DiscordRest(this.token);

  Map<String, String> get _headers => {
        "Authorization": "Bot $token",
        "Content-Type": "application/json",
      };

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

  /// Adds a reaction to a message.
  /// 
  /// [emoji] must be URL encoded if it's a unicode emoji.
  /// For custom emojis use the format: `name:id`
  Future<void> addReaction(String channelId, String messageId, String emoji) async {
    final encodedEmoji = Uri.encodeComponent(emoji);
    final url = Uri.parse("$baseUrl/channels/$channelId/messages/$messageId/reactions/$encodedEmoji/@me");

    final res = await http.put(url, headers: _headers);

    if (res.statusCode != 204) {
      throw Exception("Failed to add reaction: ${res.body}");
    }
  }

  /// Removes a reaction added by the bot user.
  Future<void> removeReaction(String channelId, String messageId, String emoji) async {
    final encodedEmoji = Uri.encodeComponent(emoji);
    final url = Uri.parse("$baseUrl/channels/$channelId/messages/$messageId/reactions/$encodedEmoji/@me");

    final res = await http.delete(url, headers: _headers);

    if (res.statusCode != 204) {
      throw Exception("Failed to remove reaction: ${res.body}");
    }
  }

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

  // Placeholder for handling rate limits, retries, etc.
  // Can add exponential backoff or queueing here later
