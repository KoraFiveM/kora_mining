# Mining progression guide

This is a faster-paced recommendation for the 20 rock models listed in `client/creator.lua`. It keeps recognizable OSRS unlock points for the low and mid tiers, but moves advanced resources to level 50 or above and raises early XP. OSRS reference rewards include copper/tin at level 1 for 17.5 XP, iron at 15 for 35 XP, silver at 20 for 40 XP, coal at 30 for 50 XP, gold at 40 for 65 XP, mithril at 55 for 80 XP, adamantite at 70 for 95 XP, runite at 85 for 125 XP, and amethyst at 92 for 240 XP. ([OSRS Mining experience table](https://oldschool.runescape.wiki/w/Mining/Experience_table), [OSRS Mining training](https://oldschool.runescape.wiki/w/Pay-to-play_Mining_training))

## Recommended rock settings

| Category | Rock model | Suggested reward item | Required level | XP per mine | Progression role |
| --- | --- | --- | ---: | ---: | --- |
| Resources | `copper_rock` | `copper_ore` | 1 | 30 | Starter ore; raised above OSRS's 17.5 XP to speed up early levels. |
| Resources | `tin_rock` | `tin_ore` | 1 | 30 | Starter ore paired with copper for the bronze tier. The SQL row is present with no locations yet. |
| Resources | `basalt_rock` | `basalt` | 5 | 30 | Common starter stone. |
| Resources | `bauxite_rock` | `bauxite` | 10 | 40 | Early step between starter stone and iron. |
| Resources | `iron_rock` | `iron_ore` | 15 | 60 | First meaningful level gate; OSRS iron unlock is level 15. |
| Resources | `silver_rock` | `silver_ore` | 20 | 70 | Early valuable metal; OSRS silver unlock is level 20. |
| Resources | `carbon_rock` | `carbon` | 30 | 85 | Midgame bulk material; OSRS coal unlock is level 30. |
| Resources | `sandstone_rock` | `sandstone` | 35 | 95 | Midgame stone. |
| Resources | `gold_rock` | `gold_ore` | 40 | 120 | Valuable midgame metal; OSRS gold unlock is level 40. |
| Resources | `zinc_rock` | `zinc_ore` | 50 | 180 | First advanced metal tier. |
| Crystals | `quartz_rock` | `quartz_shard` | 55 | 210 | First advanced crystal tier. |
| Resources | `carbonatite_rock` | `carbonatite` | 70 | 275 | High-tier mineral, filling the OSRS adamantite tier. |
| Resources | `obsidian_rock` | `obsidian` | 85 | 315 | Endgame resource, filling the OSRS runite tier. |
| Crystals | `opal_rock` | `opal_shard` | 40 | 120 | First crystal tier. |
| Crystals | `topaz_rock` | `topaz_shard` | 50 | 180 | Advanced crystal tier. |
| Gemstones | `sapphire_rock` | `uncut_sapphire` | 60 | 230 | Advanced gemstone. |
| Gemstones | `emerald_rock` | `uncut_emerald` | 65 | 250 | Advanced gemstone. |
| Gemstones | `ruby_rock` | `uncut_ruby` | 70 | 275 | High-value gemstone. |
| Gemstones | `diamond_rock` | `uncut_diamond` | 75 | 300 | Highest standard gemstone tier. |
| Crystals | `amethyst_rock` | `amethyst_shard` | 92 | 350 | Endgame crystal; OSRS unlock point is level 92, with increased XP for the shorter Kora pace. |

## Pickaxe unlock suggestions

Use the per-rock pickaxe speed settings to unlock better tools over time. Keep the rock's Mining level as the main gate and avoid making every pick mandatory for a material.

| Pickaxe item | Suggested Mining level |
| --- | ---: |
| `bronze_pickaxe` | 1 |
| `iron_pickaxe` | 20 |
| `steel_pickaxe` | 40 |
| `titanium_pickaxe` | 60 |
| `obsidian_pickaxe` | 80 |

These levels define when each pickaxe can be used. Per-rock enable flags and speed bonuses are assigned by the rock's required Mining level bracket: up to 30, 31–50, 51–70, and above 70.

## XP pacing notes

- On the `kora_skills` XP curve, this schedule takes about **115 hours** of continuous mining at 10 seconds per mine, or about **41,337 successful mines**. That is approximately half the previous 230-hour estimate.
- The estimate assumes the player always mines the available rock with the highest XP, moves to the next rock as soon as its level requirement is met, and receives XP once for each completed mine. It excludes travel and respawn downtime, and assumes no pickaxe or maximum-level speed bonuses.
- `kora_skills` reaches level 99 at 13,034,431 XP. The curve is RuneScape-shaped; this schedule increases the RS-like XP rewards to reach the requested faster pace.
- The current mining setting accepts whole-number XP only; all values in the recommended table are integers.
- SQL mining times are set by category: 12 seconds for Resources, 17 seconds for Crystals, and 20 seconds for Gemstones. Mining level contributes up to 20% additional speed at level 99.
- Award XP once per completed mine action, regardless of whether the player receives one or several items. This keeps XP tied to mining actions, like OSRS XP-per-ore rewards.
- Keep rare materials meaningfully slower and more valuable. Level gates and pickaxe speed bonuses should carry that progression; avoid inflating XP rewards on every resource just to speed up leveling.
- `tin_rock` has no matching `tin_ore` item in `kora_core/shared/items.lua`; add it before configuring the Tin rockspawn. `carbonatite` and `obsidian` have matching items, although the related ingot item is spelled `*_ignot` in the current items file.

## RuneScape reference points

| Level | Total XP in this skill curve |
| ---: | ---: |
| 15 | 2,411 |
| 30 | 13,363 |
| 40 | 37,224 |
| 50 | 101,333 |
| 55 | 166,636 |
| 70 | 737,627 |
| 85 | 3,258,594 |
| 92 | 6,517,253 |
| 99 | 13,034,431 |
