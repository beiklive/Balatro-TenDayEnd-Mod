# 终焉之地 · 设计清单（beiklive助手 v2）

> 十日终焉主题大型模组设计文档。每完成一项就把 `[ ]` 改成 `[x]`。
> 设定来源：360 百科、夸克百科、简书设定整理（粉丝资料，非官方设定集）；标注「设计」的部分是模组原创映射。

## 0. 决策记录

| 项 | 决定 |
|---|---|
| 形态 | 挑战模式「终焉之地」（SMODS.Challenge） |
| 池隔离 | 完全硬核：原版小丑 / 塔罗 / 幻灵 / 优惠券 / 标签全部不出现在该模式 |
| 临时例外 | 卡组(Back)、补充包(Booster)、强化(Enhancement)、牌型(PokerHand) 保留原版 |
| 货币 | 道 = 独立货币 + 独立 HUD；金钱仍用于商店 |
| 道产出 | 仅由击败盲注产出（不与金钱、分数绝对值挂钩） |
| 通关 | 第 10 天击败天龙（真结局）；道 ≥ 3600 → 天龙提前降临（提前结局） |
| 反刷 | 天龙需求分数 ×(1 + ⌊道/500⌋ × 0.1)，进入天龙战时结算一次 |
| 牌型 | 原版 12 种，不做增补 |

## 1. 道 · 经济系统

### 1.1 基础产出（击败盲注立即结算）
- [x] 小盲注道 = `10 + 5 × 天`
- [x] 大盲注道 = `20 + 8 × 天`
- [x] Boss 道 = 人级 80 / 地级 130 / 天级 200 / 天龙 400
- [x] 十天全程基础总量 = **2575 道**

### 1.2 性能奖励（封顶）
- [x] 剩余出牌次数 × 4 道
- [x] 剩余弃牌次数 × 3 道
- [x] 超额分数：比率 ≥1.5 / ≥3 / ≥6 → 基础道 +10% / +25% / +40%（封顶 +40%）

### 1.3 消耗与赌命
- [x] Boss 失败可赌命：第一次 500 道 / 第二次 800 道 / 之后 1200 道
- [x] 道不足则本局失败
- [x] 跳过盲注不给道；标签「鼠·寻道」「马·竞速」直接给道

### 1.4 分位校准（验收标准）
| 玩法强度 | 十天结束道 | 结果 |
|---|---|---|
| 频繁赌命 / 大量跳过 | < 2000 | 只能第 10 天硬打天龙 |
| 稳定通关 | 2600 ~ 3100 | 正常 |
| 高超额少赌命 | 3200 ~ 3500 | 逼近提前开战 |
| 全程极限 | 3600+ | 触发提前结局 |

### 1.5 反通胀三约束
- [x] 道只由战斗产出（不与金钱/分数绝对值挂钩）
- [x] 单项奖励倍率封顶 +40%
- [x] 唯一消耗是赌命且价格递增

## 2. 挑战与隔离

- [x] `SMODS.Challenge{ key = 'zhongyan' }`，开局把 `G.GAME.win_ante` 置为 **10**（原版默认 8，见 §23）
- [x] 起始：标准牌组 + 1 张随机回响小丑 + $4 + 0 道
- [x] 完整隔离（§23）：`Joker`(含稀有度池与 `ObjectTypes.Joker.rarity_pools`) / `Tarot` / `Tarot_Planet` /
      `Spectral` / `Consumeables` / `Voucher` / `Tag` / `Edition` / `Seal` / `Sticker` 全部只留本模组；
      `G.P_TAGS` / `G.P_BLINDS` 只留本模组；原版内容进 `G.GAME.banned_keys`
- [x] 商店不再出现原版星球牌 / 原版扑克；卡包数量置 0
- [x] 退出或普通局还原原池（快照深拷贝 + 原地回填）
- [x] HUD 注入「道」计数器（hook `create_UIBox_HUD`）
- [x] 盲注击败时结算道（hook 盲注完成流程）
- [x] Boss 失败时的赌命判定
- [x] 道 ≥ 3600 触发天龙提前降临

## 3. 小丑（30 张 · 回响）

牌面名称格式：`回响名-持有者`（如 `生生不息-齐夏`）；稀有度只看回响名部分，2 字 = 普通(1)、3 字 = 罕见(2)、4 字 = 稀有(3)

### 3.1 洞见
- [x] 灵视 | 普通 | 苏闪 | 手牌上限 +1
- [x] 灵闻 | 普通 | 齐夏 | 每回合首次出牌为同花或顺子时，返还 1 次出牌
- [x] 灵嗅 | 普通 | 郑应雄 | 计分时手中每张带强化/版本/蜡封的牌 +15 Chips（上限 +90）
- [x] 魂迁 | 普通 | 章晨泽 | 手牌被摧毁时，其点数 +1 转移给左侧手牌

### 3.2 破法
- [x] 离析 | 普通 | 赵海博 | 每次出牌后 1/4 概率摧毁本次打出的一张牌，+$2
- [x] 招灾 | 普通 | 韩一墨 | 回合结束 1/3 概率摧毁随机 2 张手牌，本牌永久 +8 Mult
- [x] 爆燃 | 普通 | 宋明辉 | 使用消耗品时 1/4 概率不消耗
- [x] 破万法 | 罕见 | 乔家劲 | 每回合首次出牌解除当前盲注限制，并 +1 次出牌

### 3.3 生成与复制
- [x] 巧物 | 普通 | 张丽娟 | 使用消耗品后 1/3 概率返还一张同名牌
- [x] 显灵 | 普通 | 李香玲 | 本回合用过消耗品则回合结束生成 1 张随机塔罗
- [x] 原物 | 普通 | 老孙 | 每回合开始向手牌加入 1 张石头牌
- [x] 赝品 | 普通 | 秦丁冬 | 由本牌生成的牌只给一半分数，每次生成永久 +2 Mult
- [x] 探囊 | 普通 | 李尚武 | 回合结束花 $3，把牌堆随机 1 张强化牌加入手牌
- [x] 癫人 | 普通 | 楚天秋 | 每出售 1 张消耗品永久 +3 Mult
- [x] 双生花 | 罕见 | 钱多多 | 每次出牌把手中最强强化复制给同点数其他手牌
- [x] 生生不息 | 稀有 | 齐夏 | 每 3 回合生成 1 张随机负片小丑（上限 3）

### 3.4 概率与赌运
- [x] 强运 | 普通 | 云瑶 | 概率效果分子 +1（`context.fix_probability`）
- [x] 激发 | 普通 | 林檎 | 本回合每次概率成功再 +1 分子（上限 +3）
- [x] 祸水 | 普通 | 肖冉 | 回合开始 1/2：本回合 ×1.5，否则本盲注需求 +25%
- [x] 入梦 | 普通 | 程敖宇 | 回合结束 1/4 手牌上限 +1（整局限 3 次）
- [x] 因果 | 普通 | 江若雪 | 打出 1 级牌型 ×1.5 Mult，否则 +15 Chips

### 3.5 免伤与存续
- [x] 替罪 | 普通 | 陈俊南 | 每弃 1 张牌 +$1
- [x] 嫁祸 | 普通 | 陆潇潇 | 盲注 debuff 改为让随机 1 张小丑失效
- [x] 忘忧 | 普通 | 罗十一 | 免疫所有 debuff，但全部计分 ×0.8
- [x] 不灭 | 普通 | 姜十 | 每局第一次分数不足不死：分数清零并消耗 1 次出牌
- [x] 天行健 | 罕见 | 张山 | 回合结束未弃牌 +15 Mult，弃过牌 +40 Chips

### 3.6 节奏与操控
- [x] 跃迁 | 普通 | 金元勋 | 每使用 1 张消耗品 +1 出牌（每回合上限 2）
- [x] 夺心魄 | 罕见 | 燕知春 | 每回合首次出牌前，把手中点数最高的牌改为与另一张同点数
- [x] 传音 | 普通 | 周末 | 计分时复制左侧相邻小丑的 +Mult 一次
- [x] 挪移 | 普通 | 马十二 | 弃牌时 1/4 概率该牌回手（不计弃牌消耗）

## 4. 塔罗（21 张）

> **描述约定**（§27）：主文案写「做什么」，最后一行固定用 `{C:inactive}（…）` 写「什么时候能用 /
> 边界与并列规则 / 是否永久」，与原版「（必须有空位）」同一风格。每张塔罗都必须有这一行。

### 4.1 基础层（5 张，无花色）
- [x] 权柄 | 选中至多 2 张手牌点数变 A
- [x] 镜像 | 复制选中的 1 张手牌
- [x] 阶梯 | 手中所有牌点数 +1（A→2）
- [x] 契约 | 摧毁选中的 1 张手牌，+$10
- [x] 丰饶 | 手中每张牌 +$1

### 4.2 十二生肖（12 张，全部带花色处理）
- [x] 鼠·仓库寻道 | 选中 1 张 → 牌堆中所有同花色牌加入手牌
- [x] 牛·障碍赛跑 | 选中至多 3 张：同花色则各 +3 点数，否则各 +1
- [x] 虎·狭路相逢 | 选中 2 张不同花色：低者摧毁、高者变万能牌；同花色各 +$3
- [x] 兔·蓬莱 | 选中 1 张 → 花色变为手中数量最少的花色
- [x] 龙·跷跷板 | 手中所有牌花色统一为数量最多的花色
- [x] 蛇·少数与多数 | 最少花色所有牌 +30 Chips；最多花色的牌各 +$2
- [x] 马·木牛流马 | 手中所有牌花色轮换一位（黑桃→红桃→梅花→方片→黑桃）
- [x] 羊·四情扇 | 手中所有牌花色随机重掷
- [x] 猴·箱中道 | 选中 1 张 → 与随机另一张互换花色
- [x] 鸡·兵器牌 | 选中并摧毁 1 张 → 同花色其他牌各变随机强化
- [x] 狗·传信人 | 选中 2 张互换花色
- [x] 猪·黑白棋子 | 选中 1 张：1/2 变万能牌，否则变黑桃

### 4.3 四神兽（4 张，确定性单花色转化）
- [x] 青龙·东方 → 全部变黑桃
- [x] 朱雀·南方 → 全部变红桃
- [x] 白虎·西方 → 全部变方片
- [x] 玄武·北方 → 全部变梅花

## 5. 幻灵（10 张）

> 与塔罗同一套描述约定（§27）：每张都要写清使用条件与边界。

- [x] 二重身 | 复制价值最高的小丑并变为负片
- [x] 反物质 | 所有小丑变负片
- [x] 献祭 | 摧毁价值最低的可摧毁小丑，获得售价 ×3
- [x] 熵增 | 手中所有牌变随机强化
- [x] 回声 | 返还本回合已用掉的出牌次数
- [x] 道城·轮回 | 返还本回合已消耗的出牌与弃牌次数
- [x] 玉城·记忆 | 恢复本局已使用的最后 3 张消耗品中的 1 张
- [x] 涡城·漩涡 | 手牌洗回牌堆并重抽等量
- [x] 勾城·契约 | 本盲注需求 ×1.5；**击败该盲注时**获得的道 ×2（只能用于小/大盲注）
- [x] 索城·索引 | 以手中**点数最高**的牌为基准，把牌堆中所有同点数牌加入手牌

## 6. 优惠券（8 组 16 张）

| 基础 | 升级 | 效果 | 升级 |
|---|---|---|---|
| [ ] 面试房间协作合同 | [ ] 深度协作 | 每回合首次弃牌不消耗次数 | 前两次 |
| [ ] 良人守则 | [ ] 良人守则·补 | 手牌上限 +1 | +2 |
| [ ] 生肖守则 | [ ] 生肖守则·飞升 | 击败 Boss 额外 1 个标签 | 2 个 |
| [ ] 生肖飞升对赌合同 | [ ] 对赌合同·终 | 出牌次数 -1，Boss 金钱 ×2 | ×3 |
| [ ] 眼球移植 | [ ] 双眼移植 | 开局随机获得 1 张回响小丑 | 2 张 |
| [ ] 面具 | [ ] 永久回响者 | 小丑免疫 debuff，但不能用幻灵 | 扩到消耗品 |
| [ ] 巨钟 | [ ] 钟鸣不止 | 每回合揭示牌堆顶 3 张 | 6 张 |
| [ ] 空间列车 | [ ] 永恒列车 | 每个底注可额外跳过 1 次 | 2 次 |

## 7. 标签（16 张）

- [x] 鼠·寻道 | `immediate` | 获得 40 道
- [x] 牛·负力 | `immediate` | 本回合 +1 出牌次数
- [x] 虎·强势 | `new_blind_choice` | 重掷下一个 Boss 盲注
- [x] 兔·脱身 | `immediate` | 本回合 +2 弃牌次数
- [x] 龙·称量 | `eval` | 击败 Boss 额外 +$25
- [x] 蛇·诡问 | `new_blind_choice` | 免费开启一个秘术包
- [x] 马·竞速 | `immediate` | 每张已打出的牌 +2 道
- [x] 羊·伪饰 | `store_joker_modify` | 商店 1 张小丑变负片
- [x] 猴·取物 | `store_joker_create` | 免费获得 1 张回响小丑
- [x] 鸡·夺械 | `store_joker_create` | 免费获得 1 张生肖塔罗
- [x] 狗·传信 | `voucher_add` | 免费获得 1 张优惠券
- [x] 猪·博弈 | `immediate` | 1/2 概率金钱翻倍，否则减半
- [x] 玄武·公正 | `eval` | 本盲注失败不结算失败（一次性）
- [x] 白虎·调停 | `immediate` | 解除当前盲注 debuff
- [x] 朱雀·审判 | `immediate` | 摧毁 1 张随机小丑，获得 $30
- [x] 青龙·之首 | `voucher_add` + 生成 | 免费优惠券 + 1 张负片小丑

## 8. 盲注（12 生肖 Boss）

> 早期设计表与本表不同（8/12 项），**以本表为准**——它是实际实现（`content/blinds.lua`），
> 游戏内描述与之一致。审计过程与修复见 §26。

| key | 名称 | 级 | 效果 | 实现方式 |
|---|---|---|---|---|
| `blh_rat` | 人鼠·仓库寻道 | 人 | 方片全部失效 | `debuff = { suit = 'Diamonds' }` |
| `blh_ox` | 人牛·障碍赛跑 | 人 | 出牌次数 **-1** | `set_blind` + `hands_sub = 1`（原版 The Needle 同款字段） |
| `blh_tiger` | 人虎·狭路相逢 | 人 | 人头牌全部失效 | `debuff = { is_face = 'face' }` |
| `blh_rabbit` | 人兔·蓬莱 | 人 | 弃牌次数清零 | `set_blind` + `discards_sub`（原版 The Water 同款字段） |
| `blh_snake` | 地蛇·少数与多数 | 地 | 梅花全部失效 | `debuff = { suit = 'Clubs' }` |
| `blh_horse` | 地马·木牛流马 | 地 | 需求分数 **×2.2** | `mult = 2.2`（`chips = get_blind_amount(天) × mult`） |
| `blh_goat` | 地羊·四情扇 | 地 | 红桃全部失效 | `debuff = { suit = 'Hearts' }` |
| `blh_monkey` | 地猴·箱中道 | 地 | 手牌上限 **-1**；每次出牌随机弃 1 张手牌 | `change_size(-1)` + `press_play` |
| `blh_rooster` | 天鸡·兵器牌 | 天 | 人头牌全部失效 | `debuff = { is_face = 'face' }` |
| `blh_dog` | 天狗·送信人 | 天 | 手牌上限 **-2** | `change_size(-2)` |
| `blh_pig` | 天猪·黑白棋子 | 天 | 需求分数随机 **×0.8 ~ ×1.4** | `set_blind` 直接乘 `G.GAME.blind.chips` |
| `blh_dragon` | 天龙·天秤游戏 | 天（最终） | 黑桃/梅花占比极端（0 张或全）时计分 **×0.5**；强度 **×(1+⌊道/500⌋×0.1)** | `modify_hand` + `set_blind` |

出场：`boss.min` 分段（1–3 / 4–7 / 8–9），天龙 `min = 10, showdown = true`；
`get_new_boss` 只认 `min` 与 `showdown`，故 1–9 天不会出现天龙、第 10 天只可能是天龙。

## 9. 版本 / 封印 / 贴纸

> 早期表与本表不同（多数项与实现不符），**以本表为准**——它就是 `content/{editions,seals,stickers}.lua` 的实际实现，
> 每个数值都有 `dev/test_blh.lua` 的行为断言（§33 审计：`== 版本 / 封印 / 贴纸 / 优惠券 行为与边界 ==`）。

### 9.1 版本（5，替换原版 Foil / Holo / Polychrome，保留原版负片）

| key | 名称 | 效果（实现） | shader |
|---|---|---|---|
| `blh_echo` | 回响 | 每次出牌本牌永久 +2 倍率；计分时返还累计值 | `foil` |
| `blh_fragrance` | 清香 | 每次出牌 +$1 | `holo` |
| `blh_ripple` | 波纹 | 计分时 ×1.2 倍率 | `polychrome` |
| `blh_zodiac` | 生肖 | 计分时 +30 筹码 | `hologram` |
| `blh_beast` | 神兽 | 计分时 ×1.1 倍率，且每次出牌 +$2 | `foil` |

全部声明 `prefix_config = { shader = false }`（否则引擎按模组前缀找 `blh_foil` 之类不存在的 shader 会崩，见 §17），并带 `in_shop`/`weight`。

**结算上下文（v2.4.0 修正，P0 级）**：版本效果只有两个合法入口，且**小丑与扑克牌不同**：

| 载体 | 引擎传入的 context | device 证据 |
|---|---|---|
| 小丑 | `pre_joker`（成长/筹码/给钱）、`post_joker`（倍率） | `functions/state_events.lua:682`、`:772`；`:689` 会把 `joker_main` 里的 edition 显式清空 |
| 扑克牌 | `main_scoring = true` 且 `cardarea == G.play` | `functions/common_events.lua:744-749`（任何带版本的卡都会走 `card:calculate_edition`），计分主循环传 `{main_scoring=true, cardarea=G.play}` |

`pre_joker` 只在小丑区循环里产生（`state_events.lua:679` 循环），扑克牌永远不会命中它；而版本池 cull 只看 `in_shop`（`functions/common_events.lua:2271-2272`），
所以标准补充包给扑克牌 roll 版本时（`card.lua:2103-2105`）本模组的 5 个版本都会落到扑克牌上。
v2.4.0 前只认 `pre_joker`/`post_joker` → **扑克牌上的版本完全不生效（静默失效）**，现已按原版写法补上
（原版 `SMODS/_/src/game_object.lua:3685/3718/3751` 同样是 `pre_joker`/`post_joker` 或 `main_scoring + cardarea == G.play`）。
两个条件在小丑上互斥（引擎分两次调用），在扑克牌上同时成立，因此「神兽」必须合并返回，否则会互相吃掉一段。

### 9.2 封印（5，替换原版红/蓝/金/紫）

| key | 名称 | 效果（实现） | 触发点 |
|---|---|---|---|
| `blh_dao` | 道印 | 打出时 +5 道 | `context.main_scoring` + 出牌区 |
| `blh_yu` | 玉印 | 打出时 +$3 | `context.main_scoring` + 出牌区 |
| `blh_wo` | 涡印 | 弃掉时生成 1 张随机塔罗（槽位满则不给，事件内二次复查） | `context.discard` |
| `blh_zodiac` | 生肖印 | 打出时额外触发 1 次（`repetitions = 1`） | `context.repetition` |
| `blh_beast` | 神兽印 | 打出时 +10 筹码、+$2 | `context.main_scoring` + 出牌区 |

封印状态一律存在**卡牌自身**（`card.seal` / `card.ability.seal.*`），不使用任何全局状态。

### 9.3 贴纸（5，仅在小丑上，且仅在挑战内启用）

| key | 名称 | 效果（实现） | 说明 |
|---|---|---|---|
| `blh_memory` | 记忆保留 | 计分时 +10 筹码 | |
| `blh_deep_echo` | 深度回响化 | 每次计分 +3 倍率，**最多叠加 5 层**（最高 +15） | 文案「最多叠加 5 次」现在真的参与计算 |
| `blh_native` | 原住民 | 计分时 +12 倍率 | |
| `blh_ant` | 蝼蚁 | 每张计分牌 +$1 | |
| `blh_mask` | 面具 | 计分时 +8 倍率 | |

5 张贴纸都声明 `sets = { Joker = true }` 与 `rate = 0.15`，并靠 `needs_enable_flag` 由挑战的
`rules.custom` (`enable_blh_memory` … `enable_blh_mask`) 启用——**只在「终焉之地」里出现**（SMODS 判定：
`G.GAME.modifiers['enable_'..key]`，见参考源码 `src/game_object.lua:3173`）。

> 已知 WARN（不修）：三张固定数值贴纸（记忆保留/原住民/面具）在 `calculate` 里内联了数值，
> `config` 只用于展示。数值一致、行为正确，但改 `config` 不会改效果。

## 10. 美术与图集

统一尺寸：卡面类 71×95；标签 / 盲注筹码 34×34。
全部图集由 `dev/gen_art.py` 程序化生成（纯标准库，无 PIL），同时输出 `assets/1x` 与 `assets/2x`。

| 图集 | 内容 | 实际像素 (1x) | 排布 |
|---|---|---|---|
| [x] blh_joker.png | 30 小丑 + 5 版本 | 426×570 | 6 列 × 6 行（小丑 y0–4，版本占 y5） |
| [x] blh_tarot.png | 21 | 497×285 | 7 列 × 3 行 |
| [x] blh_spectral.png | 10 | 355×190 | 5 列 × 2 行 |
| [x] blh_voucher.png | 16 | 568×190 | 8 列 × 2 行 |
| [x] blh_seal.png | 5 | 355×95 | 5 列 × 1 行 |
| [x] blh_sticker.png | 5 | 355×95 | 5 列 × 1 行 |
| [x] blh_tag.png | 16 | 272×68 | 8 列 × 2 行 |
| [x] blh_blind.png | 12 盲注 × 21 帧 | 714×408 | **21 列（x = 动画帧）× 12 行（y = 盲注）** |

> 盲注的行列方向按设备源码确定：`x` 走帧、`y` 选动画行，与 §20 的结论一致。

## 11. 验证

- [x] 全部 Lua 语法通过
- [x] JSON / PNG 校验
- [x] 桩测试：全部注册器数量、每张卡的边界条件、道结算数值、天龙反刷公式
- [x] 真机清单：挑战可见、池隔离生效、道 HUD 显示、盲注结算、赌命、第十天打天龙、退出模式后原版池还原


---

## 12. 实现状态

- [x] 系统层：`systems/economy.lua`（道 + HUD + 结算 + 赌命 + 反刷）、`systems/pools.lua`（挑战 + 池隔离）
- [x] 内容层：30 小丑 / 21 塔罗 / 10 幻灵 / 16 优惠券 / 16 标签 / 12 生肖 Boss / 5 版本 / 5 封印 / 5 贴纸
- [x] 美术：8 张图集（1x + 2x）程序化绘制
- [x] 验证：15 个 Lua 语法通过、JSON/PNG 校验、51 项桩测试通过

## 13. 实现偏差（重要）

原设计中以下效果需要拦截原版流程（销毁消耗品、免疫 debuff、可摧毁性等），
这些钩子在 smods 里没有公开接口，为保证可运行，v2 采用了**等价的安全实现**：

| 卡牌 | 原设计 | 实现 | 原因 |
|---|---|---|---|
| 魂迁 | 手牌被摧毁时转移点数 | 弃牌时把点数 +1 转移给随机手牌 | 没有"手牌被摧毁"的上下文 |
| 离析 | 摧毁打出的牌 | 摧毁随机手牌 +$2 | 摧毁计分中的牌会破坏计分流程 |
| 爆燃 | 消耗品概率不消耗 | 弃牌概率爆炸 +$4 | 无法拦截消耗品销毁 |
| 巧物 | 返还同名牌 | 花 $3 造随机塔罗 | 同上 |
| 显灵 | 用过消耗品则生成塔罗 | 手牌有蜡封则生成幻灵 | 无法可靠追踪回合内消耗品使用 |
| 原物 | 回合开始入手牌 | 回合结束进牌堆（石头牌） | 没有"回合开始"钩子 |
| 赝品 | 生成的牌半效 | 概率复制手牌并永久 +2 Mult | 无"生成牌"追踪 |
| 癫人 | 出售消耗品成长 | 持有 ≥$20 时回合结束 +3 Mult | 无出售消耗品的公开上下文 |
| 因果 | 1 级牌型 ×1.5 | 本回合未弃牌 ×1.5 | 避免依赖未核实的 scoring_name |
| 忘忧 | 免疫 debuff | 仅保留 ×0.8 代价的计分版本 | 免疫需 mod 级 set_debuff，未接 |
| 嫁祸 | debuff 转移给小丑 | 概率解除盲注限制并使随机小丑失效 | 近似实现 |
| 版本/贴纸 | 免疫 debuff、不可摧毁等 | 纯计分增益（Mult/Chips/金钱） | 需要 mod 级贴纸钩子 |
| 优惠券 | 额外标签、开局奖励小丑、揭示牌堆 | 槽位/次数/刷新费用等数值型升级 | 需要额外的挑战/商店钩子 |
| 生肖 Boss | 背面牌、兵器牌概率 debuff | 原版声明式 debuff + set_blind（手牌/弃牌/上限） | 保证盲注行为稳定 |
| 牌型 / 卡组 / 补充包 / 强化 | — | 保留原版 | 按你的决定 |

## 14. 真机验收清单（必须人工验证）

- [ ] 挑战列表出现「终焉之地 / Ten Day Ultimatum」
- [ ] 进入后商店只出本模组小丑/塔罗/幻灵/优惠券/标签，且普通局退出后原版池恢复
- [ ] HUD 左上显示「道」计数器，击败盲注后数值按公式增长
- [ ] 道 ≥ 500 时 Boss 失败触发赌命（扣道并免死）
- [ ] 不灭小丑触发免死并扣 1 手牌上限
- [ ] 道 ≥ 3600 触发天龙提前降临
- [ ] 天龙强度随道提升（需求分数显示变大）
- [ ] 十二生肖 Boss 的限制与解除（disable）正常
- [ ] 生肖塔罗的花色操作全部生效（检索/归一/轮转/随机/交换/万能）
- [ ] 塔罗/幻灵/优惠券/标签的卡面无错位（图集坐标）

---

## 15. 官方文档合规复核（对照 docs.smods.dev API 文档）

复核对象：SMODS.Blind / SMODS.Tag / SMODS.Voucher / SMODS.Consumable / SMODS.Seal /
SMODS.Sticker / SMODS.Challenge / Calculate-Functions 上下文清单。

### 发现并修复的问题（均为会导致功能失效的错误）

| # | 问题 | 文档依据 | 修复 |
|---|---|---|---|
| 1 | 生肖 Boss 图集摆成 12 列 × 21 行，`pos = {x=i, y=0}` | Blind 文档："`y` 决定用哪一行动画，`x` 被忽略并循环帧" | 图集改为 **21 列（帧）× 12 行（盲注）**，`pos = { x = 0, y = i }` |
| 2 | `debuff = { rank = 'face' }` | Blind 文档：合法字段为 `suit / value / nominal / is_face / hand / h_size_ge / h_size_le` | 改为 `debuff = { is_face = true }`（人虎、天鸡） |
| 3 | 优惠券 `requires = { 'blh_xxx' }` | Voucher 文档：requires 必须是**完整键**（`v_` 类前缀 + 模组前缀） | 8 处改为 `v_blh_xxx`（升级券此前永远不会出现） |
| 4 | 贴纸使用未文档化的 `apply_to_card`，且读取自行命名的 `ability` 键 | Sticker 文档：只有 `apply` / `should_apply` / `calculate` / `loc_vars`；`config` 存到 `card.ability[sticker_key]` | 删除 `apply_to_card`，数值内联，改用标准字段 |
| 5 | 贴纸 `needs_enable_flag = true` 但从未设置启用标记 | Sticker 文档：需要 `G.GAME.modifiers['enable_'..key]` | 在挑战 `rules.custom` 中加入 5 条 `enable_blh_*`（`no_ui = true`） |
| 6 | 玄武·公正标签在 `eval` 上下文返回 `{saved = true}` | Calculate 文档：`saved` 只在 `context.end_of_round` 有效 | 改为 `immediate` 标签发放"免死充能"，由经济系统在失败时消耗 |
| 7 | 牛/兔标签在 `apply` 里直接改状态 | Tag 文档：应通过 `tag:yep(msg, colour, func)` 的 `func` 执行 | 移入 `yep` 回调 |
| 8 | 祸水直接改写 `G.GAME.blind.chips` | Calculate 文档：返回 `blindsize` / `xblindsize` 即可增乘盲注需求 | 改为返回 `{ xblindsize = 1.25 }` |
| 9 | 盲注惩罚只在 `disable` 还原 | Blind 文档：`disable`（被禁用）与 `defeat`（被击败）是两个还原时机 | 两者都接幂等还原函数 |
| 10 | 主题 `SMODS.ObjectType` 建了池但从未填充 | Center 文档：`pools` 用于登记内容到 ObjectType | 挑战启动时把本模组全部中心登记进 `G.P_CENTER_POOLS.blh_zhongyan` |

### 复核通过（无需修改）

- `use(self, card, area, copier)` / `can_use(self, card)` / `loc_vars(self, info_queue, card)` ✅
- `calculate(self, card, context)` 与盲注 `calculate(self, blind, context)` ✅
- 用到的上下文全部在官方清单内：`before / main_scoring / individual / repetition / joker_main / after / discard / end_of_round / using_consumeable / fix_probability / blueprint` ✅
- 返回键合法：`chips / mult / xmult / dollars / message / colour / repetitions / saved / numerator / denominator` ✅
- `SMODS.Atlas` 动画图集：`atlas_table = 'ANIMATION_ATLAS'` + `frames` ✅
- `SMODS.Challenge`：`deck / rules.custom / rules.modifiers / jokers / consumeables / vouchers / restrictions` ✅
- `SMODS.Seal`：`loc_txt.label` + `config` → `card.ability.seal` ✅

### 验证

- 15 个 Lua 文件语法通过
- 桩测试 **59 项**全通过（新增 8 项文档合规断言：debuff 字段白名单、requires 完整键、贴纸字段、标签 apply、消耗品 set/use/can_use、小丑行为函数、封印 label、盲注 y 行动画）
- 盲注图集尺寸复核：1x = 714×408，2x = 1428×816 ✅

---

## 16. 真机崩溃分析与修复（Steamodded v26.829.0）

崩溃日志：`lovely-2026.09.25-21.12.53.log`（iOS 端）＋ dump 归档。

### 崩溃原因（100% 由本模组引起）

```
[SMODS _ "src/game_object.lua"]:32: Missing required parameter for Edition declaration: shader
  at content/editions.lua line 10 (from mod with id beiklive_helper)
```

`SMODS.Edition` 的 `required_params = { 'key', 'shader' }`（dump 源码注释：可设 `false` 表示无 shader）。
5 个版本都没写 `shader` → 加载到 editions.lua 时 `assert` 失败，游戏启动即崩。
两次崩溃日志（21:12:55 与 21:13:27）都是同一处。

### 关键环境事实（修正之前的对照基准）

- 设备实际运行 **Steamodded v26.829.0**（日志 `SMODS :: Steamodded v26.829.0`），
  我之前对照的是本地 `beta-1814a`，两者 `game_object.lua` / `overrides.lua` 有差异。
- 设备装有 **Malverk**（会 patch smods，dump 中可见 `-- Removed by Malverk`）。
- 设备 smods 无 `SMODS.Attribute`、无 Blind 的 `big/small` → 确实低于/等于 26.829.0 特性面；
  本模组未使用这些新特性。

### 本轮修复

| # | 问题 | 证据（设备源码） | 修复 |
|---|---|---|---|
| 1 | **Edition 缺 `shader` → 启动崩溃** | `required_params = { 'key', 'shader' }` | 5 个版本全部补 `shader`（复用原版已确认存在的 `foil/holo/polychrome/hologram`） |
| 2 | `debuff = { is_face = true }` 不生效 | `blind.lua:713`：`self.debuff.is_face =='face'` | 改为 `is_face = 'face'`（与文档写 `true` 不一致，以源码为准） |
| 3 | **免死/赌命整体失效** | `state_events.lua:104-108`：26.829.0 的 `end_round` 改为 `SMODS.calculate_context({end_of_round...})` + `if SMODS.saved then game_over = false end`，不再逐个 `calculate_joker` | 删除 `Card:calculate_joker` 钩子，改为官方 `mod.calculate` + 返回 `{ saved = true }` 并显式置 `SMODS.saved`；不灭小丑自身 `calculate` 保留兜底 |
| 4 | 崩溃不便定位 | Mod Object 文档：`mod.debug_info` | 增加 `mod.debug_info`（版本/模式/内容量），下次崩溃界面直接显示 |

### 复核为"无误"的钩子（在 26.829.0 设备源码上确认存在）

- `game.lua:1927` `starting_params = get_starting_params()` → 起始金钱/次数注入有效 ✅
- `blind.lua:310` `Blind:defeat` → 道结算有效 ✅
- `blind.lua:191/377/404/507` `obj.set_blind / obj.defeat / obj.disable / obj.press_play` → 生肖 Boss 效果与还原有效 ✅
- `tag.lua:62` `Tag:yep(message, colour, func)`、`tag.lua:133` `obj:apply(self, _context)` → 标签有效 ✅
- `UI_definitions.lua` `create_UIBox_HUD` → 道 HUD 注入有效 ✅
- `animatedsprite.lua` `setViewport(frame_offset, h*y, w, h)` → 帧沿 **x** 推进、`y` 选行动画；
  与"21 列 × 12 行 + `pos={x=0,y=i}`"一致 ✅
- `card.lua:3430+` Mr. Bones 的 `{saved = true}` 返回 → 免死机制语义确认 ✅

### 验证

- 15 个 Lua 文件语法通过
- 桩测试 **64 项**全通过（新增：Edition 必须有 shader、`is_face == 'face'`、`mod.calculate` 存在、赌命扣道 500、无道时不返回 saved）

---

## 17. 第二次真机崩溃（点击"版本"）：shader 前缀

### 现象

在收藏/图鉴里点击「版本（Edition）」卡片即崩：

```
engine/sprite.lua:97: attempt to index a nil value
(3) draw_shader  _shader = string: "blh_foil"
(4) src/card_draw.lua:315  edition = {type:blh_echo, key:e_blh_echo}
```

### 原因

`prefix_config` 文档说明：**默认会给对象的 `shader` 字段加上模组前缀**（源码 `game_object.lua:82-83`
`SMODS.modify_key(obj, mod.prefix, shader_cfg, 'shader')`）。
我的 `shader = 'foil'` 被改写成 `blh_foil`，而 `G.SHADERS` 里没有这个键 →
`sprite.lua` 的 `G.SHADERS[_shader]:send(...)` 索引 nil → 崩溃。

### 修复

5 个版本全部加 `prefix_config = { shader = false }`，让 `shader` 原样指向原版 shader。

> 排查同类风险：只有**显式写在对象上的引用字段**会被加前缀（源码用 `rawget` 判断），
> 因此「版本」的默认 `atlas='Joker'`（类默认值）不受影响；`Voucher.requires` 不在前缀列表，
> 已改用完整键 `v_blh_*`；我的图集键本身带 `blh_` 前缀，命中 `modify_key` 的幂等保护，不会双重前缀。

## 18. 调试功能：一键解锁全部内容

| 入口 | 适用平台 | 说明 |
|---|---|---|
| 模组设置页「解锁全部内容（调试）」按钮 | **移动端可用** | 模组菜单 → beiklive助手 → Config → 点击按钮 |
| `Ctrl + U` | 键鼠/外接键盘 | `SMODS.Keybind { key_pressed = 'u', held_keys = { 'lctrl' } }` |

实现（`systems/debug.lua`）：遍历 `SMODS.Jokers / Consumables / Vouchers / Tags / Blinds / Editions /
Seals / Stickers`，把属于本模组的对象全部置 `discovered = true, unlocked = true`，
并调用原版 `set_discover_tallies()` 刷新图鉴计数；完成后弹出提示显示解锁数量。

注意：这是**临时解锁**（运行时字段），重开游戏或点图鉴刷新后以正式解锁状态为准；
本模组内容本身多数已声明 `discovered = true`，该工具主要用于标签/盲注等默认未解锁项。

---

## 19. 素材重制（对照游戏原始素材的形制）

参考 `game_original_files/resources/textures/1x` 的实际尺寸与形状，**只作为形制参考，未复制任何原始素材**。

### 原始素材形制调查

| 图集 | 原始尺寸 | 单元 | 真实形状 |
|---|---|---|---|
| Jokers.png | 710×1520 | 71×95（10×16） | 整卡：**透明圆角**（角像素 alpha=0）＋深色描边＋浅色内框＋满幅插画＋**左侧竖排「JOKER」** |
| Tarots.png | 710×570 | 71×95（10×6） | 羊皮纸底＋棕金**双线花框**＋四角菱形饰＋中央插画＋**底部名牌**；行星牌为青绿配色、幻灵为深蓝配色 |
| Vouchers.png | 639×380 | 71×95（9×4） | 高饱和底色＋**白色内描边**＋顶部「VOUCHER」小牌＋中央图标 |
| BlindChips.png | 714×1054 | 34×34（**21 列帧 × 31 行**） | **圆形筹码**（外环纹理＋内盘＋符号＋顶部小字），四角透明；**帧沿 x 推进、y 选行**（与 `AnimatedSprite:setViewport(frame_offset, h*y, w, h)` 一致） |
| tags.png | 204×170 | 34×34（6×5） | **圆角小牌**＋浅色边框＋立体倒角，四角透明 |
| stickers.png | 355×285 | 71×95（5×3） | **左上角一颗 ~14px 小圆徽章**，其余全透明（贴纸按整卡尺寸绘制在卡左上） |
| Enhancers.png | 497×475 | 71×95（7×5） | 强化＋卡背＋**封印**（同样为左上角小徽章：`G.shared_seals` 用 {x=4,y=4} 等） |

### 重制内容

- 新增 **3×5 位图字体**（A–Z/0–9/符号），用于：小丑左侧竖排「JOKER」、塔罗/幻灵底部名牌（21 张卡各自的名字）、优惠券顶部「VOUCHER」、盲注筹码顶部小字（RAT/OX/TIGER…）
- **卡面形制**：透明圆角＋描边＋内框；小丑为满幅插画＋底饰线；塔罗为羊皮纸双线花框＋角饰＋名牌；幻灵为深蓝双线框＋星点＋名牌；优惠券为高饱和底＋白描边＋顶部牌＋中央图标
- **主体图形库扩到 36 组**（场景式，非单图标）：王冠·面具·眼·月·蛇·门·宝箱·骰·闪电·烈焰·涟漪·螺旋·金币·钥匙·钟·列车·塔·天平·折扇·灯笼·叶·剑·盾·镜·书·沙漏·齿轮·水滴·莲·石柱·骷髅·手·蛛·针·锚·迷宫
- **盲注重画为圆形筹码**（外环纹理逐帧旋转，21 帧真实动画），四角透明
- **标签重画为圆角小牌**（浅框＋倒角＋符号）
- **封印/贴纸重画为左上角小徽章**（不再铺满整卡）：验证结果为封印 bbox (3,3)-(20,20)、贴纸 bbox (1,1)-(20,20)，与原版一致
- **版本**改用自绘展示图：小丑图集扩为 6×6（30 小丑＋5 版本展示＋1 备用），版本声明 `atlas='blh_joker', pos={x=i,y=5}`

### 生成过程踩到并修掉的 3 个渲染 bug

1. 超采样画布未按 k 倍缩放坐标 → 图形只画在左上角 1/6 区域（改为所有图元内部按 `k` 缩放）
2. `put()` 忽略 alpha=0，`rrect_outline` 无法挖空 → 内框色铺满整卡（改为 alpha=0 也写入，可擦除）
3. `line()` 先缩放点、`poly()` 再缩放一次 → 双重缩放导致线稿类图形（螺旋/折扇/天平）画到画布外（改为只由 `poly` 缩放）

### 验证

- 8 张图集尺寸全部与代码坐标一致：joker 426×570、tarot 497×285、spectral 355×190、voucher 568×190、seal/sticker 355×95、tag 272×68、blind 714×408（2x 各自翻倍）
- 视觉核对：小丑（整卡插画＋竖排 JOKER）、塔罗（羊皮纸花框＋名牌）、优惠券（VOUCHER 牌）、盲注（圆形筹码＋顶部小字＋逐帧旋转）、标签（圆角小牌）
- 代码侧仅新增版本展示图的 `atlas/pos`，其余 key/坐标不变

---

## 20. 素材第三版：解决"图案元素看起来都一样"

反馈：形制对了，但**每张卡都是"纯色底 + 居中图标 + 底部横线"，构图完全雷同**。
因此重写绘制层，把"变化"从**单一维度（图形）**扩展到**四个维度**。

### 现在每张卡的差异来源

| 维度 | 数量 | 说明 |
|---|---|---|
| 主体图形 | 36 组场景式插画 | 王冠·面具·眼·月·蛇·门·宝箱·骰·闪电·烈焰·涟漪·螺旋·金币·钥匙·钟·列车·塔·天平·折扇·灯笼·叶·剑·盾·镜·书·沙漏·齿轮·水滴·莲·石柱·骷髅·手·蛛·针·锚·迷宫 |
| 构图模板 | 6 种 | 居中主体 / 地平线 / 角位主体+圆环 / 双主体 / 圆章 / 横带 |
| 背景纹理 | 8 种 | 放射线 / 同心弧 / 对角分割 / 横条 / 撒点 / 网格 / 渐晕环 / 人字纹 |
| 配色方案 | 2 类×多色 | **1/3 浅底深墨 + 2/3 深底亮墨**，色相按卡片索引散列 |

组合选择同时依赖**行号与列号**（`idx*7 + col*2 + row*5`），避免出现"同一列永远是同一种构图/背景"的规律性重复；
36 组图形保证**单张图集内不重复**（小丑 30、塔罗 21、幻灵 10、优惠券 16，均 < 36）。

### 各类别的专属元素

- **盲注**：新增 15 组**粗剪影符号**（梅花/红桃/黑桃/方片/骷髅/眼/月牙/星/闪电/浪/箭头/面具/钥匙/金币/螺旋），
  内盘符号半径放大到 7.6（原来 6.6 太小看不清），并加 4 种环纹样式（刻度/长刻/圆点/双环）——只有 12 张盲注，符号与环纹都不重复
- **标签**：同样用粗剪影符号 + 4 种面板纹理（素面/横条/撒点/人字），16 张各不相同
- **封印/贴纸**：徽章内改用粗剪影符号，5 张各不同

### 同时修掉的两个渲染 bug

1. **竖排 "JOKER" 标签不可见**：`text_v` 里用 `put()` 直接写坐标，而 `put()` 写的是**单个画布像素**（不缩放），
   在 6 倍超采样画布上等于只点亮了 1/36 的像素点 → 改为按超采样倍率铺成 k×k 方块后才可见
2. **竖排文字镜像**：原实现按字符逐像素映射，方向反了 → 改为"整段渲染到临时画布后整体旋转 90°"，
   现在自下而上阅读，与原版一致

### 验证

- 4× 放大检视图逐项核对：小丑（左侧竖排 JOKER 清晰可读）、塔罗（DOMINION/MIRROR 名牌清晰）、
  幻灵（DOPPELGANGER 名牌清晰）、优惠券（VOUCHER 牌清晰）、标签（粗剪影+圆角牌）、盲注（圆形筹码+顶部小字）、封印/贴纸（左上小徽章）
- 8 张图集 1x/2x 尺寸全部与代码坐标一致
- 版本升至 2.2.0

---

## 21. 第三轮真机问题（盲注说明崩溃 / 解锁无效 / 中英混杂）

### ① 查看盲注说明崩溃

```
functions/misc_functions.lua:869: attempt to index local 'C1' (a nil value)
  mix_colours(C1=nil, C2=..., 0.4)
  ← old_blind_popup (UI_definitions.lua:4529)  ← create_UIBox_blind_popup
```

原版 `create_UIBox_blind_popup` 里有 `mix_colours(blind.boss_colour, G.C.GREY, 0.4)`，
而 `mix_colours` 直接索引 `C1[1]` → **模组 Boss 盲注必须声明 `boss_colour`**，否则一点说明就崩。

**修复**：12 个生肖盲注全部补 `boss_colour = HEX('.....')`（每只一个专属色）。

### ② 调试解锁无效果（小丑仍显示未知）

两个原因叠加：

1. **`SMODS.Jokers` 这张表在 26.829.0 里并不存在**（dump 里只有 `SMODS.Tags / Seals / Stickers / Atlases`），
   我原来的 `pairs(SMODS.Jokers or {})` 于是静默空转，一张都没解锁。
2. 我的 30 张小丑没有写 `discovered`，而 `SMODS.Joker` 类默认 `discovered = false`，
   所以图鉴里一直是"未知"。

**修复**：
- 解锁逻辑改为遍历**真正承载数据的运行时表**：`G.P_CENTERS / G.P_TAGS / G.P_BLINDS / G.P_SEALS / G.P_CENTER_POOLS`
  （外加存在才扫的 `SMODS.*` 汇总表），深度遍历 + 去重 + 限深；
- 归属判定改为**双判据**：`obj.mod == mod` 或 key 含模组前缀 `blh_`（后者对任何版本都成立）；
- 顺带把贴纸需要的 `enable_blh_*` 标记一起打开；
- 30 张小丑补 `discovered = true`（与其它类别一致）。

### ③ 中文界面里混着英文

根因：**`localize` 遇到不存在的键返回字符串 `'ERROR'`（不是 nil）**，
所以我写的 `localize('k_win_ex') or 'Boom!'` 兜底永远不会生效，玩家看到的是 `ERROR`。
缺失的键共 5 个：`k_win_ex / k_immune_ex / k_plus_dollars / k_plus_hand / k_plus_card`。

**修复**：改用自有文案键并补齐中英两份，删除全部失效兜底：

| 原写法 | 现写法 | 中文 |
|---|---|---|
| `localize('k_win_ex') or 'Boom!'` | `blh_msg_boom` | 爆炸！ |
| `localize('k_win_ex') or 'Lucky!'` | `blh_msg_lucky` | 幸运！ |
| `localize('k_plus_tarot') or '+Tarot'` | `blh_msg_tarot` | +1 塔罗 |
| `localize('k_plus_spectral') or '+Spectral'` | `blh_msg_spectral` | +1 幻灵 |
| `localize('k_plus_card') or '+Card'` | `blh_msg_card` | +1 手牌 |
| `localize('k_plus_dollars') or '+$'..n` | `blh_msg_dollars`..n | +$n |
| `localize('k_plus_hand') or '+1 Hand'` | `blh_msg_hand` | +1 出牌次数 |
| `localize('k_immune_ex') or 'Immune'` | `blh_msg_immune` | 免疫 |

保留的 `k_disabled_ex / k_plus_tarot / k_plus_spectral / k_upgrade_ex / k_again_ex / k_duplicated_ex / k_nope_ex / k_safe_ex`
均已确认存在于原版本地化。

> 说明：卡面贴图里烘焙的英文（竖排 JOKER、塔罗名牌 DOMINION、VOUCHER 牌、盲注筹码顶部 RAT/OX）
> 与原版一致——原版塔罗/星球/优惠券贴图同样带英文名，游戏不会翻译贴图内文字。

### 新增的自动回归检查（桩测试 71 → 76 项）

- 每类对象都必须有 `loc_txt['zh_CN']`
- 所有盲注必须声明 `boss_colour`
- 所有小丑必须 `discovered = true`
- 代码中出现的每个 `localize('k_*')` 原版键都必须真实存在（防止再次写成 `ERROR`）
- 解锁工具在真实表结构下必须返回 > 0

---

## 22. 卡片功能边界审计（回合结束 / 跨阶段触发）

针对「回合结束后加入卡牌的能力，是否会在过关后仍然触发」这类跨阶段边界，做了三轮：
静态作用域扫描 → 行为回归测试 → 与设备版原版源码逐条比对。

### 22.1 扫描方法

`dev/boundary_report.py` 把全部内容文件切成对象块，对每个 `context.*` 触发器按**缩进判定 if 块作用域**，
再标记块内的危险操作（改手牌 / 改牌堆 / 摧毁 / 改手牌上限 / 动金钱 / 动道 / 一次性标记），输出矩阵：

- 扫描对象：17 类 / 92 个对象（Joker 30、Tarot 21、Spectral 10、Voucher 16、Tag 16、Blind 12、Edition 5、Seal 5、Sticker 5、Challenge/ObjectType 等）
- 触发器覆盖：`joker_main` 17、`before` 9、`end_of_round` 9、`discard` 7、`individual` 4、`blueprint` 3、`first_hand_drawn` 2、`after` 1、`setting_blind` 1
- 结论：**回合结束分支内改动手牌 / 牌堆 / 弃牌堆的操作 = 0 处**

### 22.2 真实修掉的问题

| # | 对象 | 现象 | 根因 | 修复 |
|---|---|---|---|---|
| 1 | 赝品 | 回合结束复制的牌会消失 | `end_of_round` 之后手牌整区会被回合重置清掉，复制进手牌等于白做 | 回合结束只掷骰挂 `extra.pending`，改为 `context.first_hand_drawn` 时再实体化复制 |
| 2 | 探囊 | 同上（付了钱拿不到牌） | 同上 | 回合结束只扣钱挂 `pending`，首手抽完后从牌堆取牌到手 |
| 3 | 生生不息 | 标注 `cap = 3`，实际产出 9 张负片小丑 | 用 `count - every < cap * every` 判断次数，`cap=3/every=3` 时 count 3..11 都成立 | 改为 `count % every == 0 and made < cap`，新增 `made` 计数（仅真正生成时 +1），描述同步显示 `made/cap` |
| 4 | 巧物 | 延迟生成事件期间槽位被占满会白扣 $3 | 扣钱与 `create_card` 之间有 0.2s 延迟窗口 | 事件内二次检查失败则 `ease_dollars(cost)` 退款 |
| 5 | 不灭（兜底分支） | 可能与 economy 的免死入口同 pass 双触发，绕过「充能 → 不灭 → 赌命」优先级直接扣手牌上限 | 兜底 `calculate` 只查 `blh_saved_round`，同 pass 内若它先于 `mod.calculate` 执行，标志尚未置位 | 兜底增加前置条件 `not (SMODS.current_mod and SMODS.current_mod.calculate)`；主路径统一由 `mod.calculate` 处理 |
| 6 | 原物 / 赝品 / 镜像 | 手动 `G.deck.config.card_limit = card_limit + 1` | 旧版写法；设备版 `create_playing_card` 只做 `G.playing_card++ / add_to_deck / G.playing_cards / emplace`，不碰牌堆上限。SMODS 的 `card_limits` 模型下这个赋值会写进无意义的 `mod` | 三处手改全部移除，交给原版 helper 与 `G.playing_cards` |
| 7 | 免死标记 | 救过一次后整局再也救不了 | `blh_saved_round` 从不复位 | `mod.calculate` 在 `not context.game_over` 时复位 |
| 8 | 提前天龙 | 已通关仍触发提前天龙判定 | `check_early` 未判断 `G.GAME.won` | 加 `G.GAME.won` 短路 |
| 9 | 道结算 | `Blind:defeat` 重复调用会重复发道 | 无幂等标记 | `blind.blh_settled` 幂等 |
| 10 | 涡印 / 生生不息 / 巧物 / 显灵 | 消耗品区 / 小丑栏满时溢出或空操作 | 事件内未二次检查容量 | 事件内二次检查 `card_limit` |
| 11 | 赝品 / 探囊 / 镜像 / 原物 | 加入牌堆/手牌的牌不吃盲注 debuff、不排序、不触发"加牌"类小丑 | 只做了 `add_to_deck` + `emplace`，漏掉原版 Certificate / Marble 的配套流程 | 补 `G.GAME.blind:debuff_card(card)`、`G.hand:sort()`、`playing_card_joker_effects({card})` |

### 22.3 逐条复核后判定为「安全」的写法（非 bug）

| 对象 | 写法 | 为何安全 |
|---|---|---|
| 巧物 / 显灵 | `end_of_round` 生成塔罗 / 幻灵到 `G.consumeables` | **消耗品区不随回合重置**；原版 Cartomancer 就是「回合结束造塔罗」 |
| 生生不息 | `end_of_round` 生成负片小丑到 `G.jokers` | **小丑区不随回合重置**；原版 Riff-Raff 同类 |
| 招灾 | `end_of_round` 摧毁 2 张手牌 | 原版 Ceremonial Dagger 就是在 `end_of_round` 用 `SMODS.destroy_cards`；手牌此时仍在场 |
| 入梦 | `end_of_round` `G.hand:change_size(1)` | 设备版 `CardArea:change_size` 写 `config.card_limits.mod`，该值随存档序列化且不随回合重置；`CardArea:update` 只重算 `total_slots` 并保留 `mod` |
| 灵视 | `add_to_deck` / `remove_from_deck` 对称 ±1 | 与原版 Juggler（`config.h_size`）等价；`Card:add_to_deck`/`remove_from_deck` 本身就做对称 ± |
| 二重身 | 无 `card_limit` 检查 | 复制品是**负片**（不占小丑栏），且 `can_use` 已要求 `eligible_jokers(true) > 0`（无小丑 / 全负片时不可用） |
| 镜像 | `G.deck.config.card_limit + 1`（已移除） | `can_use` 已查 `#G.hand.cards < G.hand.config.card_limit` 与选中 1 张 |
| 赝品 / 探囊 | 用 `context.first_hand_drawn` 落地 | 设备版 `functions/state_events.lua:378` 确实派发该上下文，且原版 **Certificate** 就是「首手抽完后往手牌加牌」；其值 `= not any_hand_drawn and G.GAME.facing_blind`，跳过盲注时为假，挂起标记会留到下一次真正出牌 |

### 22.4 消耗品可用性边界（`dev/canuse_audit.py`，26 个消耗品，`can_use` × 资源依赖）

自动核对「`use` 里用到了某资源 → `can_use` 必须检查该资源」，结果 **26/26 全部命中**：
手牌/选牌数（`highlighted()` / `G.hand`）、牌堆（`G.deck`）、消耗品区（`G.consumeables`）、小丑（`G.jokers`）。

### 22.5 新增自动回归（桩测试 76 → 119 项）

`dev/test_blh.lua`（`luajit dev/test_blh.lua`）新增「跨阶段边界」检查组：

- 静态：`end_of_round` 的 if 块内（按缩进作用域）不得出现 `G.hand:emplace` / `create_playing_card` / `G.deck:remove_card` / `G.hand:remove_card`
- 静态：常规 `end_of_round` 分支必须带 `main_eval`；失败分支必须显式 `SMODS.saved = true`
- 静态：使用 `extra.pending = true` 的对象必须存在 `extra.pending = nil` 的消费点
- 行为：赝品回合结束手牌数不变 + `pending` 置位；首手后才 +1 且成长生效
- 行为：探囊回合结束只扣钱、不动牌区；首手后强化牌确实从牌堆移到手牌
- 行为：`BLH.settle_blind` 幂等；勾城契约只对签约盲注翻倍
- 行为：免死标记每回合复位；真失败时消耗充能并置 `SMODS.saved`；同回合不重复消耗
- 行为：生生不息总产出 = cap，节奏为第 3/6/9 回合，栏满时不产出也不扣 cap
- 行为：巧物有钱有槽位才扣钱，槽位满 / 钱不够不扣
- 行为：不灭兜底在存在 mod 级入口时不抢触发、不误扣手牌上限
- 行为：赝品 / 镜像加牌后确实调用了 `playing_card_joker_effects`、`G.hand:sort()`、`G.GAME.blind:debuff_card()`
- 行为：镜像加牌后手牌 +1 且配套流程齐全

### 22.6 仍需真机确认

- 赝品 / 探囊在 **Boss 盲注过关** 与 **跳过盲注** 两种路径下首手分支都能到达（`first_hand_drawn` 只在正常进入出牌阶段时派发；跳过盲注不走该阶段，此时挂起标记会保留到下一次真正出牌——属预期，但需确认不会跨回合堆积）。
- 入梦的 `change_size` 在 **存档 / 读档** 后是否与 `card_limits.mod` 一致（依赖设备版 SMODS 的序列化）。

---

## 23. 持有者署名 + 挑战模式完全隔离原版

### 23.1 小丑牌名加持有者

30 张小丑的牌名统一改为 `回响名-持有者`（例：`生生不息-齐夏`），
中英双语同步（英文用拼音，`Endless Creation - Qi Xia`）。
稀有度仍按**回响名**字数判定，测试改为先剥离 `-持有者` 后缀再数（按 UTF-8 字符数，不是字节数）。

### 23.2 完整隔离：挑战内原版内容一律不可获得

原实现只过滤了 `Joker/Tarot/Spectral/Voucher/Tag/Boss盲注`，本轮补齐并修掉 5 个真实泄漏：

| # | 泄漏 | 后果 | 修复 |
|---|---|---|---|
| 1 | 隔离发生在 `Game:start_run` 的**返回之后** | `init_game_object` 里掷出的本回合优惠券、跳过盲注标签、盲注都是按**未隔离**的池掷的 → 第一商店可能出现原版优惠券、跳过盲注可能给原版标签 | 隔离提前到 `start_run_ref` **之前**执行；调用后再补一次（读档进入挑战时用） |
| 2 | `win_ante` 从未设置 | 实际是原版默认 **8** → 天龙（showdown Boss）第 8 天就出现，"第 10 天终局"与提前天龙都不成立 | 开局置 `G.GAME.win_ante = 10` |
| 3 | `G.GAME.planet_rate = 4`（原版默认） | 商店卡位约 14% 会出现原版**星球牌** | 置 0 |
| 4 | `boosters_in_shop = 2` | 商店会出现原版**卡包**（Buffoon/Tarot/Spectral/Standard/Celestial），卡包内容也是原版池 | 置 0（同时 `modifiers.extra_boosters = 0`） |
| 5 | 直接替换池表 | `SMODS.ObjectTypes.Joker.rarity_pools` 等持有旧表引用；若启用对象权重模式（`object_weights`），原版小丑仍可能被 `poll_object` 取到 | 改为**原地清空 + 回填**，并对原始表做**深拷贝**快照，`restore()` 才有内容可还原 |

另外 `G.P_CENTER_POOLS['blh_zhongyan']` 原实现用 `SMODS.Jokers / Consumables / Vouchers` 收集，
但这三个表在 26.829.0 **并不存在** → 主题池一直是空的。现改为从实际池（稀有度池 + Tarot/Spectral/Voucher）收集。

### 23.3 隔离范围（最终）

| 类别 | 处理 |
|---|---|
| 小丑 | `G.P_JOKER_RARITY_POOLS` + `ObjectTypes.Joker.rarity_pools` + `G.P_CENTER_POOLS.Joker` 原地只留本模组（25/4/1） |
| 塔罗 / 幻灵 / 消耗品总池 / 星球塔罗池 | `Tarot` / `Spectral` / `Consumeables` / `Tarot_Planet` 只留本模组 |
| 优惠券 / 标签 / 版本 / 封印 / 贴纸 | `Voucher` / `Tag` / `Edition` / `Seal` / `Sticker` 池只留本模组；`G.P_TAGS` 只留本模组 |
| Boss 盲注 | `G.P_BLINDS` 保留 `bl_small`/`bl_big`（底注结构）+ 本模组 12 生肖 Boss，原版 Boss 全删 |
| 星球 / 卡包 / 强化 | **不**清空池（本模组无这三类内容，清空会让 `create_card` 命中"空池兜底"并强行返回原版卡 `c_pluto`/`c_base`），改为关闭获取途径：商店 rate = 0 + 卡包数量 = 0。原版强化（如石头牌 `m_stone`）本模组自身还在用，因此不清也不禁 |
| 原版其余内容 | 全部 key 写入 `G.GAME.banned_keys`（由 `apply_banned_keys()` 在开局写入，**不**经过挑战的 `restrictions`，原因见 §25）；含原版标签、原版 Boss 盲注、原版版本（`e_foil` 等）、原版封印/贴纸 |

**为什么默认封印/贴纸只禁 key、不删表**：`card.lua` 会无条件索引 `G.P_SEALS[self.seal]`，
删表会让任何带封印的牌在绘制/结算时直接报错；只禁 key 同样能阻断随机获取。

**为什么"空池兜底"必须避开**：`get_current_pool` 在池里一个可用项都没有时会走
`elseif _type == 'Joker' then _pool[#_pool+1] = 'j_joker'` 之类的兜底分支，
把原版卡强行塞回来。所以"禁用"与"清空池"不是一回事：有自有内容的类别才清池，没有的类别只关途径。

### 23.4 新增自动回归（桩测试）

- 30 张牌名都符合 `回响名-持有者`；英文名带 Holder 段；回响名字符数与稀有度一致
- 挑战开局后 10 个中央池 + 稀有度池 + `ObjectTypes.Joker.rarity_pools` 均无原版内容，且仍有本模组内容
- **表引用不变**（原地回填）：塔罗池 / 稀有度池 / 标签表 / 盲注表 / ObjectType 稀有度池
- `win_ante = 10`、`planet_rate = 0`、`playing_card_rate = 0`、`boosters_in_shop = 0`、`extra_boosters = 0`
- `init` 阶段掷出的原版优惠券 / 原版跳过标签被重掷为本模组内容
- `restrictions` 三个列表都是普通表且为空；每项（若有）必须能在 `G.P_CENTERS` / `G.P_TAGS` / `G.P_BLINDS` 解析出对象
- `G.GAME.banned_keys` 含原版小丑/塔罗/幻灵/优惠券/版本/标签/Boss 盲注，不含小/大盲注，不含本模组内容
- 可见的自定义规则里有 `blh_hardcore`（对应 `ch_c_blh_hardcore` 文案）
- 退出挑战（普通局 `start_run`）后所有池与表**还原**（含 ObjectType 稀有度池）

### 23.5 仍需真机确认

- 挑战内连续打 10 个底注：Boss 应依次落在 1–3（鼠/牛/虎/兔）、4–7（蛇/马/羊/猴）、8–9（鸡/狗/猪）、10（天龙）。
- 商店 2 个卡位只出本模组小丑/塔罗/幻灵：**没有星球牌、没有卡包、没有原版优惠券**。
- 退出挑战进入普通局后，收藏与商店里的原版内容恢复。

---

## 24. 中文文案修正：倍率 / 筹码 / 概率分数

用户反馈：中文界面里 `Mult`、`Chips`、以及 `1 in 4`（几分之几）仍是英文写法。原实现把中文描述直接照着英文文案写，
只改了颜色标签，没换词。参照原版 `localization/zh_CN.lua` 的措辞统一：

| 项 | 原版中文写法 | 本模组修正前 | 修正后 |
|---|---|---|---|
| 倍率 | `{C:mult}+#1#{}倍率` | `{C:mult}+#1#{} Mult` | `{C:mult}+#1#{}倍率` |
| 筹码 | `{C:chips}+#1#{}筹码` | `{C:chips}+#1#{} Chips` | `{C:chips}+#1#{}筹码` |
| 概率 | `有{C:green}#1#/#2#{}几率` | `{C:green}#1# in #2#{} 概率` | `{C:green}#1#/#2#{} 概率` |
| 当前值注记 | `{C:inactive}（当前为{C:mult}+#2#{C:inactive}倍率）` | `{C:inactive}(当前 {C:mult}+#2#{C:inactive} Mult)` | 同原版 |
| debuff | `失效` | `debuff` | `失效` |

共修正 **41 处中文串**（`{...}` 颜色标签只做掩码，避免误改 `C:mult` 这类标签本身），另修 10 处概率分数、
`main.lua` 的 `mod.debug_info`（版本面板可见）改为中文、`生肖 Boss` → `生肖盲注`。

同时统一：中文数值段后面必须带单位（`{C:mult}+#1#{}倍率` / `{C:chips}+#1#{}筹码`），
英文文案保持 `Mult` / `Chips` / `1 in 4` 不变。

### 新增自动回归（168 项）

- 任一对象的 `zh_CN` 文案不得出现 `Mult` / `Chips`
- `zh_CN` 概率必须是 `#1#/#2#` 形式；`en-us` 必须仍是 `#1# in #2#`
- `zh_CN` 文案不得有英文残留（白名单：`Boss`）
- `{C:mult}/{X:mult}/{C:chips}` 数值段必须紧跟「倍率 / 筹码」
- 文案检查覆盖 ≥110 个对象

### 过程事故（记录，避免再犯）

第一轮批量替换脚本的 span 取的是「含引号的整个字面量」，却用「不含引号的新内容」去替换，
结果 7 个内容文件的 41 个中文字面量**丢了引号**（工作区无 git，无法回滚）。
第二遍脚本按 `loc()` 第 3 个参数（中文文本表）逐元素检测「未加引号的元素」并补回引号，
再用「解析元素数」对比中英文元素数验证结构未错位（0 处不一致），全部语法检查通过。
教训：批量改字符串必须保留引号，改完立刻 `luajit -bl` 验证。

---

## 25. 真机崩溃：点「终焉之地」的「限制条件」页 → `card.lua:277`

### 25.1 现象与调用链

```
点击挑战描述页的 Restrictions 分页
→ functions/UI_definitions.lua:6236  (vanilla tab_definition_function，被 CardSleeves 包裹)
   for k, v in ipairs(challenge.restrictions.banned_cards) do
       local card = Card(0,0,W,H, nil, G.P_CENTERS[v.id], {...})
   end
→ card.lua:277 Card:set_ability 处 attempt to index local 'center' (a nil value)
```
崩溃时局部变量：`banned_cards` 是我们的清单，`n_rows = 30`，`v = {id: tag_ethereal}`。

### 25.2 根因

原版「限制条件」页对 `restrictions.banned_cards` 的每个元素都会**创建一张卡牌精灵**，
中心取 `G.P_CENTERS[v.id]`。而 §23 里我把 **标签 / 盲注** 的 key 也塞进了这个列表，
它们的对象在 `G.P_TAGS` / `G.P_BLINDS` 里，**不在 `G.P_CENTERS`** → `center = nil` → 崩。

附带问题（同样要避开）：
- 原版全部卡牌有 600+ 项，全部塞进 `banned_cards` 会让这个页面逐张画精灵，移动端不可行。
- 当时用的是 `restrictions.banned_cards = 函数`：vanilla 只在**新开一局**时才把它替换成结果表，
  而挑战描述页（开一局之前）会直接 `#challenge.restrictions.banned_cards` / `pairs` 它 —— 函数会直接报错。

### 25.3 修复

| 项 | 修复 |
|---|---|
| `restrictions.banned_cards / banned_tags / banned_other` | 全部改回**空普通表**（页面显示原版的「无」占位） |
| 原版内容禁用 | 全部改由 `apply_banned_keys()` 在开局写 `G.GAME.banned_keys`（时机在 `init_game_object` 之后；隔离池在此之前已完成，所以 init 阶段掷优惠券/标签也不会碰原版） |
| 玩家可见性 | 规则栏加一条**可见**自定义规则 `blh_hardcore`，文案键 `ch_c_blh_hardcore`（zh/en 均补），说明「禁用全部原版内容」 |

`G.P_SEALS` / `G.P_STICKERS` 仍然只加 `banned_keys`、不删表（`card.lua` 会无条件索引 `G.P_SEALS[self.seal]`）。

### 25.4 新增自动回归（174 项）

- `restrictions` 三项必须是**普通表**（函数会让 UI `pairs/ipairs` 崩）
- `restrictions` 中每一项（若有）必须能在 `G.P_CENTERS` / `G.P_TAGS` / `G.P_BLINDS` 解析出对象
  —— 这条直接锁死本次崩溃的前置条件
- `banned_cards` 保持短列表（≤10，不做 600 张精灵展示）
- `G.GAME.banned_keys` 含原版小丑/塔罗/幻灵/优惠券/版本/标签/Boss 盲注，不含小/大盲注，不含本模组内容
- 可见自定义规则里有 `blh_hardcore`

---

## 26. 盲注（Boss）效果审计

逐个核对 12 张生肖盲注「描述 vs 实现 vs 设备版分派点」，发现并修掉 4 类问题。

### 26.1 设备版 `blind.lua` 实际分派哪些盲注钩子

`/tmp/dump`（26.829.0）里 `blind.lua` 全部分派点：

| 行 | 分派 | 含义 |
|---|---|---|
| 191 | `obj:set_blind()` | 盲注登场（读档走 `Blind:load`，**不会**再调用它） |
| 377 | `obj:defeat()` | 被击败 |
| 404 | `obj:disable()` | 被禁用（本模组的「破万法」就调用 `G.GAME.blind:disable()`） |
| 507 | `obj:press_play()` | 按下出牌（原版 The Hook 在此弃牌） |
| 553 | `obj:modify_hand(cards, poker_hands, text, mult, hand_chips)` | 计分修正（原版 The Flint） |
| 565 | `obj:debuff_hand(...)` | 该手牌是否被封印 |
| 620 | `obj:drawn_to_hand()` | 抽牌后 |
| 689 / 697 | `obj:recalc_debuff` / `obj:debuff_card` | 单张牌的 debuff 判定 |

**`blind.lua`（原版）里没有 `blind.calculate` 的分派点**；不过 SMODS 自己的
`utils.lua` 里定义了 `function Blind:calculate(context)`（本地参考 beta-1814a:2342），
并从「个体计分目标」里调用，所以 `calculate` 在 SMODS 下确实会触发。
即便如此，本模组仍把关键效果放在上表中原版就会分派的钩子上：
`modify_hand` 是原版 The Flint 用的计分修正入口，`press_play` 是原版 The Hook 用的出牌时机入口，
比依赖 SMODS 内部实现更稳（26.829.0 的 `utils.lua` 未在设备 dump 中，无法逐行核对）。

### 26.2 修掉的问题

| # | 问题 | 证据 | 修复 |
|---|---|---|---|
| 1 | **人牛文案与行为不符**：描述「出牌次数 -1」，实现却是 The Needle 式「只留 1 次」（基础 4 手时等于 -3） | `hands_sub = G.GAME.round_resets.hands - 1` | 改为 `hands_sub = 1` + `ease_hands_played(-1)`；描述不变 |
| 2 | **地猴 / 天龙的效果挂在 `blind.calculate` 上**（可能永不触发）：地猴「每次出牌后随机弃 1 张」、天龙「天秤失衡计分 ×0.5」 | 26.1：`blind.lua` 无该分派点 | 地猴改 `press_play`（同 The Hook，`hook = true` 不消耗弃牌次数）；天龙改 `modify_hand`（返回 `mult/2, hand_chips, true`） |
| 3 | **读档后惩罚无法还原**：施加标记 `_applied` 与次数存在 SMODS.Blind **中心对象**上，中心是单例且字段不入存档；`Blind:load` 又不会重调 `set_blind` → 读档后标记丢失，`defeat/disable` 直接返回，**手牌上限的减少会被永久留在牌局里** | `Blind:save`（774 行）只保存固定字段；`Blind:load` 不调用 `set_blind` | 次数类改用原版会进存档的 `hands_sub` / `discards_sub`（The Needle / The Water 同款）；手牌上限在「当前盲注确实是本盲注」时无条件还原；并补 `disable` 后 `defeat` 不二次还原（对齐原版 The Manacle 的 `not self.disabled` 判断） |
| 4 | **天猪 / 天龙的缩放标记会跨登场残留**：标记写在 `G.GAME.blind`（整个 run 复用同一个实例，`set_blind` 不会清自定义字段）→ 同一 Boss 第二次上场（无尽模式/提前天龙后再遇）不再缩放 | `Blind:save/load` 与 `set_blind` 的字段重置列表 | 改为「本次登场一次」：中心上打标，`defeat` / `disable` 时清除 |

### 26.3 复核通过（无需修改）

- **debuff 字段**：`blind.lua:687` 只认 `suit` / `value` / `nominal` / `is_face == 'face'` / `hand` / `h_size_ge` / `h_size_le` —— 本模组只用了 `suit` 与 `is_face = 'face'` ✅
- **`mult` / `dollars` 语义**：`chips = get_blind_amount(天) × mult × ante_scaling`（135 行）、`dollars` = 击败奖励 ✅ 地马的 ×2.2 生效路径正确
- **`boss_colour`**：12 张全部声明（缺了会在盲注说明弹窗崩溃，见 §21）✅
- **出场覆盖**：按 `get_new_boss` 的真实判定（只看 `min` 与 `showdown`）模拟 1–10 天：每天都 ≥1 个可用 Boss，1–9 天无 showdown，第 10 天只有天龙 ✅ 不会退回原版 `bl_wall`
- **HUD 需求分数**：`UI_definitions.lua:1459` 用 `ref_table = G.GAME.blind, ref_value = 'chip_text'` 实时绑定，`set_blind` 里改 `chips/chip_text` 会立刻反映到界面 ✅
- **时序**：`obj:set_blind()` 在 `chips` 计算之后调用（135 → 191），所以天猪/天龙可以直接改 `chips`，不需要延迟事件 ✅

### 26.4 新增自动回归（215 项）

- 12 张盲注的 `boss_colour` / `mult` / `dollars` / 图集坐标
- 1–10 天出场覆盖、1–9 天无 showdown、第 10 天仅天龙
- `debuff` 字段白名单 + `is_face` 必须是字符串 `'face'`
- 禁止使用未被分派的 `blind.calculate`；天龙必须有 `modify_hand`、地猴必须有 `press_play`
- 行为：人牛 -1 且幂等、人兔清零且幂等、**读档后（自定义标记清空、`hands_sub` / `discards_sub` 来自存档）仍能还原**
- 行为：地猴/天狗手牌上限还原；`disable` 后 `defeat` 不二次还原（否则白赚手牌上限）
- 行为：天猪缩放落在 ×0.8~×1.4、重复调用不叠加、**新一次登场会重新缩放**
- 行为：天龙 1000 道时强度 ×1.2；黑桃/梅花占比极端时 `modify_hand` 返回减半 + `triggered = true`，混合花色时不减半
- 行为：地猴 `press_play` 恰好弃 1 张、`hook = true`（不消耗弃牌次数）

### 26.5 仍需真机确认

- 人牛在场时左上角出牌次数应为「3」（原为 1）。
- 地猴：每次出牌时手里随机少 1 张牌；击败后手牌上限回到 8。
- 天龙：全场黑桃（或完全不含黑桃/梅花）时打出的那一手，倍率与筹码被砍半并弹出「天秤失衡」提示。
- 天猪：需求分数在基础值的 0.8~1.4 倍之间，且 HUD 数字同步变化。

---

## 27. 描述完整度审计（塔罗 / 幻灵）

用户反馈「很多塔罗牌的描述仍然不清楚不完整」。逐张把 `loc_txt` 与 `can_use` / `use` 对齐后，
问题集中在三类：**使用条件不可见**、**边界规则没写**、**文案与实现不一致**。

### 27.1 描述约定（已统一）

主文案写「做什么」（含选中张数），最后一行固定用 `{C:inactive}（…）` 写三件事之一：

1. **什么时候能用**：需要选中恰好 N 张 / 手牌至少 N 张 / 手牌需有空位 / 牌堆需有同花色或同点数牌；
2. **边界与并列规则**：并列时按 `黑桃→红桃→梅花→方片` 取第一个、点数上限为 A、没有同花色其他牌时只摧毁；
3. **是否永久**：筹码加成是永久（`perma_bonus`）而不是本手生效。

### 27.2 修掉的问题

| # | 卡 | 问题 | 修复 |
|---|---|---|---|
| 1 | 虎·狭路相逢 | 同花色分支只写「各 +$3」，看不出总数；点数相同时谁被摧毁没写 | 改为「每张 +$3（两张共 $6）」，`loc_vars` 同时给两个变量；补「点数相同时摧毁先选的那张」 |
| 2 | 蛇·少数与多数 | `+30 筹码` 是**永久**加成（写进 `perma_bonus`），描述看不出来 | 标明「{C:attention}永久{}获得 +30 筹码」 |
| 3 | 牛·障碍赛跑 | 点数到 A 就不再上升（`math.min(14, …)`），描述没提 | 补「点数上限为 A，不会再升」 |
| 4 | 鼠·仓库寻道 | 实际是「加到手牌满为止」（逐张检查 `card_limit`），且需要牌堆里有同花色牌 | 补「需手牌有空位、牌堆里有同花色牌；加到手牌满为止」 |
| 5 | 镜像 | `can_use` 还要求手牌有空位，描述没有 → 玩家看到「用不了」却不知原因 | 补「需手牌有空位」，并写明复制品保留强化 / 版本 / 蜡封 |
| 6 | 龙·跷跷板 / 兔·蓬莱 | 花色并列时按固定顺序取（Spades→Hearts→Clubs→Diamonds），完全没写 | 两张都补「并列时按 黑桃→红桃→梅花→方片 取第一个」 |
| 7 | 鸡·兵器牌 | 强化是**覆盖**原有强化，且没有同花色其他牌时只摧毁 | 补「会覆盖原有强化」「没有同花色其他牌时只摧毁」 |
| 8 | 猪 / 猴 / 狗 / 契约 / 权柄 / 羊 / 索城·索引 | 只写了效果，没写「需选中恰好 N 张」「手牌至少 N 张」等 `can_use` 条件 | 全部补 `{C:inactive}` 条件行 |
| 9 | **勾城·契约（幻灵）** | 描述写「**通关时**获得 ×2 的道」，实际是**击败该盲注时**结算（`economy.lua` 按 ante + 盲注 key 匹配并 `total * 2`）；且 `can_use` 限定非 Boss 盲注，描述没写 | 改为「击败该盲注时，获得的道 ×2」+「只能在小盲注 / 大盲注时使用，Boss 盲注不可用」 |
| 10 | 玉城·记忆 / 涡城·漩涡 / 道城·轮回 | 同样缺少 `can_use` 条件（消耗品区空位、本局用过消耗品、本回合消耗过次数、手牌非空） | 各补条件行 |
| 11 | 四神兽（4 张） | 只写「手中所有牌变为 X」 | 补「需至少 1 张手牌」；`dev/gen_art.py` 与文案无关，仅描述层改动 |

改动涉及 17 张塔罗 + 4 张神兽（生成器）+ 5 张幻灵；**只改 `loc_txt` 与虎的 `loc_vars`，效果代码一行未动**。

### 27.3 新增自动回归（236 项）

- 每张塔罗都必须含 `{C:inactive}` 条件/边界行；带 `max_highlighted` 的必须写明「选中」
- 每个消耗品（塔罗 + 幻灵）都必须含 `{C:inactive}` 条件行
- `loc_vars` 声明的每个变量（`#1#`…）都必须在描述里真正出现（防止写了变量没用上）
- 中英文行数 / 元素数一致（沿用「本地化」检查组）
- 本次补齐的关键信息点逐一断言：镜像空位、鼠「满为止」、牛「上限」、蛇「永久」、鸡「覆盖」、
  龙与兔「并列」、虎「恰好 2 张」且 `loc_vars` 有两个变量、四神兽「至少 1 张」、
  勾城「Boss 盲注不可用」与「击败该盲注时」、道城「没消耗过」、玉城「有空位」、索城「同点数牌」

### 27.4 仍未做

- 幻灵与塔罗的**卡面**没有把条件印上去（只影响描述面板）——这是美术范畴，见 README「美术素材不足」。
- 原版消耗品描述行数上限约 5 行；本模组目前最多 3 行，后续加长仍需注意面板高度。

---

## 28. 真机反馈：生生不息「推进回合看不到计数增加」

### 28.1 两个原因（都已修）

**原因 A：描述里显示的是「已生成张数」，不是回合计数**

`loc_vars` 原来返回 `{ every, made, cap }`，描述是「（本牌已生成 #2#/#3#）」。
而 `made` **只在真正生成时才 +1**，条件有两个：每 3 回合一次 **且** 小丑栏有空位。
5 个栏位在挑战里通常第 3 回合就满了 → `made` 永远是 `0/3` → 看起来"没生效"。

修复：描述改为 `（已积累 #4# 回合，已生成 #2#/#3#）`，`#4#` 是 `count`，**每个回合结束都会 +1**；
`#2#` 仍是实际生成张数。这样"是否在推进"一眼可见，也不会把"栏满"误读成"没生效"。

**原因 B：`end_of_round` 守卫依赖 `context.main_eval`**

- `main_eval` **不是引擎字段**，而是 SMODS 在 `SMODS.calculate_context` 内部临时塞进去的
  （本地 SMODS 参考 `beta-1814a`：`src/utils.lua:2055` `context.main_eval = true`，只包住小丑那一次遍历）。
- 设备版 26.829.0 的源码 dump 里 **`main_eval` 零出现**；SMODS 的 `utils.lua` 未在 dump 中，无法证实新版仍会塞。
- 但设备版**原版小丑**的 `end_of_round` 分支用的是另一套判定（`card.lua:3280`）：
  `if context.individual … elseif context.repetition … elseif not context.blueprint …`
  —— 完全不看 `main_eval`。

因此把 8 处守卫统一改为设备版原版同款，并保留我们自己的失败判定与 blueprint 保护：

```lua
if context.end_of_round and not context.game_over and not context.blueprint
    and not context.individual and not context.repetition then
```

这套判定在两种情况下都成立：SMODS 塞 `main_eval` 时（小丑那次遍历既非 individual 也非 repetition），
以及将来不再塞时。静态 lint 也放宽为「`main_eval` **或** `not individual + not repetition`」二者任一。

### 28.2 附带修复：栏满时的反馈

原来栏满时仍然返回「复制！」消息（生成在延迟事件里失败），玩家只看到消息、没有牌。
现在**先同步检查栏位**：满则返回原版 `k_no_space_ex`（「没有空间！」），不浪费这次判定、不消耗 cap，
也不显示误导性的成功消息。

### 28.3 新增自动回归（249 项）

- 不带 `main_eval` 的普通 `end_of_round` 上下文就能推进 `count`（1 → 2 → 3）
- 第 3 回合产出 1 张负片小丑、`made` = 1
- `loc_vars` 第 4 个变量是累计回合数、第 2 个是已生成张数（描述顺序锁定）
- `individual` / `repetition` 子通过不重复触发；`game_over` 的失败回合不推进
- 小丑栏满：不产出、不消耗 cap、返回非空提示；腾出位置后继续产出（`made` = 2）
- 静态 lint：常规 `end_of_round` 分支必须有主通过判定（`main_eval` 或 `not individual/repetition`）

### 28.4 仍需真机确认

- 挂上生生不息后连续推进回合：描述里的「已积累 N 回合」应**每回合 +1**。
- 第 3 回合若小丑栏有空位：应出现 1 张**负片**小丑，描述变「已积累 3 回合，已生成 1/3」。
- 小丑栏满时：应弹出「没有空间！」，且不再显示误导性的「复制！」。
- 同时确认其它 `end_of_round` 小丑（招灾 / 巧物 / 显灵 / 赝品 / 探囊 / 入梦 / 天行健 / 癫人）在真机上确实会触发。

---

## 29. 小丑 / 标签审计：静默失败与生效时机

顺着 §28 的问题（"效果看不出在推进"）把 30 张小丑 + 16 张标签逐个对照实现，又找出 4 类真实问题。

### 29.1 功能缺失（承诺了但根本没实现）

| 对象 | 问题 | 修复 |
|---|---|---|
| **忘忧** | 描述写「你的牌不会被任何效果失效」，实现里**只有 ×0.8 惩罚**，免疫完全没写 | 补 `Card:set_debuff` 钩子：持有时把**牌**（`playing_card`）的失效强制为 false；小丑仍可被失效（描述同步说明） |

### 29.2 生效时机错误：获得后立刻消耗、效果白费

| 对象 | 问题 | 修复 |
|---|---|---|
| **牛·负力**（标签） | 跳过盲注拿到标签时立刻 `ease_hands_played(1)`，但那一刻 `new_round()` 还没跑，**下一个盲注开场时 `hands_left` 被整体重置** → 加了等于没加 | 改写 `G.GAME.round_bonus.next_hands`（`new_round` 先算 `round_resets.hands + round_bonus.next_hands` 再清零 bonus），文案改为「下一次出牌回合 +1 出牌次数」 |
| **兔·脱身**（标签） | 同上，`ease_discard(2)` 被下一回合重置抹掉 | 改写 `G.GAME.round_bonus.discards`，文案同步 |
| **白虎·调停**（标签） | 跳过盲注时「当前盲注」其实已经打完，当场 `blind:disable()` 会作用在**旧盲注**上；旧盲注 chips 已满足时还会把状态推成 `NEW_ROUND` | 改为挂起 `G.GAME.blh_break_blind`，由 `mod.calculate` 在下一个盲注的 `setting_blind` 时机解除（已验证 SMODS 会把 mod 作为「个体计分目标」收到**所有** `calculate_context`） |

### 29.3 静默失败（做了但没有任何反馈）

| 对象 | 问题 | 修复 |
|---|---|---|
| **探囊** | 回合结束就扣 $3，而取牌发生在下一回合首手；若**牌堆没有强化牌**或**手牌已满**，钱白扣、什么也没有 | 改为**取到牌才扣钱**；牌堆无强化牌 → `blh_msg_nopick`，钱不够 → `blh_msg_nomoney`，手牌满 → `k_no_space_ex`（并保留挂起，下一回合再试） |
| **巧物** | 钱不够 / 消耗品区满时静默无反应 | 分别给 `blh_msg_nomoney` / `k_no_space_ex` |
| **显灵** | 有蜡封但消耗品区满时静默无反应 | 给 `k_no_space_ex` |
| **挪移** | 掷骰成功但手牌已满时，牌留在弃牌堆却仍显示「再来一次」 | 改成掷骰成功后再查空位，满则 `k_no_space_ex` |
| **猴·取物 / 青龙·之首**（标签） | 用 `SMODS.Jokers` 建池，而该表在 26.829.0 **不存在**（同 §23 的主题池问题）→ 池为空、标签白消耗 | 改用 `our_joker_keys()`：从 `G.P_JOKER_RARITY_POOLS` 取本模组小丑（空则回退扫 `G.P_CENTERS`） |

### 29.4 文案与实现不符

| 对象 | 原文案 | 实际 | 处理 |
|---|---|---|---|
| **双生花** | 「把手中**最强**的强化复制…」 | 取的是手中**第一张**强化牌（没有强度比较） | 文案改为「手中一张强化牌」 |
| **嫁祸** | 「让本盲注的限制**改为**失效 1 张小丑牌」 | 实际是**解除整条盲注限制** + 随机 1 张小丑失效（比描述更强） | 文案改为「解除本盲注的限制，代价是随机 1 张小丑失效」；`victim.debuff = true` 改用 `victim:set_debuff(true)` |
| **离析** | 「每次出牌**后**」 | 实际在 `context.before`（出牌**时**、计分前） | 文案改为「每次出牌时」 |
| **替罪** | 「每弃掉 1 张牌获得 $1」 | 被失效的牌不计 | 补 `{C:inactive}（被失效的牌不计）` |
| **激发** | `(1/4 → 1/3）` 半全角括号混用 | — | 统一为全角 |

### 29.5 顺带修正：跃迁的上限是「每手牌」不是「每回合」

**跃迁**在 `context.before`（每次出牌）清零计数，等于「每手牌最多 2 次」，
还能靠消耗品续手无限滚；描述写的是「每回合最多 2 次」。
改为按回合 id 计（`round_id()`，与 `once()` 同一套）：同回合内出牌不再重置额度。

### 29.6 复核通过（未改）

- `context.*` 白名单核对：`joker_main` / `before` / `after` / `discard`+`other_card` / `individual` /
  `repetition` / `end_of_round` / `game_over` / `first_hand_drawn` / `setting_blind` / `using_consumeable` /
  `fix_probability`+`numerator`+`denominator` 在设备源码或 SMODS 里都有分派点 ✅
  （`using_consumeable`：`button_callbacks.lua:2320`；`fix_probability`：SMODS `utils.lua:3039`）
- `once(card)` 的每回合标识：`G.GAME.round` 在按下盲注时 `ease_round(1)` 自增（`button_callbacks.lua:2633`）✅
- 爆燃 / 魂迁 / 替罪 / 挪移 / 因果 / 天行健 的弃牌上下文与"被失效不计"逻辑 ✅

### 29.7 新增自动回归（279 项）

- 忘忧：无忘忧时牌会失效、持有忘忧时牌不失效、小丑仍可失效
- 跃迁：同回合第 3 张消耗品不再给手；同回合出牌不重置额度；下一回合额度恢复
- 探囊：回合结束**不扣钱**只挂起；无强化牌不扣钱并清挂起；成功取牌才扣 $3；手牌满不扣钱且保留挂起
- 巧物：槽位满 / 钱不够时返回非空提示且不扣钱；显灵：槽位满时返回提示
- 标签：牛/兔 写 `round_bonus`；猴·取物 能从小丑池取到；白虎当场不解除旧盲注、挂起标记在下一次 `setting_blind` 被消费
- 旧断言同步更新（探囊由「回合结束扣钱」改为「取到牌才扣钱」）；桩里的 `Tag:yep` 改为**执行回调**（原版语义）

### 29.8 仍需真机确认

- 跳过盲注拿到「牛·负力 / 兔·脱身」后，下一个盲注开场时出牌/弃牌次数确实多 1 / 多 2。
- 「白虎·调停」应在下一个盲注**进场后**才解除限制，且不影响当前界面状态。
- 「探囊」在牌堆没有强化牌时不再扣钱，并提示「牌堆没有强化牌」。
- 「忘忧」在场时，盲注（如方片失效）不再让方片失效。

## 30. 第四轮审计（v2.3.9 → v2.4.0）：版本在扑克牌上静默失效 + 幻灵使用门槛

第三份独立切片（幻灵 + 版本）返回后，逐条回到设备源码复核，落地以下修改。完整报告见 `AUDIT.md` §15。

### 30.1 版本（Edition）：错的是上下文，不是数值

`pre_joker` / `post_joker` **只在小丑区循环里产生**（`functions/state_events.lua:679` 循环、`:682` pre_joker、`:772` post_joker），
扑克牌永远不会命中它们。而版本池 cull 只看 `in_shop`（`functions/common_events.lua:2271-2272`），
标准补充包会给扑克牌 roll 版本（`card.lua:2103-2105`）→ 本模组 5 个版本落在扑克牌上时**完全没有任何效果**。

扑克牌的入口是 `functions/common_events.lua:744-749`（任何带版本的卡都走 `card:calculate_edition(context)`），
计分主循环传 `{main_scoring = true, cardarea = G.play}`。原版三个版本的写法就是这个组合
（`SMODS/_/src/game_object.lua:3685/3718/3751`：`pre_joker`/`post_joker` **或** `main_scoring and cardarea == G.play`）。

修正：`content/editions.lua` 增加两个上下文助手

```lua
local function before_score(context) return context.pre_joker or (context.main_scoring and context.cardarea == G.play) end
local function after_score(context)  return context.post_joker or (context.main_scoring and context.cardarea == G.play) end
```

- 「神兽」在扑克牌上两个条件同时成立，必须**合并返回** `{xmult, dollars}`，否则先 return 的分支会吃掉另一段。
- 小丑侧不会因此 double-dip：主计分在 `calculate_card_areas('jokers', ...)` 之前把 `context.main_scoring` 置回 nil。
  设备版 `SMODS/src/utils.lua` 未 dump，此条以两份参考源码为准（1814a `utils.lua:2098-2107`、0711a `utils.lua:1872-1881`）→ **[REF-ONLY]**。
- 回响的成长只在 `before_score` 且非 `context.blueprint` 时写入（蓝复制不复制永久成长）。
- 文案从「每张计分牌」统一改为「每次出牌」（小丑上确实每手只结算一次；扑克牌上按计分结算）。

### 30.2 幻灵：`can_use` 必须限定"盲注进行中"

商店里 `G.GAME.blind` 仍然是**已击败的那个盲注**（`blind.lua:188` 的 `in_blind` 只有 `set_blind` 时才为真，
`state_events.lua:280` 才换盲注）。因此：

| 卡 | 修正 |
|---|---|
| 勾城·契约 | 加 `G.GAME.blind.in_blind == true`（否则 +50% 打在死盲注上、奖励永不匹配 = $4 白费）+ `BLH.in_challenge()`（普通局只在挑战内按道结算） |
| 回声 | 加 `G.GAME.blind.in_blind == true` |
| 道城·轮回 | 加 `G.GAME.blind.in_blind == true` |

另外 `content/spectrals.lua` 此前引用**裸全局 `BLH`**（`systems/economy.lua:5` 里是 `local`）→ 勾城 `can_use` 必崩，已补 `local BLH = SMODS.current_mod.blh`。

索城·索引：石头牌等无点数牌的 `base.id` 为 nil（`card.lua:139-141`），原版同类循环带 `SMODS.has_no_rank` 守卫（`card.lua:3713`）；
两处循环已加 `c.base and c.base.id`，`top` 为 nil 时直接返回，`use` 内也兜一次（可能被别的 API 绕过 `can_use` 调用）。

### 30.3 文案

- 熵增：「（保留点数与花色）」→「（点数与花色尽量保留；石头牌/万能牌本身没有点数或花色）」
- 献祭：zh 补「永恒或已负片的小丑不可献祭」，en 由「Eternal Jokers are spared」改为「Eternal or already-Negative Jokers cannot be sacrificed」（en 漏了负片，与实现不一致）
- 二重身：补「售价最高」

### 30.4 新增自动回归（344 → 368 项）

版本：`pre_joker` 结算与累计、`joker_main` 无效、蓝复制不计成长、`main_scoring + cardarea == G.play` 生效、
`G.hand` 不计分、神兽合并返回；幻灵：勾城 4 种门槛、回声/道城盲注内外、索城 nil 卡池与 `use` 直调；文案 6 项（熵增/献祭/二重身，中英各一）。

### 30.5 仍需真机确认

- 标准补充包开出一张带「回响 / 波纹 / 神兽」的扑克牌，打出时确实给对应加成。
- 商店里「勾城·契约」显示为不可用（灰掉），盲注进行中才可点。
- 「索城·索引」在手里有石头牌时不崩、正常抽同点数牌。
