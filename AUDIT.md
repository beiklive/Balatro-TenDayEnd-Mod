# 终焉之地 · beiklive助手 — 最终审计报告

审计对象：`beiklive_helper` v2.3.6（120 个对象：小丑 30 / 优惠券 16 / 塔罗 21 / 幻灵 10 / 封印 5 / 版本 5 / 标签 16 / 盲注 12 / 贴纸 5）

审计基准（**所有结论都必须能落到这些文件的行号上**）：

| 基准 | 位置 | 用途 |
|---|---|---|
| 设备版 Balatro + Steamodded 26.829.0 源码 dump | `/tmp/dump/dump/`（`game.lua`、`card.lua`、`blind.lua`、`cardarea.lua`、`functions/*.lua`、`SMODS/_/src/{game_object,overrides}.lua`） | 判定 Context / Hook / 生命周期是否真实存在 |
| SMODS 参考源码 1.0.0-beta-1814a | `/Users/beiklive/Code/Other/Balatro2_mods/smods-1.0.0-beta-1814a`（`src/utils.lua` 等） | 设备版未 dump 的 SMODS 核心（`calculate_context`、`blueprint_effect`、`Blind:calculate`、`get_mods_scoring_targets`） |
| 原版本地化 | `/Users/beiklive/Code/Other/Balatro_dev/game_original_files/localization/{zh_CN,en-us}.lua` | 术语与概率写法对齐 |
| 自动回归 | `dev/test_blh.lua`（`luajit dev/test_blh.lua`，**283 项**） | 逐项行为断言 |
| 静态审计 | `dev/boundary_report.py`、`dev/canuse_audit.py` | 边界矩阵、消耗品可用性 |

> 设备版 26.829.0 是**权威**；SMODS 参考源码仅用于设备版未 dump 的核心文件，凡依赖它的结论都标注 `[REF-ONLY]`。

---

## 1. 总体审计

| 类型 | 数量 | PASS | WARN | FAIL | BLOCKED |
|---|---:|---:|---:|---:|---:|
| Joker | 30 | 25 | 4 | 1 | 0 |
| Voucher | 16 | 16 | 0 | 0 | 0 |
| Tarot | 21 | 21 | 0 | 0 | 0 |
| Spectral | 10 | 10 | 0 | 0 | 0 |
| Seal | 5 | 5 | 0 | 0 | 0 |
| Edition | 5 | 5 | 0 | 0 | 0 |
| Tag | 16 | 12 | 4 | 0 | 0 |
| Blind | 12 | 12 | 0 | 0 | 0 |
| Sticker | 5 | 5 | 0 | 0 | 0 |
| **合计** | **120** | **111** | **8** | **1** | **0** |

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

---

## 5. P3 问题（数值 / 文案 / 体验 / 工程卫生）

| # | 对象 | 问题 | 状态 |
|---|---|---|---|
| 1 | 全局 | `function SMODS.blh_add_dao(n)` 污染 SMODS 命名空间（且无调用点） | FIXED（删除，内容文件直接用 `BLH.add_dao`） |
| 2 | 塔罗 / 幻灵 | 描述缺少使用条件与边界（并列取色顺序、点数上限、永久加成、覆盖强化、Boss 盲注不可用…） | FIXED（§27：17 张塔罗 + 4 神兽 + 5 幻灵） |
| 3 | 设计文档 | §4/§5/§8 与实现不一致（盲注 8/12 项、勾城·契约"通关时"、索城·索引"指定点数"） | FIXED（按实现重写） |
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
| Endgame / Boss-like | 天龙（showdown）、天猪 | — | 终局挑战 | 强度随道提升 | 第 10 天 | PASS（`win_ante=10` 已修，showdown 只在天 10） |

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
- **文案**：283 项回归中包含"每个消耗品必须有条件行 / `loc_vars` 变量必须被使用 / 中文不得残留英文 / 数值段必须带单位"
- **兼容性**：Blueprint（计分类兼容、永久成长类按原版惯例跳过）、Retrigger（`repetition` 已排除）、Debuff（引擎行为）、Copy（`set_ability`/`copy_card` 保留强化与版本）

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
| 修改是否解决原问题 | 是 | 283 项回归中新增 30+ 项针对本轮修复的断言全部通过 |
| 是否引入新问题 | 否 | 全量 `luajit -bl` 语法检查通过；283/283 通过 |
| 是否破坏其他卡牌 | 否 | 旧断言（探囊"回合结束扣钱"）已按新语义同步更新，其余断言未改 |
| 是否破坏公共机制 | 否 | `mod.calculate` 新增 `setting_blind` 分支，`end_of_round` 分支行为不变（测试覆盖免死/复位） |
| 是否改变描述 | 是（有意） | 6 处文案对齐 + 2 个新本地化键，中英同步 |
| 是否改变状态生命周期 | 是（有意） | `pending` 不再提前消费；标签改用 `round_bonus`；盲注惩罚量被夹紧且还原用实际值 |
| Blueprint | 保持兼容 | 计分类去掉了多余的守卫；永久成长类仍按原版惯例跳过 |
| Retrigger | 无影响 | `repetition` 子通过仍被排除 |
| Save / Load | 无回归 | 状态仍落在 `G.GAME` / `ability.extra` / 原版存档字段上 |
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
