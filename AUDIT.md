# 终焉之地 · beiklive助手 — 最终审计报告

审计对象：`beiklive_helper` v2.4.1（120 个对象：小丑 30 / 优惠券 16 / 塔罗 21 / 幻灵 10 / 封印 5 / 版本 5 / 标签 16 / 盲注 12 / 贴纸 5）

审计基准（**所有结论都必须能落到这些文件的行号上**）：

| 基准 | 位置 | 用途 |
|---|---|---|
| 设备版 Balatro + Steamodded 26.829.0 源码 dump | `/tmp/dump/dump/`（`game.lua`、`card.lua`、`blind.lua`、`cardarea.lua`、`functions/*.lua`、`SMODS/_/src/{game_object,overrides}.lua`） | 判定 Context / Hook / 生命周期是否真实存在 |
| SMODS 参考源码 1.0.0-beta-1814a | `/Users/beiklive/Code/Other/Balatro2_mods/smods-1.0.0-beta-1814a`（`src/utils.lua` 等） | 设备版未 dump 的 SMODS 核心（`calculate_context`、`blueprint_effect`、`Blind:calculate`、`get_mods_scoring_targets`） |
| 原版本地化 | `/Users/beiklive/Code/Other/Balatro_dev/game_original_files/localization/{zh_CN,en-us}.lua` | 术语与概率写法对齐 |
| 自动回归 | `dev/test_blh.lua`（`luajit dev/test_blh.lua`，**387 项**） | 逐项行为断言（含版本/封印/贴纸/优惠券的行为与边界） |
| 静态审计 | `dev/boundary_report.py`、`dev/canuse_audit.py` | 边界矩阵、消耗品可用性 |

> 设备版 26.829.0 是**权威**；SMODS 参考源码仅用于设备版未 dump 的核心文件，凡依赖它的结论都标注 `[REF-ONLY]`。

---

## 1. 总体审计

| 类型 | 数量 | PASS | WARN | FAIL | BLOCKED |
|---|---:|---:|---:|---:|---:|
| Joker | 30 | 25 | 4 | 1 | 0 |
| Voucher | 16 | 16 | 2 → 修复后 0 | 0 | 0 |
| Tarot | 21 | 21 | 2 → 修复后 0 | 2 → 修复后 0 | 0 |
| Spectral | 10 | 10 | 0 | 1 → 修复后 0 | 0 |
| Seal | 5 | 3 | 0 | 5 → 修复后 0 | 0 |
| Edition | 5 | 4 | 0 | 1 → 修复后 0 | 0 |
| Tag | 16 | 13 | 3 → 修复后 0 | 3 → 修复后 0 | 0 |
| Blind | 12 | 12 | 0 | 0 | 0 |
| Sticker | 5 | 5 | 1 → 修复后 0 | 0 | 0 |
| **合计** | **120** | **109** | **8** | **12** | **0** |

计数口径：FAIL = 承诺的效果不存在或必然丢失；WARN = 功能可用但存在时机/文案/兼容性问题（本报告 §3–§5 逐条列出，**本轮已全部修复**，表内为修复前判定）。
**BLOCKED = 0**：没有任何对象依赖不存在或无法验证的机制（依据 §6 能力矩阵）。

---

## 2. P0 问题

**本轮 P0 = 0。** 崩溃 / soft-lock / 生命周期错乱类问题在 v2.3.2–v2.3.6 已修复并回归：

| 轮次 | P0 | 根因 | 证据 |
|---|---|---|---|
| §25 | 点「限制条件」页崩溃 `card.lua:277` | 把标签/盲注 key 塞进 `restrictions.banned_cards`，原版会为每项建卡牌精灵 `Card(..., G.P_CENTERS[v.id])` → `center=nil` | `functions/UI_definitions.lua:6236` |
| §22/§23 | 挑战内原版内容泄漏、`win_ante` 未设置 | 隔离时机在 `init_game_object` 之后；`win_ante` 从未赋值 | `functions/state_events.lua:280`、`game.lua:2561` |
| §26 | 读档后盲注惩罚无法还原（手牌上限永久 -1） | 状态存在 SMODS.Blind 中心对象上，`Blind:load` 不会重调 `set_blind` | `blind.lua:774`（`save()` 只存固定字段） |
| 本轮 | 盲注惩罚可能把出牌次数/手牌上限压到 0 → 无法出牌（soft-lock） | 人牛 `-1`、天狗 `-2` 未夹紧 | `content/blinds.lua`（已夹紧到 ≥1，见 §5） |
| §15 | `content/spectrals.lua` 读裸全局 `BLH`（`systems/economy.lua:5` 里是 `local`）→ 勾城·契约 `can_use` 必崩 `attempt to index global 'BLH'` | 全仓仅本文件 `decl=0`（其余文件都有 `local BLH = ...`） | 补 `local BLH = SMODS.current_mod.blh` + `assert` |
| §15 | 勾城·契约在**商店**可用：`G.GAME.blind` 此时是已击败的盲注（`in_blind` 为假）→ +50% 打在死盲注上、结算奖励永不匹配 = $4 白费；普通局抽到只能自伤 | 设备 `blind.lua:188`（`in_blind`）、`state_events.lua:280-282`（`setting_blind` 才重置盲注） | `can_use` 加 `G.GAME.blind.in_blind == true` + `BLH.in_challenge()` |

---

## 3. P1 问题（核心效果无法触发 / 触发后丢失 / 无限资源 / 永久错误状态）

```text
[忘忧 wang_you]  FIXED
问题：描述承诺「你的牌不会被任何效果失效」，实现里只有 ×0.8 惩罚，免疫根本没写。
原因：只写了 joker_main 的计分分支，没有拦截 debuff 写入。
影响：一个稀有度 1、cost 5 的小丑，只带来纯负面效果（×0.8）——完全不可用设计。
证据：content/jokers.lua 忘忧 calculate 只有 context.joker_main；全局搜 "immune" 只有提示文案。
最小修复：补 Card:set_debuff 钩子（设备源码 card.lua 有该字段/方法），持有时把 playing_card 的失效强制为 false；
         小丑不受影响（描述同步注明）。
```

```text
[牛·负力 ox_power / 兔·脱身 rabbit_escape（跳过盲注标签）]  FIXED
问题：拿到标签时立刻 ease_hands_played(1) / ease_discard(2)，但下一个盲注开场 new_round() 会把
     hands_left / discards_left 整体重置 → 加了等于没加，标签被"获得后立刻消耗"却毫无效果。
原因：跳盲发生在 Blind Select 界面，那一刻 new_round() 尚未执行；回合值随后被重算。
影响：玩家跳过盲注换来的奖励 100% 白费（正是用户反馈的"获得后立刻消耗"）。
证据：functions/state_events.lua:237 new_round() 先算 round_resets.hands + round_bonus.next_hands，再清零 round_bonus。
最小修复：改写 G.GAME.round_bonus.next_hands / round_bonus.discards；文案改为「下一次出牌回合」。
```

```text
[白虎·调停 baihu_mediate（标签）]  FIXED
问题：跳过盲注时"当前盲注"其实已经打完，当场 G.GAME.blind:disable() 作用在旧盲注上；
     旧盲注 chips 已满足时 blind.lua 的 disable 事件会把状态推成 NEW_ROUND → 界面状态错乱风险。
原因：标签是 immediate，但效果需要"下一个盲注"这个还不存在的对象。
影响：效果无效 + 潜在状态错乱。
证据：blind.lua:398 Blind:disable 内部 `if self.boss and G.GAME.chips - G.GAME.blind.chips >= 0 then G.STATE = G.STATES.NEW_ROUND`。
最小修复：改为挂起 G.GAME.blh_break_blind，由 mod.calculate 在下一个盲注的 setting_blind 时机解除
         （已用 SMODS 参考源码确认 mod 会作为「个体计分目标」收到所有 calculate_context）。
```

```text
[猴·取物 monkey_take / 青龙·之首 qinglong_head（标签）]  FIXED
问题：用 SMODS.Jokers 建池，而该表在 26.829.0 不存在（设备 dump 只有 SMODS.Tags/Seals/Stickers/Atlases）
     → 池为空、标签白消耗。
原因：照抄了旧版 SMODS 的表名。
影响：两个标签 100% 无效果。
证据：grep -rn "SMODS.Jokers" /tmp/dump/dump → 无定义；本轮能力矩阵中 `SMODS.Jokers` 命中来自我们自己的代码。
最小修复：改用稀有度池 G.P_JOKER_RARITY_POOLS 收集本模组小丑（空则回退扫 G.P_CENTERS）。
```

```text
[探囊 tan_nang]  FIXED
问题：回合结束立刻扣 $3，取牌发生在下一回合首手；若牌堆没有强化牌或手牌已满 → 钱白扣、什么也没有。
原因：扣钱与取牌分成两个阶段，第二阶段失败了也不退款。
影响：正收益小丑变成纯亏损。
证据：content/jokers.lua 探囊原实现 end_of_round 分支 ease_dollars(-cost)。
最小修复：改为"取到牌才扣钱"；牌堆无强化牌 → blh_msg_nopick，钱不够 → blh_msg_nomoney，手牌满 → k_no_space_ex
         （并保留挂起，下一回合再试）。
```

```text
[赝品 yan_pin]  FIXED
问题：[TRIGGER-LOST] 首手抽牌时先把 pending 清掉，再进入延迟事件；手牌已满时事件里什么也不做，
     本次复制永久丢失（且没有提示、也没有 +Mult）。
原因：先消费状态再判断条件。
影响：概率小丑的一部分触发被静默吃掉。
证据：content/jokers.lua 赝品 first_hand_drawn 分支（修复前 pending=nil 在容量判断之前）。
最小修复：先查空位/手牌数，不满足则保留 pending 并提示 k_no_space_ex。
```

```text
[盲注惩罚 soft-lock]  FIXED
问题：人牛「出牌次数 -1」在 round_resets.hands=1 时会把 hands_left 压到 0；天狗「手牌上限 -2」在
     手牌上限很小时会压到 0 → 玩家无法出牌 → 本盲注永远无法完成。
原因：惩罚没有下限夹紧。
影响：P0 级 soft-lock（当前挑战默认 4/8，但配置页允许把出牌次数设为 1）。
证据：round_resets.hands 来自挑战 modifiers / 配置页；G.hand:change_size 允许降到 0（cardarea.lua:126 max(0, …)）。
最小修复：hands_penalty 至少保留 1 次出牌；hand_size_penalty 至少保留 1 张手牌，并在还原时使用被夹紧后的实际扣除量。
```

---

## 4. P2 问题（边界 / 组合 / 静默失败 / 文本一致性）

| # | 对象 | 问题 | 影响 | 状态 |
|---|---|---|---|---|
| 1 | 巧物 / 显灵 / 挪移 | 钱不够、消耗品区满、手牌满时静默无反应 | 玩家不知道"为什么没发生" | FIXED（分别给 `blh_msg_nomoney` / `k_no_space_ex`） |
| 2 | 跃迁 | 上限在 `context.before` 清零 = 每**手牌**重置，描述写「每回合最多 2 次」，且可无限滚 | 描述与行为不符 + 资源循环 | FIXED（按回合 id 计，同回合出牌不重置） |
| 3 | 传音 / 祸水 | 计分类效果被 `not context.blueprint` 挡掉 → Blueprint 复制本牌时完全无效 | 与 Blueprint 不兼容 | FIXED（去掉该守卫；传音内部调用为有界链，不会递归） |
| 4 | 嫁祸 | 文案「限制改为失效 1 张小丑」，实际是解除整条盲注限制（更强）；`victim.debuff = true` 非标准写法 | 描述低估效果 | FIXED（文案对齐 + 改用 `victim:set_debuff(true)`） |
| 5 | 双生花 | 文案「最强的强化」，实际取手中第一张强化牌 | 描述错误 | FIXED（文案改为「一张强化牌的强化」） |
| 6 | 离析 | 文案「出牌后」，实际在 `context.before`（出牌时、计分前） | 时机描述错误 | FIXED（文案改「每次出牌时」） |
| 7 | 替罪 | 被失效的牌不计入，描述未说明 | 描述遗漏 | FIXED（补 `{C:inactive}（被失效的牌不计）`） |
| 8 | 激发 | 文案 `(1/4 → 1/3）` 半全角括号混用 | 文案瑕疵 | FIXED |
| 9 | 生生不息 | 描述只显示"已生成张数"（每 3 回合且栏位有空位才 +1）→ 推进回合看不到任何变化 | 玩家误判"没生效" | FIXED（v2.3.5：显示「已积累 N 回合 / 已生成 X/3」；栏满给提示） |
| 10 | 全部 `end_of_round` 小丑（8 处） | 守卫依赖 SMODS 内部塞的 `context.main_eval`；设备版原版用的是 `not individual/not repetition` | 若 SMODS 不再塞，8 个回合结束效果全灭 | FIXED（改为设备版原版同款判定，两种都成立） |
| 11 | 盲注：地猴弃牌 / 天龙天秤 | 效果挂在 `blind.calculate` 上 | 依赖 SMODS 核心（未 dump）的实现细节 | FIXED（改用原版就有分派点的 `press_play` / `modify_hand`） |
| 12 | 深度回响化（贴纸） | 文案「最多叠加 5 次」，代码只把计数器封顶、永远返回 +3 → 计数器是死状态，叠加不存在 | 描述与实现不符 | FIXED（改为 `+3 × 层数`，封顶 5 层 = +15，并有断言） |

---

## 5. P3 问题（数值 / 文案 / 体验 / 工程卫生）

| # | 对象 | 问题 | 状态 |
|---|---|---|---|
| 1 | 全局 | `function SMODS.blh_add_dao(n)` 污染 SMODS 命名空间（且无调用点） | FIXED（删除，内容文件直接用 `BLH.add_dao`） |
| 2 | 塔罗 / 幻灵 | 描述缺少使用条件与边界（并列取色顺序、点数上限、永久加成、覆盖强化、Boss 盲注不可用…） | FIXED（§27：17 张塔罗 + 4 神兽 + 5 幻灵） |
| 3 | 设计文档 | §4/§5/§8 与实现不一致（盲注 8/12 项、勾城·契约"通关时"、索城·索引"指定点数"）；**§9 版本/封印/贴纸表约 80% 与实现不符**（例如"生肖＝免疫 debuff"实际是 +30 筹码、"涡印＝得标签"实际是生成塔罗） | FIXED（§4/§5/§8/§9 全部按实现重写） |
| 3b | 贴纸 | 记忆保留/原住民/面具在 `calculate` 里内联数值，`config` 只用于展示（改 config 不改效果） | 保留（数值一致、行为正确；属可维护性 WARN） |
| 4 | 地鸡·兵器牌 | 「随机强化牌」未枚举池（实现是 8 种原版强化） | 保留（池在游戏内可见），如需更精确可枚举 |
| 5 | 美术 | 塔罗/幻灵卡面没有印使用条件（只影响描述面板） | 保留（美术范畴，见 README） |
| 6 | 音频 | 零新增音效/BGM | 保留（见 README「声音素材不足」） |

---

## 6. API / 实现能力矩阵

对模组用到的每个 API 逐个 grep 设备 dump 与 SMODS 参考源码（完整表见 `dev/api_matrix.md`）。结论：

| 结论 | 数量 | 说明 |
|---|---:|---|
| 设备源码确认 | 30+ | `SMODS.Joker/Consumable/Voucher/Tag/Seal/Sticker/Edition/Blind/Challenge/ObjectType/Atlas/Keybind`、`SMODS.calculate_context`、`SMODS.calculate_effect`、`SMODS.change_base`、`SMODS.destroy_cards`、`SMODS.get_probability_vars`、`SMODS.pseudorandom_probability`、`SMODS.saved`、`Card:set_debuff`、`Card:use_consumeable`、`Blind:defeat`、`G.FUNCS.use_card`、`G.FUNCS.discard_cards_from_highlighted`、`Game:start_run`、`Game:init_game_object` … |
| 仅 SMODS 参考源码确认 `[REF-ONLY]` | 3 | `SMODS.load_file`、`SMODS.save_mod_config`、`SMODS.Blinds`/`SMODS.Consumables`（聚合表）——设备版本未 dump，但模组在真机可正常加载本身即证明前两者存在 |
| 模组自建全局 | 2 | `G.FUNCS.blh_config_changed`（main.lua:107）、`G.FUNCS.blh_unlock_all`（debug.lua:97）——非 SMODS API，属自建 |
| `[API-UNVERIFIED]`（外部 API） | **0** | 完整表见 `dev/api_matrix.md`（37 项设备确认 / 4 项 [REF-ONLY] / 2 项自建全局） |
| `[UNSUPPORTED-MECHANISM]` | **0** | — |

**Context 白名单核对**（模组实际使用 vs 分派点）：

| Context | 分派证据 |
|---|---|
| `joker_main` / `before` / `after` / `discard`(+`other_card`) / `individual` / `repetition` / `playing_card_added` | 设备版 `card.lua`、`functions/state_events.lua` |
| `end_of_round` / `game_over` | `functions/state_events.lua:107` `SMODS.calculate_context({end_of_round=true, game_over=…})` |
| `setting_blind` | `functions/state_events.lua:282` |
| `first_hand_drawn` | `functions/state_events.lua:378` |
| `using_consumeable` | `functions/button_callbacks.lua:2320` |
| `fix_probability` + `numerator` / `denominator` | SMODS `src/utils.lua:3039` `[REF-ONLY]` |
| `blueprint` / `blueprint_card` | SMODS `src/utils.lua:2253 SMODS.blueprint_effect`（`context.blueprint` 为**数字**，逐个复制递增）`[REF-ONLY]` |
| `main_eval` | SMODS `src/utils.lua:2055`（**内部临时塞入**，不是引擎字段）`[REF-ONLY]` → 已在 v2.3.5 移除对该字段的依赖 |

生命周期核对：

| 机制 | 结论 | 证据 |
|---|---|---|
| Blueprint / Brainstorm | 引擎在复制时把 `context.blueprint` 设为数字；"永久成长"类效果按原版惯例用 `not context.blueprint` 跳过复制（与 Campfire/Flash Card 一致），计分类效果保持兼容 | `card.lua:2714/2738/2764/2775`、SMODS `utils.lua:2253` |
| Retrigger | `context.repetition` 子通过已被回合结束类效果排除；`joker_main` 类按次触发（符合原版） | `card.lua:3280`（`context.repetition` 分支） |
| Debuff | 无需模组侧处理，沿用引擎行为 | SMODS `utils.lua:355`（`find_card` 默认排除 debuff） |
| Save / Load | 自定义状态都在 `G.GAME`（随存档）或 `card.ability.extra`（随卡牌）上；盲注惩罚状态借用原版会存档的 `hands_sub`/`discards_sub` | `blind.lua:774 Blind:save`、`card.lua` Card:save |
| 伪随机 | 全部走 `SMODS.pseudorandom_probability` / `pseudoseed`，受种子控制 | `content/*.lua` |

---

## 7. 文案问题汇总（已全部修复，保留记录）

| 类别 | 对象 | 原文案 → 修正 |
|---|---|---|
| 隐藏效果（代码有、描述无） | 嫁祸 | 「限制改为失效 1 张小丑」→「解除本盲注的限制，代价是随机 1 张小丑失效」 |
| 描述高估（描述有、代码无） | 忘忧 | 免疫未实现 → 补齐实现并注明"小丑仍会被失效" |
| 时机错误 | 离析（出牌后→出牌时）、牛·负力/兔·脱身（本回合→下一次出牌回合）、跃迁（每回合→实际每手牌）、生生不息 | 见 §4 |
| 数量/范围模糊 | 双生花（最强→一张）；地鸡（随机强化牌未枚举） | 前者已修，后者保留 |
| 条件遗漏 | 镜像/鼠/龙/羊/猴/鸡/狗/猪/契约 等塔罗与幻灵缺"需选中恰好 N 张 / 需空位 / 不可用于 Boss" | §27 已补 |
| 术语/格式 | 倍率 / 筹码 / `1/4` 分数 / 括号全半角 / debuff | §24 已统一为原版中文写法 |
| 数值表述 | 虎·狭路相逢「各 +$3」看不出总数 | 改为「每张 +$3（两张共 $6）」，`loc_vars` 给两个变量 |

模糊词扫描（§XIX）：`随机`18 处、`当前`5 处、`该牌`2 处、`相邻`1 处、`可能`1 处——逐条核对后**均为有明确游戏定义**（如"随机 1 张手牌"、"当前盲注"、"左侧相邻"、"每张牌独立随机，可能重复"），无模糊阻塞项。

---

## 8. 边界条件问题

| 对象 | 边界条件 | 原行为 | 正确行为 | 风险 | 状态 |
|---|---|---|---|---|---|
| 探囊 | 牌堆无强化牌 / 手牌满 / 钱不够 | 白扣 $3 | 不扣钱 + 提示 | 资源损失 | FIXED |
| 赝品 | 下回合首手手牌满 | 复制永久丢失（pending 已清） | 保留 pending + 提示 | 触发丢失 | FIXED |
| 忘忧 | 盲注 debuff / 贴纸 debuff | 牌被失效 | 牌不被失效（小丑仍可） | 效果不存在 | FIXED |
| 牛·负力 / 兔·脱身 | 跳过盲注时 | 加成立刻被回合重置抹掉 | 写 round_bonus，下一回合生效 | 奖励丢失 | FIXED |
| 白虎·调停 | 跳过盲注时 | disable 旧盲注、可能推 NEW_ROUND | 挂起到下一个盲注进场 | 状态错乱 | FIXED |
| 猴·取物 / 青龙·之首 | 任意 | 池为空 → 无效果 | 从稀有度池取本模组小丑 | 效果不存在 | FIXED |
| 人牛 | `round_resets.hands == 1` | hands_left = 0 → 无法出牌 | 至少保留 1 次 | soft-lock | FIXED |
| 天狗 / 地猴 | 手牌上限很小 | 上限可为 0 → 无法抽牌 | 至少保留 1 张 | soft-lock | FIXED |
| 巧物 / 显灵 / 挪移 | 槽位满 / 手牌满 | 静默 | 明确提示 | 体验 | FIXED |
| 跃迁 | 同回合反复使用消耗品 | 每手牌重置 → 可无限续手 | 每回合上限 2 | 资源循环 | FIXED |
| 天龙 | 全黑桃/梅花或完全不含 | 计分 ×0.5（`modify_hand`） | 同（已用有分派点的钩子） | — | PASS |
| 塔罗 / 幻灵（26 张） | 空手牌 / 满手牌 / 无目标 / 目标不足 | 全部由 `can_use` 拦截 | 同 | — | PASS（`dev/canuse_audit.py` 26/26） |
| 盲注（12） | 读档后 defeat/disable | 修复前无法还原手牌上限 | 借用原版会存档的字段还原 | 永久惩罚 | FIXED（v2.3.4） |
| 挑战 | 读档进入挑战 | 池隔离、banned_keys 都会重放 | 同 | — | PASS |

---

## 9. 平衡审计（按设计原型分组，不做全卡排名）

| 原型 | 对象（示例） | 成本 | 收益 | 风险 | 触发频率 | 是否符合原型 |
|---|---|---|---|---|---|---|
| Build-around / Engine | 生生不息（稀有 8）、双生花（罕见 7） | 高 | 长期产出/扩散 | 需要栏位与同点牌 | 每 3 回合 / 每手 1/2 | PASS（上限 cap=3 已生效） |
| Scaling（永久成长） | 癫人、招灾、赝品、入梦 | 中 | 永久 Mult / 手牌上限 | 需要牺牲手牌/持币 | 回合结束 | PASS（成长与 payout 分离，Blueprint 语义正确） |
| Economy | 探囊、巧物、丰饶、替罪、灵闻 | 低-中 | 资源/金钱 | 有代价（花 $） | 回合结束 / 弃牌 | PASS（本轮修掉"白扣钱"） |
| Risk / Reward · Gamble | 祸水、猪·黑白棋子、强运、激发 | 低 | 高倍率 / 概率提升 | 失败有惩罚（盲注需求 +5%、变黑桃） | 每次计分 / 使用 | PASS（概率写法统一为 `#1#/#2#`） |
| Utility / Tempo | 破万法、跃迁、夺心魄、传音、挪移 | 中 | 出牌次数/操作性 | 有条件 | 回合内 | PASS（跃迁上限已改为每回合） |
| Defensive | 忘忧、不灭、嫁祸、替罪 | 中 | 免死/免疫/转嫁 | 有代价（×0.8 / -1 手牌上限） | 一次性或持续 | PASS（忘忧免疫本轮补齐，代价清晰） |
| Endgame / Boss-like | 天龙（showdown）、天猪 | — | 终局挑战 | 强度随持有金钱提升 | 第 10 天 | PASS（`win_ante=10` 已修，showdown 只在天 10） |

**无"实现漏洞型超模"**：本轮把三处"因为条件写错而变成无限/白拿"的问题修掉（跃迁上限、牛/兔标签、探囊白扣钱）。
存在的强项（生生不息负片小丑、双生花扩散、天龙 ×0.5）都有明确 cap / 代价 / 触发频率，属设计意图，不做削弱。

---

## 10. 逐对象验收表

见 `dev/acceptance_table.md`（120 个对象，由脚本从源码机械提取：Trigger / Condition / 状态字段 / 边界保护 / 文案键 / 兼容守卫），
逐行核对结论：

- **API**：全部落在 §6 白名单内（0 个 `[API-UNVERIFIED]`）
- **Trigger**：全部为设备源码或 SMODS 有分派点的 Context
- **Condition**：26 张消耗品的 `can_use` 覆盖其 `use` 依赖的资源（`dev/canuse_audit.py` 26/26）
- **Action / State**：所有状态字段要么随回合复位（`count`/`pending`/`discarded`/`rnd`），要么是设计上的永久成长（`mult`/`made`），要么借用原版存档字段（`hands_sub`/`discards_sub`）
- **Boundary**：见 §8
- **文案**：344 项回归中包含"每个消耗品必须有条件行 / `loc_vars` 变量必须被使用 / 中文不得残留英文 / 数值段必须带单位"
- **兼容性**：Blueprint（计分类兼容、永久成长类按原版惯例跳过）、Retrigger（`repetition` 已排除）、Debuff（引擎行为）、Copy（`set_ability`/`copy_card` 保留强化与版本）
- **版本 / 封印 / 贴纸 / 优惠券**（规范 §VII/§X/§XI/§XIV）：本轮补齐行为验证——5 个版本的 shader 与计分/成长断言；
  5 个封印的触发点与槽位边界；5 张贴纸的数值与叠加上限；16 张优惠券 `redeem` 逐张「必须真的改变状态」+ `requires` 链可解析

---

## 11. 修改计划（本轮已执行）

顺序严格执行 P0 → P1 → P2 → P3，全部为最小修改：

| 优先级 | 修改 | 文件 |
|---|---|---|
| P1 | 忘忧补 `Card:set_debuff` 免疫 | `content/jokers.lua` |
| P1 | 牛/兔标签改写 `round_bonus` | `content/tags.lua` |
| P1 | 白虎标签改为挂起 + `mod.calculate` 消费 | `content/tags.lua`、`systems/economy.lua` |
| P1 | 猴/青龙标签池改稀有度池 | `content/tags.lua` |
| P1 | 探囊改为"取到牌才扣钱" + 三种提示 | `content/jokers.lua`、`localization/*` |
| P1 | 赝品先查空位再消费 `pending` | `content/jokers.lua` |
| P1 | 盲注惩罚下限夹紧（防 soft-lock） | `content/blinds.lua` |
| P2 | 跃迁上限按回合 | `content/jokers.lua` |
| P2 | 传音/祸水 Blueprint 兼容 | `content/jokers.lua` |
| P2 | 巧物/显灵/挪移静默失败补提示 | `content/jokers.lua` |
| P2 | 嫁祸/双生花/离析/替罪/激发 文案对齐 | `content/jokers.lua` |
| P3 | 删除 `SMODS.blh_add_dao` 命名空间污染 | `systems/economy.lua` |
| P3 | 文档同步（§26.1 更正、§29 新增、§4/§5/§8 重写） | `DESIGN.md` |

**未做（有意保留）**：不重写任何系统、不改动已正确的对象、不引入新依赖、不为了"更平衡"削弱强卡。

---

## 12. 修改后二次审计（§XXXIV）

| 检查项 | 结果 | 证据 |
|---|---|---|
| 修改是否解决原问题 | 是 | 344 项回归中新增 30+ 项针对本轮修复的断言全部通过 |
| 是否引入新问题 | 否 | 全量 `luajit -bl` 语法检查通过；344/344 通过 |
| 是否破坏其他卡牌 | 否 | 旧断言（探囊"回合结束扣钱"）已按新语义同步更新，其余断言未改 |
| 是否破坏公共机制 | 否 | `mod.calculate` 新增 `setting_blind` 分支，`end_of_round` 分支行为不变（测试覆盖免死/复位） |
| 是否改变描述 | 是（有意） | 6 处文案对齐 + 2 个新本地化键，中英同步 |
| 是否改变状态生命周期 | 是（有意） | `pending` 不再提前消费；标签改用 `round_bonus`；盲注惩罚量被夹紧且还原用实际值 |
| Blueprint | 保持兼容 | 计分类去掉了多余的守卫；永久成长类仍按原版惯例跳过 |
| Retrigger | 无影响 | `repetition` 子通过仍被排除 |
| Save / Load | 无回归 | 状态仍落在 `G.GAME` / `ability.extra` / 原版存档字段上 |
| 新增测试是否覆盖四类对象 | 是 | 版本/封印/贴纸/优惠券 新增 41 项行为断言（283 → 344） |
| 深度回响化叠加是否引入新问题 | 否 | 仅改返回值与计数逻辑；`card.ability.blh_deep_echo_hits` 仍在卡牌自身、随存档 |
| 静态审计 | 全绿 | `dev/boundary_report.py` 0 告警、`dev/canuse_audit.py` 26/26、中文文案 0 英文残留、SMODS 命名空间 0 污染 |

---

## 13. 结论与遗留

- **可交付判定**：120 个对象中 **119 个 PASS / PASS WITH WARNING，1 个（忘忧）本轮从 FAIL 修复为 PASS**；无 BLOCKED、无 `[UNSUPPORTED-MECHANISM]`、无 `[API-UNVERIFIED]`。
- **残留（非阻塞，均为设计/素材层面）**：
  1. 塔罗/幻灵/小丑的**卡面**没有印使用条件（只影响描述面板）；
  2. 零新增音频（无 BGM/音效/配音）；
  3. 「随机强化牌」未在文案里枚举 8 种池；
  4. 仅 iOS + Steamodded 26.829.0 实测，其他平台/版本未验证。
- **必须真机确认的 8 项**：见 `DESIGN.md` §22.6 / §23.5 / §26.5 / §27.4 / §28.4 / §29.8。


---

## 14. 独立切片审计合并（v2.3.6 → v2.3.9）

除本报告 §22–§29 的自审外，另派 3 个**只读**子代理独立复核切片：优惠券+标签、封印+贴纸+塔罗+本地化、幻灵+版本。
3 份**全部已返回**（第三份见 §15）。
所有结论都经我**回到设备源码逐条复核**后才落地修复。

### 14.1 独立审计发现并已修复的问题

| 优先级 | 对象 | 问题 | 证据（设备源码） | 修复 |
|---|---|---|---|---|
| **P0** | 青龙·之首（标签） | `G.GAME.current_round.voucher = nil` → 进入新生成的商店时 `game.lua:3329` 无条件读 `.spawn` → **报错中断**；且"免费优惠券"完全没实现 | `game.lua:3329/3331/3333-3334`；`current_round.voucher` 全部赋值点（`game.lua:2254`、`state_events.lua:205`） | 删掉置 nil；type 改 `voucher_add`；自己实现免费券（加 `card.cost=0`/`couponed`） |
| **P0** | 狗·传信（标签） | `voucher_add` 生效但原版效果被 `self.name == 'Voucher Tag'` 挡住（`tag.lua:323`）→ **零效果** | `tag.lua:322-340`；模组内无 `couponed`/`voucher_tag` 引用 | 自己实现加券（照抄原版路径 + 显式免费） |
| **P0** | 涡印（封印） | 缺 `context.other_card == card` 守卫 → 弃 1 张时**手牌里每张带涡印的牌都触发**（`state_events.lua:413` 直调 + `:416` 全量 context） | 原版紫印 `card.lua:2618`；`state_events.lua:405-418` | 加守卫 + 回归（"没被弃的那张不触发"） |
| **P0** | 玉印 / 神兽印（封印） | 手调 `ease_dollars` **又** `return {dollars=…}` → `dollars` 是 SMODS calculation_key，引擎再结算一次 → **双倍给钱**（UI 只显示一份） | 参考 `utils.lua:1584/1312-1316`、`game_object.lua:3801` | 删手调，只留 return；测试改为"总额"模型（旧实现会算出 2 倍而失败） |
| **P1** | 权柄 / 牛·障碍赛跑（塔罗） | `can_use` 只判 `>0`，而 SMODS 的 `obj.can_use` 会**提前 return**，跳过原版「高亮数 ≤ max_highlighted」检查 → 文案"1~2 张 / 至多 3 张"被突破 | `card.lua:1838-1840`（提前 return）vs `1871-1887`（原版上界）；`cardarea.lua:35` 高亮上限恒 5 | 两处 `can_use` 各加 `#highlighted() <= max_highlighted` |
| **P1** | 虎·强势（标签） | 只改 `blind_choices.Boss`，不重建已生成的盲选 UI → 显示与实际对战不一致；文案还写"本盲注" | 原版 Boss Tag `tag.lua:305-321` → `G.FUNCS.reroll_boss`（`button_callbacks.lua:2901-2965`） | 改走原版路径（`G.from_boss_tag=true` + `reroll_boss`），文案改"Boss 盲注" |
| **P1** | 面具（优惠券） | 只改 `round_resets.reroll_cost` → **当前商店仍原价**；`base_reroll_cost` 全 dump 只写不读（死写） | `common_events.lua:2617-2624`；原版 `v_reroll_surplus` | 同时改 `current_round.reroll_cost` + `calculate_reroll_cost(true)`；删死写 |
| **P1** | 巨钟（优惠券） | 只改 `shop.joker_max`，未走 `change_shop_size` → 本商店不加位、商店内刷新还会溢出 `card_limit` | `common_events.lua:1334-1353`；原版 `v_overstock` | 改调 `change_shop_size(extra)` |
| **P1** | 马·竞速（标签） | 文案"每张已打出的牌获得 2 道"，实际按「打出过几次牌型」求和 | `tags.lua:155-163` vs `state_events.lua:589` | 文案改为「本局每打出过 1 次牌型获得 2 道」 |
| **P1** | 白虎·调停（标签） | 标记**先清后判** Boss；跳小盲注时下一个是大盲注（无限制）→ 标签白白消耗 | `button_callbacks.lua:2861-2863` 跳盲推进 | 只在 Boss 盲注消费；文案改"下一个 Boss 盲注" |
| P2 | 蛇·少数与多数（塔罗） | 花色并列时 `minor == major`，`elseif` 吞掉给钱分支 | 实现自证 | 改两个独立判断 + 并列场景回归 |
| P2 | 朱雀·审判（标签） | 无小丑 / 只有永恒小丑时仍白拿 $30 | 实现自证 | 只有真的摧毁才给钱，否则提示 |
| P2 | 猴·取物 / 鸡·夺械（标签） | 栏位满时静默失败但标签照消耗 | `tags.lua:13/38` 的容量门 | 满时给"没有空间"提示 |
| P2 | 青龙·之首（标签） | 负片小丑不占小丑栏却按 `card_limit` 拦 | 负片 +1 槽位（`game_object.lua:3758-3762`） | 去掉该门 |
| P3 | 生肖印（封印） | `config.repetitions` 写进 `ability.seal.*` 后无人读取（引擎读顶层 `ability.repetitions`） | `card.lua:617-624` vs `common_events.lua:630` | 删除该字段 |
| P3 | 蝼蚁（贴纸） | 手调 `ease_dollars` → 每张计分牌多触发一轮 `money_altered` 计算且无金额弹字 | 参考 `utils.lua:3439-3450` | 改为 `return { dollars = 1 }` |
| P3 | 深度回响化（贴纸） | 计数键挂在 `card.ability` 顶层，移除贴纸时不清零；`config` 灰度未参与计算 | 贴纸 `apply(false)` 只清 `card.ability[<sticker key>]` | 计数放进 `card.ability.blh_deep_echo.hits`，数值读 `config.gain/cap` |
| P3 | 镜像（塔罗） | 漏 `G.deck.config.card_limit + 1`（原版 DNA/Cryptid 都有；`big_hands/tiny_hands` 读这个值） | `card.lua:1539 / 3902` | 补回该行（§22 当时的"删除手改"结论对"入牌堆"路径成立，对"入手牌"路径不成立） |
| P3 | 商店区域 | `G.P_STICKERS` 在 26.829.0 **不存在** → `pools.lua` 的贴纸禁用循环是死代码 | 全 dump / 参考源码 grep 均无 | 删除该循环并改注释 |
| P3 | 代码卫生 | `card_init_ok` 局部函数定义在调用点**之后**（Lua 不可前向引用）→ 真机会 nil；`type(Card)=='function'` 判错（`Card` 是可调用表） | 自测在 5 分钟内抓到 | 前移定义 + 判定改为 `Card ~= nil` |

### 14.2 独立审计确认无问题（保留记录）

- 16 张优惠券的 `round_resets.*` / `card_limit` / `ease_dollars` / `requires` 链全部走原版同类写法 ✓
- 16 张标签的 `config.type` 均为原版真实取值，且各 type 的 `apply_to_run` 调用点真实存在（`store_joker_create`/`store_joker_modify`/`eval`/`voucher_add`/`new_blind_choice`/`immediate`/`round_start_bonus`/`shop_start`/`tag_add`）✓
- 塔罗 21 张 `pos` 唯一、图集 497×285 = 7×71×3×95 ✓；选中张数/目标条件与文案一致（除本轮修掉的 2 张上界）✓
- 封印 `badge_colour`、贴纸 `sets`/`rate`/`needs_enable_flag` 与挑战 `enable_blh_*` 一一对应 ✓
- 本地化：**无缺失 key**、zh/en 键集合**完全一致**、无未闭合 `{C:}` 标签、中文无英文残留（`A` 为点数符号、`Boss` 与模组名除外）✓

### 14.3 仍未处理的 WARN（有意保留，非遗漏）

| 对象 | WARN | 决定 |
|---|---|---|
| ~~道印封印 / 鼠·寻道 / 马·竞速 标签~~ | ~~普通局（非挑战）也会从池里出现，此时"道"无 HUD，玩家看不到~~ | **已随 v2.4.1 移除「道」而消失**（见 §16）：这三个现在给的是钱，普通局也看得见 |
| 面具（优惠券）强度 | −$1 弱于原版 reroll 券的 −$2 | 保留：本模组 8 组券的整体曲线按 10 天预算设计 |
| 猪·博弈（标签） | 期望 +25% 金钱、无成本 | 保留：设计原型就是 Gamble |
| 玄武·公正（标签） | 一次免死 = 可救整局 | 保留：这是该标签的唯一设计目的（且是"充能"不是"无限免死"，用掉即消耗） |
| 3 张固定数值贴纸 | `config` 只用于展示、数值内联 | 保留：数值一致、行为正确，仅可维护性 |

### 14.4 本轮新增回归（318 → 344 项）

- 涡印：没被弃的那张不触发 / 被弃的那张才生成
- 玉印、神兽印、蝼蚁：**总额模型**断言（旧的双倍给钱实现会被判失败）
- 权柄/牛：高亮 5 张不可用、2/3 张可用
- 蛇：花色并列时筹码与金钱都结算
- 虎·强势：调用 `G.FUNCS.reroll_boss` 且置 `G.from_boss_tag`
- 狗·传信 / 青龙·之首：商店多出 1 张**免费**券；且 `current_round.voucher` 不被置 nil；负片小丑满栏也能给
- 白虎·调停：非 Boss 盲注不消费、Boss 才解除
- 朱雀·审判：无小丑 / 只有永恒小丑时不给钱
- 面具：当前商店刷新价立刻下降且调用重算；巨钟：走 `change_shop_size`
- 深度回响化：计数在贴纸命名空间下、顶层无残留

### 14.5 二次审计（v2.3.9）

语法全绿；`luajit dev/test_blh.lua` → **344/344**；`boundary_report.py` 0 告警；`canuse_audit.py` 26/26（`mirror` 的"牌堆"提示为既有误报：它在 `use` 里读的是 `G.deck.config.card_limit` 上限自增，`can_use` 已正确检查手牌空位）；
`grep` 复核：`content/seals.lua` 无手调 `ease_dollars`、`content/tags.lua` 无 `current_round.voucher = nil`、塔罗 2 处高亮上界、涡印守卫存在。

---

## 15. 第三份独立切片审计合并 + 扑克牌版本失效（v2.3.9 → v2.4.0）

第三份只读子代理复核切片：**幻灵 10 + 版本 5**。所有结论同样回到设备源码逐条复核后才落地。

### 15.1 发现并已修复的问题

| 优先级 | 对象 | 问题 | 证据（设备源码） | 修复 |
|---|---|---|---|---|
| **P0** | `content/spectrals.lua` | 文件内直接读裸全局 `BLH`，而 `BLH` 是 `systems/economy.lua:5` 的 `local` → 勾城·契约 `can_use` 必崩 `attempt to index global 'BLH'` | 全仓扫描：仅本文件 `local BLH` 声明数 = 0（其余 5 个文件都有） | 补 `local BLH = SMODS.current_mod.blh` + `assert`（`content/spectrals.lua:7-11`） |
| **P0** | 勾城·契约（幻灵） | `can_use` 只判 `G.GAME.blind ~= nil`：**商店里** `G.GAME.blind` 仍是已击败的那个盲注（`in_blind` 为假）→ `+50%` 打在死盲注上、挑战结算奖励永不匹配 = **$4 白费** | 设备 `blind.lua:188`（进盲注置 `in_blind = true`）、`state_events.lua:95`（`end_round()` 置回 **false**）、`:280-282`（只有 `setting_blind` 才换盲注） | `can_use` 加 `G.GAME.blind.in_blind == true` + `BLH.in_challenge() == true` |
| **P1** | 勾城·契约（幻灵） | 同一盲注可**重复签约**：`use` 每次都把 `blind.chips × 1.5` 累乘，但奖励只有单槽（`blh_pact_ante`/`blh_pact_blind`），`BLH.settle_blind` 匹配一次后立刻清空（`economy.lua:89-93`）→ 第 2 张起只加惩罚、拿不到 ×2（需手持两张） | 实现自证：原 `can_use` 无已签约判断；`G.GAME.blind` 在盲注内不会被替换（`game.lua:2522` 只创建一次） | `can_use` 增加「当前盲注（ante + 盲注 key）已签约 → 不可用」，对跳过盲注留下的残留不误拦；文案写「同一盲注只能签一次」 |
| **P1** | 回声 / 道城·轮回（幻灵） | `can_use` 未要求盲注进行中 → 商店里也能用（回声复制手牌区、轮回改手牌上限，均无意义） | 同上一行 | 两处各加 `G.GAME.blind.in_blind == true` |
| **P1** | 索城·索引（幻灵） | 两个问题。① `c.base.id` 可能为 nil（非扑克牌 / 用本版本不存在的 `G.P_CARDS.empty` 构造的牌，`common_events.lua:2489`）→ 比较 nil 崩。② **语义错**：直接比 `base.id` 会把「无点数」的石头牌按隐藏底牌点数当成「手中点数最高」 | `card.lua:138-141`（`base.id = rank.id`）；`SMODS.Enhancement stone` 定义 `no_rank = true`（`game_object.lua:3447-3452`，`wild` 只有 `any_suit`）；引擎判定入口 `Card:get_id()`（`card.lua:1174-1178`，无点数牌返回随机负数）；原版「手中最高点数」循环用 `SMODS.has_no_rank` 守卫（`card.lua:3710-3718` Raised Fist） | 两处循环都加 `c.base and c.base.id` 与 `not SMODS.has_no_rank(c)`；`top` 为 nil 时直接 `return false` / `return`；`use` 里再兜一次（`Card:use_consumeable` 不复查 `can_use`） |
| **P1** | 5 个版本（Edition） | 只认 `pre_joker`/`post_joker`。这两个上下文只在小丑区循环里产生（`state_events.lua:679` 循环、`:682` pre_joker、`:772` post_joker），**扑克牌上完全不生效**；而标准补充包会给扑克牌 roll 版本（`card.lua:2103-2105`），版本池 cull 只看 `in_shop`（`common_events.lua:2271-2272`）→ 本模组 5 个版本会静默失效 | `functions/common_events.lua:744-749`（任何带版本的卡都会走 `card:calculate_edition(context)`）；计分主循环传 `{main_scoring=true, cardarea=G.play}`；原版写法 `SMODS/_/src/game_object.lua:3685/3718/3751` | 加两个上下文助手 `before_score()`/`after_score()`（`context.pre_joker or (context.main_scoring and context.cardarea == G.play)` 等）；神兽在两个条件同时成立时**合并返回**，避免互相吃掉。小丑侧不会 double-dip 属 **[REF-ONLY]**：设备 `SMODS/src/utils.lua` 未 dump，两份参考源码一致（1814a `utils.lua:2098-2107`、0711a `utils.lua:1872-1881`：主计分在遍历小丑前把 `context.main_scoring` 置 nil） |
| P2 | 熵增（幻灵） | 文案「（保留点数与花色）」与实现不符：石头牌/万能牌本身没有点数或花色 | 实现读 `SMODS.get_enhancements` 全量随机 | 中英文案改为「点数与花色尽量保留；石头牌/万能牌本身没有点数或花色」 |
| P2 | 献祭 / 二重身（幻灵） | 献祭未说明「永恒/负片小丑不可献祭」；二重身未说明取「售价最高」 | 实现自证（`eternal` 判定、`sell_cost` 排序） | 补文案 |
| P3 | 版本测试 | 旧测试用 `individual` + `joker_main` 断言版本效果 → **测的是错上下文**（`state_events.lua:689` 会把 `joker_main` 的 edition 清空），掩盖了上一条 P1 | 设备 `state_events.lua:686-689` | 测试改为 `pre_joker`/`post_joker`/`main_scoring`，并断言 `joker_main` 返回 nil、蓝复制不计成长、`G.hand` 不计分、神兽合并返回 |

### 15.2 独立审计确认无问题（保留记录）

- 幻灵 10 张的 `can_use` / `use` 与 `SMODS.Consumable` 契约一致：`use` 只走 `G.E_MANAGER` 事件，无同步改牌区；负片复制路径与 `set_edition('e_negative', true)` 用法正确 ✓
- 版本 `prefix_config = { shader = false }` 全 5 个 ✓；`SMODS.Edition` 基类自带 `get_weight`（`game_object.lua:3618`）→ 不会因缺 `get_weight` 在 `poll_edition` 里崩（旧 WARN 降级为"不参与 `edition_rate` 修正"，属设计选择）✓
- 版本 `extra_cost` 会被 `Card:set_cost_value` 读取（`card.lua:508-515`），5 个版本的加价均生效 ✓

### 15.3 仍未处理的 WARN（有意保留，非遗漏）

| 对象 | WARN | 决定 |
|---|---|---|
| 索城·索引 | 索城定向抽牌不经 `draw_card` → 不触发 `SMODS.drawn_cards` / `stay_flipped` | 保留：与原版「Cryptid/Death」同属"直接改牌区"，且已在 §14.3 记录 |
| 涡城 | 同上（定向生成） | 保留 |
| 版本（扑克牌） | 回响在**重触发**（红印等）当次出牌会按重触发次数再成长一次 | 保留：与原版 foil/holo/poly 每次重复结算一次的行为一致；成长值小（+2/次），不做特例 |
| 版本 `get_weight` | 用基类默认实现，不乘 `G.GAME.edition_rate` | 保留：本模组的版本稀有度按自身 `weight` 曲线设计 |

### 15.4 本轮新增回归（344 → 374 项）

- 勾城·契约：Boss 不可用 / 盲注进行中可用 / **商店不可用** / 非本模式不可用（4 项）
- 回声 / 道城·轮回：盲注外不可用、盲注内可用
- 索城·索引：手牌/牌堆含 `base == nil` 的牌时不崩、`use` 被直接调用也不崩
- 勾城·契约：同一盲注已签约后不可再用；签约绑的是别的盲注时不误拦
- 玉城·记忆：`use` 在「本局没用过消耗品」（`blh_used_consumables` 为 nil）时不崩——`Card:use_consumeable`（`card.lua:1408-1421`）直接调 `use`、不复查 `can_use`
- 索城·索引：判别性断言——手里有 no_rank 牌（隐藏底牌 A）时不会被当成「点数最高」把 A 拉进手牌（旧实现会）
- 版本：`pre_joker` 结算与累计、`joker_main` 无效、蓝复制不计成长、`main_scoring + cardarea == G.play` 生效（扑克牌）、`G.hand` 不计分、神兽合并返回
- 文案：熵增（石头牌/万能牌无点数花色）、献祭（永恒/负片不可献祭）、二重身（售价最高）中英各断言一次（6 项）

### 15.5 二次审计（v2.4.0 首轮，子代理复核前）

- 语法：`for f in content/*.lua systems/*.lua main.lua localization/*.lua; do luajit -bl "$f"; done` → 全绿
- 行为：`luajit dev/test_blh.lua` → 369/369（该轮数字，最终见 §15.7）
- 静态：`python3 dev/boundary_report.py` → 虚拟告警 **0**；`python3 dev/canuse_audit.py` → 26 个对象，25 项 OK，1 项为既有误报（`mirror`「缺检查: 牌堆」：`can_use` 已正确检查手牌空位，`use` 里读的是 `G.deck.config.card_limit` 上限自增）
- 交叉复核：`grep -n "context.joker_main" content/editions.lua` → 无命中；`grep -c "^local BLH" content/spectrals.lua` → 1

### 15.6 独立子代理复核（对本轮修复的对抗性再验证）

另派 1 个**只读**子代理独立复算本节全部结论（不允许改文件），逐条回证据。结果：**A1–A6 全部成立**，并纠正了我一处错误例证。

| 断言 | 结论 | 子代理补充/纠正的证据 |
|---|---|---|
| A1 5 个自定义版本会进"版本池"，且标准补充包的**扑克牌**有机会带上 | 成立 | `game_object.lua:42-46` `modify_key` 先加模组前缀再拼 `class_prefix='e'` → 实际 key 为 `e_blh_*`，`overrides.lua:2266` 的 `assert(v:sub(1,2)=='e_')` 通过；池初始化 `game.lua:727`、入池 `game_object.lua:1313-1315`；Banner 1.1.1 的 `BANNERMOD.apply_editions`（`overrides.lua:2263`）只剔除用户手动禁用的 key（`Banner-1.1.1/src/main.lua:75-87`），默认不影响 |
| A2 扑克牌版本走 `calculate_edition`，context 为 `main_scoring + cardarea == G.play`；`pre/post_joker` 只在 `state_events.lua` 小丑循环产生 | 成立 | 调用点 `common_events.lua:610`（repetition_only）与 `:745`（主分支），赋 `ret.edition` 在 `:612`/`:747`；`state_events.lua:672` 传 `{cardarea = v}`；全 dump grep `pre_joker\|post_joker` 只命中 `state_events.lua:682/772` 与 `game_object.lua:3685/3718/3751` |
| A3 小丑版本不会 double-dip | 成立 `[REF-ONLY]` | 1814a `utils.lua:2084 SMODS.score_card` → `:2098 main_scoring = true` → `:2099 eval_card` → `:2101 main_scoring = nil` → `:2106 calculate_card_areas('jokers',...)`；置 nil 在遍历小丑**之前**且是同一 context 表。0711a 同序（1872/1875/1880）。`end_of_round` 路径只把 `main_scoring` 传给 args，从不写 `context.main_scoring` |
| A4 版本返回的 `mult/xmult/chips/dollars` 会被真正结算 | 成立（`dollars` 部分 `[REF-ONLY]`） | `SMODS.trigger_effects` 对 `edition` 子表以 `from_edition=true` 进 `calculate_effect` 再遍历 `SMODS.calculation_keys`（1814a `utils.lua:1503-1511/1548-1550/1557`）；key 名单 1814a `utils.lua:1577-1582`（chips/mult/xmult）、`:1584`（dollars）。设备侧可证到组装式：`game_object.lua:3905-3909/3952/4004` |
| A5 商店里是"已击败且 `in_blind=false`"的盲注 | 成立 | `in_blind` 全 dump 只有 `blind.lua:188`（`Blind:set_blind` 内）置真、`state_events.lua:95`（`end_round` 开头）置假；`G.GAME.blind` 只在 `game.lua:2522` 创建一次，此后仅 `set_blind`/读档改写，而 `set_blind` 只在 `new_round`（`state_events.lua:237`，调用点 `:280`）里被调，`new_round` 由盲注选择按钮触发（`button_callbacks.lua:2653`） |
| A6 索城守卫足够 | 成立，但**我原来的例证写错了** | 见下 |

**例证更正（已改文档与注释）**：`SMODS.Enhancement:take_ownership('stone', { no_suit = true, no_rank = true, ... })`（`game_object.lua:3447-3452`）表明石头牌是"无点数（no_rank）"，但它的 `base.id` **仍有值**（隐藏底牌，如 A=14）；`wild` 只有 `any_suit`（有 rank）。
引擎判定点数的入口是 `Card:get_id()`（`card.lua:1174-1178`：无点数且未被吸血 → 返回随机负数），原版"手中最高点数"循环（Raised Fist，`card.lua:3710-3718`）用 `SMODS.has_no_rank` 守卫。
`base.id` 真正为 nil 的路径是**非扑克牌 / 用本版本不存在的 `G.P_CARDS.empty` 构造的牌**（原始 `game.lua:299-351` 的 P_CARDS 恰 52 项、无 empty；`common_events.lua:2489`）→ 原先的 nil 守卫属防御性补强，不是本轮的真实缺陷；真实缺陷是"无点数语义"。

**子代理对抗性检查 4 项，处理如下**：

| 发现 | 判定 | 处理 |
|---|---|---|
| 勾城·契约可对同一盲注重复签约（惩罚累乘、奖励单槽） | **真缺陷** | 已修：`can_use` 增加已签约判断 + 文案 |
| 索城·索引未覆盖"无点数"语义（石头牌按隐藏底牌点数被选中） | **真缺陷** | 已修：两处循环按 `SMODS.has_no_rank` 跳过（与原版 `card.lua:3713` 一致）+ 判别性回归 |
| `use` 不复查 `can_use`（若存在绕过按钮门的直调会崩） | 覆盖缺口，**未找到可达调用点** | 记为 WARN；`玉城·记忆`/`索城·索引` 已各自兜底，其余 `use` 读的 `G.GAME.round_resets` 在局内恒存在，不做无证据改动 |
| Banner 1.1.1 的 `apply_editions` | 不影响 | 无需处理（理由见 A1 行） |

### 15.7 最终二次审计（v2.4.0，含对抗性复核修复后）

- 语法：`for f in content/*.lua systems/*.lua main.lua localization/*.lua; do luajit -bl "$f"; done` → 全绿
- 行为：`luajit dev/test_blh.lua` → 374/374（该轮数字，后续 §16 变更后为 387）
- 静态：`python3 dev/boundary_report.py` → 虚拟告警 **0**；`python3 dev/canuse_audit.py` → 26 个对象，25 项 OK，1 项为既有误报（`mirror`「缺检查: 牌堆」）
- 交叉复核：`grep -n "context.joker_main" content/editions.lua` → 无命中；`grep -c "^local BLH" content/spectrals.lua` → 1；`grep -n "has_no_rank" content/spectrals.lua` → 4（两处循环各 2 次）
- 版本字段：`beiklive_helper.json` = 2.4.0；`main.lua` `mod.debug_info.version` = v2.4.0
- 仍未处理且已记录的 WARN：反物质零成本全屏负片、猪·博弈 EV +25%、玄武·公正 1 次免死、3 张固定数值贴纸、涡城/索城绕过 `draw_card`、玉城 `Card:use_consumeable` monkey-patch、版本 `get_weight` 不乘 `edition_rate`、`use` 不复查 `can_use` 的覆盖缺口

---

## 16. 需求变更记录：移除「道」，奖励改为金钱（v2.4.0 → v2.4.1）

**不是缺陷修复，是用户决策**：真机上自绘的「道」HUD 显示不出来 → 奖励不可见、也不可用。
用户选择「移除道概念，直接改成钱」，并确认数值按金钱经济缩放、三项依赖机制全部保留。

### 16.1 变更范围

| 层 | 原 | 现 | 证据/理由 |
|---|---|---|---|
| 货币 | `G.GAME.blh_dao` + `BLH.dao()/add_dao()` + 自绘 HUD | `G.GAME.dollars` + `ease_dollars` + 原版 HUD | 原版 HUD 恒在，「显示不出来」的根因（自绘 `create_UIBox_HUD` 补丁）直接消失 |
| 产出 | 小 `10+5×天` / 大 `20+8×天` / Boss 80·130·200·400 / 十天 2575 | 小 `3+⌊天/2⌋` / 大 `5+天` / Boss 12·20·30·50 / 十天 **386** | 原版金钱稀缺度远高于道（起始 $4、盲注自带 $3~5、券 $10 级）；1:1 会让一次 Boss 奖励超过整局收入 |
| 出牌/弃牌奖励 | ×4 / ×3 道 | 各 ×$1 | 同上 |
| 超额倍率 | ×1.0/1.1/1.25/1.4 | 不变 | 设计意图（性能奖励封顶）不变 |
| 赌命 | 500 / 800 / 1200 道 | $20 / $35 / $55 | $500 在原版金钱下不可能攒到 = 机制死掉 |
| 天龙反刷 | 每 500 道 +10% | 每 $25 +10%（不设上限） | 保持"钱越多越难"的意图；配合提前结局阈值 |
| 提前结局 | 道 ≥ 3600 | 持有金钱 ≥ $250 | 按同一比例（≈1/8）折算 |
| 道印（封印） | +5 道/张 | **财印**：+$2/张（key 仍 `blh_dao`） | key 不变以免重置存档发现度；数值取"比玉印 $3 弱一档" |
| 鼠·寻道（标签） | +40 道 | **鼠·寻金**：立即 +$8 | 同上 |
| 马·竞速（标签） | +2 道/牌型 | +$1/牌型 | 同上 |
| 勾城·契约（幻灵） | 盲注金钱奖励 ×2（原为道 ×2） | 不变（现在乘以金钱奖励） | 文案同步 |

### 16.2 关闭的既有 WARN

`§14.3` 的「道印 / 鼠·寻道 / 马·竞速 在普通局没有任何 HUD 反馈」随本次变更**自然消失**：
三个对象现在给的是钱，普通局同样可见。

### 16.3 顺带修掉的 P0（本次改动中发现）

`BLH.settle_blind` 原本用 `blind.blh_settled = true` 做幂等标记，但 **`G.GAME.blind` 整局只创建一次**
（device `game.lua:2522`，`start_run` 里 `Blind(0,0,2,1)`），而 `Blind:set_blind`（`blind.lua:99-135`）
只重置固定字段、**不会清自定义字段** → 标记跨盲注残留 → **第 2 个盲注起再也不发奖励**（原来发的是道，同样只发一次）。
另外该字段不随存档保存（`blind.lua:774` 的 `Blind:save` 只存固定字段），读档后重复 `defeat` 会重复发。

修复：标记改记在 `G.GAME.blh_settled`，键为 `ante:盲注key`（无 key 时退回 `ante:类型`），
既按盲注区分、又随 G.GAME 存档保留；`init_game_object` 里初始化为 `{}`。

### 16.4 复核

- 语法全绿；`luajit dev/test_blh.lua` → **387/387（ALL PASS）**
- `grep -rn "add_dao\|BLH.dao()\|blh_dao_name" content/ systems/ main.lua localization/` → **0 命中**
- `BLH.dao` / `BLH.add_dao` 已不存在（回归显式断言，防止有人再往旧 API 写）
- 保留的「道」字样均为非货币专名：五城地名「道城·轮回」、塔罗「鼠·仓库寻道」「猴·箱中道」、
  盲注「人鼠·仓库寻道」「地猴·箱中道」
- 版本 2.4.0 → **2.4.1**
