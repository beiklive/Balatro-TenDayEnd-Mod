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

- [x] 二重身 | 复制价值最高的小丑并变为负片
- [x] 反物质 | 所有小丑变负片
- [x] 献祭 | 摧毁价值最低的可摧毁小丑，获得售价 ×3
- [x] 熵增 | 手中所有牌变随机强化
- [x] 回声 | 返还本回合已用掉的出牌次数
- [x] 道城·轮回 | 返还本回合已消耗的出牌与弃牌次数
- [x] 玉城·记忆 | 恢复本局已使用的最后 3 张消耗品中的 1 张
- [x] 涡城·漩涡 | 手牌洗回牌堆并重抽等量
- [x] 勾城·契约 | 本盲注需求 ×1.5，通关奖励 ×2（Boss 不可用）
- [x] 索城·索引 | 指定点数，把牌堆中所有该点数牌加入手牌

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

| key | 名称 | 级 | 效果 |
|---|---|---|---|
| [ ] blh_rat | 人鼠·仓库寻道 | 人 | 每回合随机 1 张手牌背面 |
| [ ] blh_ox | 人牛·障碍赛跑 | 人 | 出牌次数 -1 |
| [ ] blh_tiger | 人虎·狭路相逢 | 人 | 打出少于 5 张时计分 ×0.5 |
| [ ] blh_rabbit | 人兔·蓬莱 | 人 | 弃牌次数 0 |
| [ ] blh_snake | 地蛇·少数与多数 | 地 | 同一牌型不能连续使用 |
| [ ] blh_horse | 地马·木牛流马 | 地 | 每次出牌后手牌上限 -1 |
| [ ] blh_goat | 地羊·四情扇 | 地 | 随机 1 花色 debuff，每回合更换 |
| [ ] blh_monkey | 地猴·箱中道 | 地 | 每次出牌后随机弃 1 张手牌 |
| [ ] blh_rooster | 天鸡·兵器牌 | 天 | 每张计分牌 1/4 概率 debuff |
| [ ] blh_dog | 天狗·送信人 | 天 | 必须按上一手张数出牌 |
| [ ] blh_pig | 天猪·黑白棋子 | 天 | 需求分数随机 ×0.8~×1.4 |
| [ ] blh_dragon | 天龙·天秤游戏 | 天（最终） | Chips/Mult 差距过大 ×0.5，禁用幻灵 |

## 9. 版本 / 封印 / 贴纸

- [x] 版本：回响（打出牌永久 +2 Mult）、清香（回合结束 +$3）、波纹（×1.2 Mult）、生肖（免疫 debuff）、神兽（击败 Boss 永久 +10 Chips +$5）；保留原版负片
- [x] 封印：道印（回合结束在手 +15 道）、玉印（打出 +$3）、涡印（弃掉得 1 标签）、生肖印（再触发一次）、神兽印（击败 Boss 永久 +10 Chips）
- [x] 贴纸：记忆保留（不可摧毁/出售）、深度回响化（每回合 +3 Mult，5 回合后失效）、原住民（每回合 -$3，+10 Mult）、蝼蚁（售价 $0，获得时 +$15）、面具（免疫 debuff，不可复制）

## 10. 美术与图集

统一尺寸：卡面类 71×95；标签 34×34；盲注 34×34 × 21 帧

| 图集 | 内容 | 排布 |
|---|---|---|
| [ ] blh_joker.png | 30 | 6 列 × 5 行 |
| [ ] blh_tarot.png | 21 | 7 列 × 3 行 |
| [ ] blh_spectral.png | 10 | 5 列 × 2 行 |
| [ ] blh_voucher.png | 16 | 8 列 × 2 行 |
| [ ] blh_seal.png | 5 | 5 列 × 1 行 |
| [ ] blh_sticker.png | 5 | 5 列 × 1 行 |
| [ ] blh_tag.png | 16 | 8 列 × 2 行（34×34） |
| [ ] blh_blind.png | 12 × 21 帧 | 12 列 × 21 行（34×34 动画） |

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
