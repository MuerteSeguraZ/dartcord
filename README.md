# DiscordRest Dart Library

`DiscordRest` is a Dart class that provides convenient methods to interact with the Discord REST API for managing messages, reactions, guilds, roles, and channels. It is designed to be used alongside a `DiscordGateway` class to handle caching and real-time events.

## Features

- Send, fetch, edit, and delete messages in channels
- Add and remove reactions on messages
- Retrieve guild information, members, channels, and roles
- Create, modify, and delete roles
- Assign and remove roles for guild members
- Create, modify, and delete channels

## Requirements

- Dart SDK
- `http` package for making HTTP requests

## Usage

### Initialization

```dart
final discordRest = DiscordRest(botToken, discordGatewayInstance);
````

* `botToken`: Your Discord bot token as a string.
* `discordGatewayInstance`: An instance of your `DiscordGateway` class, used for caching and gateway communication.

### Examples

#### Sending a Message

```dart
await discordRest.sendMessage('channelId', 'Hello, world!');
```

#### Fetching Messages

```dart
List<dynamic> messages = await discordRest.fetchMessages('channelId', limit: 100);
```

#### Deleting a Channel

```dart
await discordRest.deleteChannel('channelId');
```

### Error Handling

All methods throw exceptions with descriptive messages when the Discord API responds with an error or unexpected status code.

## Method Overview

### Message Management

* `sendMessage(String channelId, String content, {List<Map<String, dynamic>>? embeds})`
* `fetchMessages(String channelId, {int limit = 50})`
* `editMessage(String channelId, String messageId, String newContent, {List<Map<String, dynamic>>? embeds})`
* `deleteMessage(String channelId, String messageId)`

### Reaction Management

* `addReaction(String channelId, String messageId, String emoji)`
* `removeReaction(String channelId, String messageId, String emoji)`

### Guild Management

* `getGuild(String guildId)`
* `getGuildMembers(String guildId, {int limit = 1000, String? after})`
* `getGuildChannels(String guildId)`
* `getGuildRoles(String guildId)`
* `getGuildMember(String guildId, String userId)`

### Role Management

* `createRole(String guildId, Map<String, dynamic> roleData)`
* `modifyRole(String guildId, String roleId, Map<String, dynamic> roleData)`
* `deleteRole(String guildId, String roleId)`
* `addRoleToMember(String guildId, String userId, String roleId)`
* `removeRoleFromMember(String guildId, String userId, String roleId)`

### Channel Management

* `createChannel(String guildId, Map<String, dynamic> channelData)`
* `modifyChannel(String channelId, Map<String, dynamic> channelData)`
* `deleteChannel(String channelId)`

## Notes

* Make sure your bot has the appropriate permissions for the actions you want to perform.
* This class expects your `DiscordGateway` instance to implement a `removeChannel(String id)` method to handle cache cleanup on channel deletion.

## License

MIT License

---

Feel free to contribute or open issues for bugs or feature requests!

```
