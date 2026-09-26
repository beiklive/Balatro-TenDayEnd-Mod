---
说明：对「模组实际使用的每个 API」逐个 grep 设备源码 dump（26.829.0）与 SMODS 参考源码（1.0.0-beta-1814a）生成。
`✘` 只在两处出现，且都是**本模组自己定义的全局**（`G.FUNCS.blh_config_changed` / `G.FUNCS.blh_unlock_all`），不是外部 API。
---

| API（模组中实际使用） | 设备 dump 命中 | SMODS 参考源码命中 | 判定 |
|---|---:|---:|---|
| `Blind:defeat` | 48 | 16 | ✔ 设备源码确认 |
| `Card:set_debuff` | 23 | 18 | ✔ 设备源码确认 |
| `Card:use_consumeable` | 23 | 6 | ✔ 设备源码确认 |
| `G.FUNCS.blh_config_changed` | 0 | 0 | ✘ [API-UNVERIFIED]（本模组自建全局） |
| `G.FUNCS.blh_unlock_all` | 0 | 0 | ✘ [API-UNVERIFIED]（本模组自建全局） |
| `G.FUNCS.discard_cards_from_highlighted` | 5 | 0 | ✔ 设备源码确认 |
| `G.FUNCS.use_card` | 40 | 22 | ✔ 设备源码确认 |
| `Game:init_game_object` | 19 | 18 | ✔ 设备源码确认 |
| `Game:start_run` | 15 | 10 | ✔ 设备源码确认 |
| `SMODS.Atlas` | 12 | 44 | ✔ 设备源码确认 |
| `SMODS.Blind` | 100 | 178 | ✔ 设备源码确认 |
| `SMODS.Blinds` | 0 | 6 | △ 仅 SMODS 参考源码确认 [REF-ONLY] |
| `SMODS.Challenge` | 12 | 43 | ✔ 设备源码确认 |
| `SMODS.Consumable` | 33 | 113 | ✔ 设备源码确认 |
| `SMODS.Consumables` | 0 | 6 | △ 仅 SMODS 参考源码确认 [REF-ONLY] |
| `SMODS.Edition` | 62 | 110 | ✔ 设备源码确认 |
| `SMODS.Editions` | 1 | 11 | ✔ 设备源码确认 |
| `SMODS.Joker` | 379 | 137 | ✔ 设备源码确认 |
| `SMODS.Jokers` | 5 | 9 | ✔ 设备源码确认 |
| `SMODS.Keybind` | 13 | 33 | ✔ 设备源码确认 |
| `SMODS.ObjectType` | 20 | 57 | ✔ 设备源码确认 |
| `SMODS.ObjectTypes` | 10 | 18 | ✔ 设备源码确认 |
| `SMODS.ObjectTypes.Joker` | 379 | 137 | ✔ 设备源码确认 |
| `SMODS.Seal` | 28 | 64 | ✔ 设备源码确认 |
| `SMODS.Seals` | 3 | 14 | ✔ 设备源码确认 |
| `SMODS.Sticker` | 29 | 80 | ✔ 设备源码确认 |
| `SMODS.Stickers` | 12 | 38 | ✔ 设备源码确认 |
| `SMODS.Tag` | 122 | 72 | ✔ 设备源码确认 |
| `SMODS.Tags` | 5 | 7 | ✔ 设备源码确认 |
| `SMODS.Voucher` | 115 | 59 | ✔ 设备源码确认 |
| `SMODS.Vouchers` | 3 | 2 | ✔ 设备源码确认 |
| `SMODS.calculate_context` | 56 | 80 | ✔ 设备源码确认 |
| `SMODS.calculate_effect` | 1 | 25 | ✔ 设备源码确认 |
| `SMODS.change_base` | 2 | 7 | ✔ 设备源码确认 |
| `SMODS.current_mod` | 7 | 13 | ✔ 设备源码确认 |
| `SMODS.current_mod.blh` | 5 | 0 | ✔ 设备源码确认 |
| `SMODS.current_mod.calculate` | 242 | 328 | ✔ 设备源码确认 |
| `SMODS.destroy_cards` | 7 | 4 | ✔ 设备源码确认 |
| `SMODS.get_probability_vars` | 12 | 16 | ✔ 设备源码确认 |
| `SMODS.load_file` | 0 | 2 | △ 仅 SMODS 参考源码确认 [REF-ONLY] |
| `SMODS.pseudorandom_probability` | 12 | 9 | ✔ 设备源码确认 |
| `SMODS.save_mod_config` | 0 | 6 | △ 仅 SMODS 参考源码确认 [REF-ONLY] |
| `SMODS.saved` | 27 | 45 | ✔ 设备源码确认 |

| 汇总 | 值 |
|---|---|
| 设备源码确认 | 37 |
| 仅参考源码确认 [REF-ONLY] | 4 |
| 自建全局（非外部 API） | 2 |

自建全局清单：`G.FUNCS.blh_config_changed`, `G.FUNCS.blh_unlock_all`
