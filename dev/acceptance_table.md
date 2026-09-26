---
说明：本表由脚本从源码机械提取（Trigger = 代码里出现的 context.*；状态 = 对象的 extra.* / G.GAME.blh_* 字段；
边界保护 = 代码中的 card_limit / 空手牌 / blueprint / 概率 / nil 判断）。列内 ⚠ 只表示机械提取未命中该模式，
不代表功能缺陷——例如灵视走 add_to_deck、灵嗅直接遍历 G.hand.cards。逐对象人工结论见 AUDIT.md §10。
---

| 对象(key) | 类型 | 成本/稀有度 | Trigger | Condition | 状态 | 边界保护 | 文案 | 兼容守卫 |
|---|---|---|---|---|---|---|---|---|
| ling_shi | Joker | cost 5/rarity 1 | - | ⚠无 | - | ⚠少 | 待核 | （无需） |
| ling_wen | Joker | cost 5/rarity 1 | before,blueprint,poker_hands | 有 | - | blueprint | 待核 | 有 |
| ling_xiu | Joker | cost 5/rarity 1 | joker_main | 有 | - | ⚠少 | 待核 | （无需） |
| hun_qian | Joker | cost 6/rarity 1 | blueprint,discard,other_card | 有 | - | blueprint | 待核 | 有 |
| li_xi | Joker | cost 6/rarity 1 | before,blueprint | 有 | - | blueprint,概率 | 待核 | 有 |
| zhao_zai | Joker | cost 6/rarity 1 | blueprint,end_of_round,game_over,individual,joker_main,repetition | 有 | mult | blueprint,概率 | 待核 | 有 |
| bao_ran | Joker | cost 5/rarity 1 | blueprint,discard,other_card | 有 | - | blueprint,概率 | 待核 | 有 |
| po_wan_fa | Joker | cost 7/rarity 2 | before,blueprint | 有 | - | blueprint | 待核 | 有 |
| qiao_wu | Joker | cost 6/rarity 1 | blueprint,end_of_round,game_over,individual,repetition | 有 | - | 容量,blueprint | 待核 | 有 |
| xian_ling | Joker | cost 6/rarity 1 | blueprint,end_of_round,game_over,individual,repetition | 有 | - | 容量,blueprint | 待核 | 有 |
| yuan_wu | Joker | cost 5/rarity 1 | blueprint,setting_blind | 有 | - | blueprint | 待核 | 有 |
| yan_pin | Joker | cost 6/rarity 1 | blueprint,end_of_round,first_hand_drawn,game_over,individual,joker_main,repetition | 有 | mult,pending | 容量,blueprint,概率 | 待核 | 有 |
| tan_nang | Joker | cost 6/rarity 1 | blueprint,end_of_round,first_hand_drawn,game_over,individual,repetition | 有 | pending | 容量,blueprint,概率 | 待核 | 有 |
| dian_ren | Joker | cost 6/rarity 1 | blueprint,end_of_round,game_over,individual,joker_main,repetition | 有 | mult | blueprint | 待核 | 有 |
| shuang_sheng_hua | Joker | cost 7/rarity 2 | before,blueprint | 有 | - | blueprint,概率,nil | 待核 | 有 |
| sheng_sheng_bu_xi | Joker | cost 8/rarity 3 | blueprint,end_of_round,game_over,individual,repetition | 有 | count,made | 容量,blueprint,nil | 待核 | 有 |
| qiang_yun | Joker | cost 5/rarity 1 | blueprint,fix_probability,numerator | 有 | - | blueprint | 待核 | 有 |
| ji_fa | Joker | cost 5/rarity 1 | blueprint,denominator,fix_probability | 有 | - | blueprint | 待核 | 有 |
| huo_shui | Joker | cost 5/rarity 1 | joker_main | 有 | - | 概率 | 待核 | （无需） |
| ru_meng | Joker | cost 6/rarity 1 | blueprint,end_of_round,game_over,individual,repetition | 有 | count | blueprint,概率 | 待核 | 有 |
| yin_guo | Joker | cost 6/rarity 1 | before,blueprint,discard,joker_main | 有 | discarded | blueprint | 待核 | 有 |
| ti_zui | Joker | cost 5/rarity 1 | blueprint,discard,other_card | 有 | - | blueprint | 待核 | 有 |
| jia_huo | Joker | cost 5/rarity 1 | before,blueprint | 有 | - | blueprint,概率 | 待核 | 有 |
| wang_you | Joker | cost 5/rarity 1 | joker_main | 有 | - | ⚠少 | 待核 | （无需） |
| bu_mie | Joker | cost 6/rarity 1 | blueprint,end_of_round,game_over | 有 | used | blueprint | 待核 | 有 |
| tian_xing_jian | Joker | cost 7/rarity 2 | before,blueprint,discard,joker_main | 有 | discarded | blueprint | 待核 | 有 |
| yue_qian | Joker | cost 6/rarity 1 | before,blueprint,using_consumeable | 有 | count,rnd | blueprint | 待核 | 有 |
| duo_xin_po | Joker | cost 7/rarity 2 | before,blueprint | 有 | - | blueprint,nil | 待核 | 有 |
| chuan_yin | Joker | cost 6/rarity 1 | joker_main | 有 | - | ⚠少 | 待核 | （无需） |
| nuo_yi | Joker | cost 6/rarity 1 | blueprint,discard,other_card | 有 | - | 容量,空手牌,blueprint,概率 | 待核 | 有 |
| dominion | Consumable | cost 4 | - | 有 | - | 空手牌 | 待核 | （无需） |
| mirror | Consumable | cost 4 | - | 有 | - | 容量,空手牌 | 待核 | （无需） |
| ascension | Consumable | cost 4 | - | 有 | - | ⚠少 | 待核 | （无需） |
| pact | Consumable | cost 4 | - | 有 | - | 空手牌 | 待核 | （无需） |
| cornucopia | Consumable | cost 4 | - | 有 | - | ⚠少 | 待核 | （无需） |
| rat_search | Consumable | cost 3 | - | 有 | - | 容量,空手牌,nil | 待核 | （无需） |
| ox_run | Consumable | cost 4 | - | 有 | - | 空手牌 | 待核 | （无需） |
| tiger_duel | Consumable | cost 4 | - | 有 | - | 空手牌 | 待核 | （无需） |
| rabbit_escape | Consumable | cost 4 | - | 有 | - | 空手牌 | 待核 | （无需） |
| dragon_balance | Consumable | cost 4 | - | 有 | - | ⚠少 | 待核 | （无需） |
| snake_vote | Consumable | cost 4 | - | 有 | - | ⚠少 | 待核 | （无需） |
| horse_race | Consumable | cost 4 | - | 有 | - | ⚠少 | 待核 | （无需） |
| goat_fan | Consumable | cost 4 | - | 有 | - | 概率 | 待核 | （无需） |
| monkey_box | Consumable | cost 4 | - | 有 | - | 空手牌,概率 | 待核 | （无需） |
| rooster_arms | Consumable | cost 4 | - | 有 | - | 空手牌,概率 | 待核 | （无需） |
| dog_letter | Consumable | cost 4 | - | 有 | - | 空手牌 | 待核 | （无需） |
| pig_gamble | Consumable | cost 4 | - | 有 | - | 空手牌,概率 | 待核 | （无需） |
| doppelganger | Consumable | cost 4 | - | 有 | - | nil | 待核 | （无需） |
| antimatter | Consumable | cost 4 | - | 有 | - | ⚠少 | 待核 | （无需） |
| offering | Consumable | cost 4 | - | 有 | - | ⚠少 | 待核 | （无需） |
| entropy | Consumable | cost 4 | - | 有 | - | 概率 | 待核 | （无需） |
| echo | Consumable | cost 4 | - | 有 | - | ⚠少 | 待核 | （无需） |
| daocheng_cycle | Consumable | cost 4 | - | 有 | - | ⚠少 | 待核 | （无需） |
| yucheng_memory | Consumable | cost 4 | - | 有 | - | 容量,概率 | 待核 | （无需） |
| wocheng_vortex | Consumable | cost 4 | - | 有 | - | ⚠少 | 待核 | （无需） |
| goucheng_pact | Consumable | cost 4 | - | 有 | - | ⚠少 | 待核 | （无需） |
| suocheng_index | Consumable | cost 4 | - | 有 | - | 容量 | 待核 | （无需） |
| rat_dao | Tag | cost - | type | 有 | - | ⚠少 | 待核 | （无需） |
| ox_power | Tag | cost - | type | 有 | - | ⚠少 | 待核 | （无需） |
| tiger_strong | Tag | cost - | type | 有 | - | ⚠少 | 待核 | （无需） |
| rabbit_escape | Tag | cost - | type | 有 | - | ⚠少 | 待核 | （无需） |
| dragon_scale | Tag | cost - | type | 有 | - | ⚠少 | 待核 | （无需） |
| snake_riddle | Tag | cost 0 | type | 有 | - | ⚠少 | 待核 | （无需） |
| horse_speed | Tag | cost - | type | 有 | - | ⚠少 | 待核 | （无需） |
| goat_disguise | Tag | cost - | card,type | 有 | - | ⚠少 | 待核 | （无需） |
| monkey_take | Tag | cost - | type | 有 | - | 概率 | 待核 | （无需） |
| rooster_weapon | Tag | cost - | type | 有 | - | 概率 | 待核 | （无需） |
| dog_letter | Tag | cost - | type | 有 | - | ⚠少 | 待核 | （无需） |
| pig_gamble | Tag | cost - | type | 有 | - | 概率 | 待核 | （无需） |
| xuanwu_fair | Tag | cost - | type | 有 | - | ⚠少 | 待核 | （无需） |
| baihu_mediate | Tag | cost - | setting_blind,type | 有 | - | ⚠少 | 待核 | （无需） |
| zhuque_judge | Tag | cost - | type | 有 | - | 概率 | 待核 | （无需） |
| qinglong_head | Tag | cost - | type | 有 | - | 容量,概率 | 待核 | （无需） |
| rat | Blind | cost - | - | ⚠无 | - | ⚠少 | 待核 | （无需） |
| ox | Blind | cost - | - | ⚠无 | - | ⚠少 | 待核 | （无需） |
| tiger | Blind | cost - | - | ⚠无 | - | ⚠少 | 待核 | （无需） |
| rabbit | Blind | cost - | - | ⚠无 | - | ⚠少 | 待核 | （无需） |
| snake | Blind | cost - | - | ⚠无 | - | ⚠少 | 待核 | （无需） |
| horse | Blind | cost - | - | ⚠无 | - | ⚠少 | 待核 | （无需） |
| goat | Blind | cost - | - | ⚠无 | - | ⚠少 | 待核 | （无需） |
| monkey | Blind | cost - | - | ⚠无 | - | 空手牌,概率,nil | 待核 | （无需） |
| rooster | Blind | cost - | - | ⚠无 | - | ⚠少 | 待核 | （无需） |
| dog | Blind | cost - | - | ⚠无 | - | ⚠少 | 待核 | （无需） |
| pig | Blind | cost - | - | ⚠无 | - | ⚠少 | 待核 | （无需） |
| dragon | Blind | cost - | - | ⚠无 | - | ⚠少 | 待核 | （无需） |
| echo | Edition | cost 4 | cardarea,individual,joker_main | 有 | - | ⚠少 | 待核 | （无需） |
| fragrance | Edition | cost 3 | cardarea,individual | 有 | - | ⚠少 | 待核 | （无需） |
| ripple | Edition | cost 5 | joker_main | 有 | - | ⚠少 | 待核 | （无需） |
| zodiac | Edition | cost 3 | joker_main | 有 | - | ⚠少 | 待核 | （无需） |
| beast | Edition | cost 6 | cardarea,individual,joker_main | 有 | - | ⚠少 | 待核 | （无需） |
| dao | Seal | cost - | cardarea,main_scoring | 有 | - | ⚠少 | 待核 | （无需） |
| yu | Seal | cost - | cardarea,main_scoring | 有 | - | ⚠少 | 待核 | （无需） |
| wo | Seal | cost - | discard | 有 | - | 容量 | 待核 | （无需） |
| zodiac | Seal | cost - | cardarea,repetition | 有 | - | ⚠少 | 待核 | （无需） |
| beast | Seal | cost - | cardarea,main_scoring | 有 | - | ⚠少 | 待核 | （无需） |
| memory | Sticker | cost - | joker_main | 有 | - | ⚠少 | 待核 | （无需） |
| deep_echo | Sticker | cost - | joker_main | 有 | - | ⚠少 | 待核 | （无需） |
| native | Sticker | cost - | joker_main | 有 | - | ⚠少 | 待核 | （无需） |
| ant | Sticker | cost - | cardarea,individual | 有 | - | ⚠少 | 待核 | （无需） |
| mask | Sticker | cost - | joker_main | 有 | - | ⚠少 | 待核 | （无需） |
