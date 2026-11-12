# kora_mining agent guide

`kora_mining` is a Kora mining and smelting job: players buy pickaxes, mine rock props for items and Mining XP, and smelt ore at stations for Smelting XP. All content (rocks, vendor, blips, recipes, stations) is database-driven and edited in game through the admin Mining Creator (`/miningCreator`). Layout: `fxmanifest.lua`, `shared/config.lua` (`MiningConfig`), `server/` (`schema.lua` tables and seeds, `util.lua`, `main.lua` rocks and mining, `pickaxe_shop.lua`, `blips.lua`, `smelting.lua`), `client/` (`rockspawns.lua`, `pickaxe_shop.lua`, `smelting.lua`, `blip.lua`, `creator.lua`), `images/` (item icons), `test/schema.lua` (offline schema test) and `tests/` (kora_qa feature files).

## Documentation

User-facing documentation lives in `docs/` (Markdown, published via the Kora Docusaurus site, kora_docs_next). Read `docs/index.md` first (it links every page). Layout: `index.md` (hub and documentation map), `installation.md`, `how-to-use.md` (step-by-step flows), `commands.md`, `api/` (`index.md` and `configuration.md` for `MiningConfig`), and topic pages (`mining.md`, `pickaxe-shop.md`, `smelting.md`, `blips.md`, `creator.md`, `events.md`, `items.md`, `database.md`, `troubleshooting.md`). Update the page that matches the topic you change.

When you add, change, or remove a feature, config option, command, export, event, item, permission, or database table/column, update the matching page in `docs/` in the same change. Keep docs accurate to the code; do not document behaviour that does not exist.

Docs rules: plain Markdown with `title`/`sidebar_position` front matter (no `id`/`slug`), relative links only between docs pages, assets inside `docs/`, fenced code blocks with a language, and no raw `<`, `>`, `{`, `}` outside code (pages are parsed as MDX). The release version comes from `fxmanifest.lua`'s `version` field.
