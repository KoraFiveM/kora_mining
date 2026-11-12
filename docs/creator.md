---
title: Mining Creator
sidebar_position: 10
---

# Mining Creator

The Mining Creator is an admin-only `kora_lib` NUI app opened with `/miningCreator` (see [Commands and permissions](./commands.md)). All changes are written to the database immediately and pushed to connected clients without a restart.

## Sections

- **Rockspawns** - grouped by category. Create a rock type (id: starts with a letter, letters, digits and underscores, up to 32 chars), edit its settings, enable and tune each pickaxe (speed bonus and enabled), place or remove spots, delete it. Spots are placed by aiming at the ground with the in-game raycast. A model must be chosen and saved before spots can be placed. See [Mining](./mining.md).
- **Pickaxe vendor** - ped model, vendor locations and the price of each pickaxe. See [Pickaxes and shop](./pickaxe-shop.md).
- **Blips** - create, edit, re-aim and delete map blips. See [Map blips](./blips.md).
- **Smelting** - create, edit and delete recipes (details, result item, required items with an item search) and stations (details, categories, recipes, locations, optional prop model). See [Smelting](./smelting.md).

## Notes

- The server callbacks behind the creator all require the admin check and return `Admin permission required.` otherwise.
- Opening the creator loads all data first; if rocks, items, vendor, blips or smelting data fail to load, an error notification is shown.
- The client-side open event only accepts a trigger coming from the server.
