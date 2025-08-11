# DartCord Dart Library

`DartCord` is a Dart package for interacting with the Discord API, combining REST methods with gateway events for real-time Discord bot development.

## Features

* Send, fetch, edit, and delete messages. Embed support included.
* Add and remove reactions
* Manage guilds, members, channels, and roles
* Create, modify, and delete roles and channels
* Create, modify, and delete categories
* Create, modify, and delete webhooks
* Listen to Discord gateway events like messages and bot readiness

## Requirements

* Dart SDK
* `http` package (handled internally)
* A `DiscordBot` instance to handle gateway connection and caching

## Usage

### Initialization

```dart
import 'package:dartcord/dartcord.dart';

void main() async {
  final bot = DiscordBot(
    "YOUR_BOT_TOKEN_HERE",
  );

  // Event: When bot is ready
  bot.onReady(([_]) {
    print("✅ Logged in!");
  });

  // Event: On message received
  bot.onMessage(([msg]) async {
    final content = msg['content'] ?? '';
    final author = msg['author']['username'];
    final channelId = msg['channel_id'];

    print("$author: $content");

    if (content == "!ping") {
      await bot.rest.sendMessage(channelId, "🏓 Pong!");
    }

    // ... additional commands and examples here ...
  });

  // Connect the bot (usually needed, depending on your lib design)
  await bot.connect();
}
```

### Example Commands

```dart
bot.onMessage(([msg]) async {
  final content = msg['content'] ?? '';
  final channelId = msg['channel_id'];

  if (content.startsWith("!say ")) {
    final message = content.substring(5);
    await bot.rest.sendMessage(channelId, message);
  } else if (content.startsWith("!edit ")) {
    final parts = content.split(" ");
    if (parts.length >= 3) {
      final messageId = parts[1];
      final newContent = parts.sublist(2).join(" ");
      await bot.rest.editMessage(channelId, messageId, newContent);
    }
  } else if (content.startsWith("!delete ")) {
    final parts = content.split(" ");
    if (parts.length == 2) {
      final messageId = parts[1];
      await bot.rest.deleteMessage(channelId, messageId);
    }
  } else if (content == "!embed") {
    await bot.rest.sendMessage(
      channelId,
      "",
      embeds: [
        {
          "title": "Test Embed",
          "description": "This is a test embed message from DartCord.",
          "color": 0x00FF00,
          "fields": [
            {"name": "Field 1", "value": "Value 1", "inline": true},
            {"name": "Field 2", "value": "Value 2", "inline": true},
          ],
          "footer": {"text": "Footer text"},
        }
      ],
    );
  }
});
```

## API Highlights

The REST API methods are accessed through the `rest` property on the `DiscordBot` instance:

```dart
await bot.rest.sendMessage(channelId, "Hello!");
final messages = await bot.rest.fetchMessages(channelId, limit: 100);
await bot.rest.editMessage(channelId, messageId, "Updated!");
await bot.rest.deleteMessage(channelId, messageId);
await bot.rest.addReaction(channelId, messageId, "👍");
await bot.rest.removeReaction(channelId, messageId, "👍");

// Guild management
final guild = await bot.rest.getGuild(guildId);
final members = await bot.rest.getGuildMembers(guildId);
final channels = await bot.rest.getGuildChannels(guildId);
final roles = await bot.rest.getGuildRoles(guildId);

// Role management
final newRole = await bot.rest.createRole(guildId, {"name": "New Role"});
await bot.rest.modifyRole(guildId, newRole['id'], {"name": "Renamed Role"});
await bot.rest.deleteRole(guildId, newRole['id']);
await bot.rest.addRoleToMember(guildId, userId, newRole['id']);
await bot.rest.removeRoleFromMember(guildId, userId, newRole['id']);

// Channel management
final newChannel = await bot.rest.createChannel(guildId, {"name": "new-channel"});
await bot.rest.modifyChannel(newChannel['id'], {"name": "renamed-channel"});
await bot.rest.deleteChannel(newChannel['id']);

// Category management
final guildId = "123456789012345678"; // Example guild ID
final categoryId = "123456789012345678"; // Example category ID
await bot.rest.createCategory(guildId, {"name": "New Category"});
await bot.rest.modifyCategory(categoryId, {"name": "Renamed Category"});
await bot.rest.deleteCategory(categoryId);

// Webhook management
final webhook = await bot.rest.createWebhook(channelId, {"name": "My Webhook"});
await bot.rest.modifyWebhook(webhook['id'], {"name": "Updated Webhook"});
await bot.rest.deleteWebhook(webhook['id']);
```
