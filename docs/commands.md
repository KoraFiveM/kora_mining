---
title: Commands and permissions
sidebar_position: 9
---

# Commands and permissions

## Commands

| Command | Who | Description |
| --- | --- | --- |
| `/miningCreator` | Admins | Opens the [Mining Creator](./creator.md). Registered server side with `restricted = false`; the handler itself checks the permission and sends an error notification to non-admins. |

## Permissions

The admin check (`MiningUtil.isAdmin`) is `IsPlayerAceAllowed(source, 'command')` for a real player source. Grant it in `server.cfg`, for example:

```cfg
add_ace group.admin command allow
```

This is the broad `command` ACE, so any player allowed to run all commands is also a mining admin. Every creator callback (rocks, vendor, blips, recipes, stations) repeats this check on the server.

There are no other commands, key mappings or exports.
