---
title: "Commands"
sidebar_position: 4
---


# Commands

One server command, admin-gated.

## Built-in commands

### `/miningCreator`

Opens the mining rockspawn creator NUI for the calling player.

| Field | Details |
| --- | --- |
| Context | In-game · server command |
| Arguments | No arguments. |
| Access | Requires the `command` ACE (checked via `MiningUtil.isAdmin`, i.e. `IsPlayerAceAllowed(source, 'command')`). Non-admins get an error notification and nothing opens. |

**Example**

```text
/miningCreator
```

**Result**

Triggers `kora_mining:creator:open` on the caller's client, opening the rock-type editor.

## Registration and permissions

The command is registered server side with `restricted = false`; the handler itself checks the permission and sends an error notification to non-admins (`server/main.lua:351`). See [Mining Creator](./creator.md) for what it opens.

The admin check (`MiningUtil.isAdmin`) is `IsPlayerAceAllowed(source, 'command')` for a real player source (`server/util.lua:7`). Grant it in `server.cfg`, for example:

```cfg
add_ace group.admin command allow
```

This is the broad `command` ACE, so any player allowed to run all commands is also a mining admin. Every creator callback (rocks, vendor, blips, recipes, stations) repeats this check on the server.

There are no other commands, key mappings or exports.
