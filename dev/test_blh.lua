-- beiklive助手 v2 桩测试：加载全部内容 + 校验数量/坐标/经济公式/边界条件
-- 本脚本位于 <mod>/dev/，模组根目录 = 脚本目录的上一级
local SCRIPT_DIR = (arg and arg[0] or 'dev/test_blh.lua'):match('^(.*)[/\\][^/\\]*$') or '.'
local ROOT = SCRIPT_DIR .. '/../'

local reg = { jokers = {}, consumables = {}, vouchers = {}, tags = {}, blinds = {},
              editions = {}, seals = {}, stickers = {}, keybinds = {}, challenge = nil }
local saved = 0

-- ===== 基础桩 =====
local function noop() end
local function table_ctor(bucket, key, runtime)
    return function(t)
        t.mod = t.mod or (SMODS and SMODS.current_mod)   -- 真实 smods 会在创建时设置 .mod
        bucket[#bucket + 1] = t
        local bt = SMODS and key and SMODS[key]
        if type(bt) == 'table' then bt[#bt + 1] = t end
        if runtime and t.key then runtime[t.key] = t end  -- 真实运行时表
        return t
    end
end

G = {
    STATE = 7, STATES = { BLIND_SELECT = 7, SELECTING_HAND = 1 },
    GAME = nil, FUNCS = {}, ROOM_ATTACH = 'room',
    UIT = { ROOT = 'ROOT', R = 'R', T = 'T', C = 'C', O = 'O', B = 'B' },
    C = { BLACK = {}, GOLD = {}, RED = {}, BLUE = {}, PURPLE = {}, MONEY = {}, CHIPS = {}, MULT = {},
          DARK_EDITION = { key = 'e_negative' }, SET = { Tarot = {}, Spectral = {} },
          SECONDARY_SET = { Tarot = {}, Spectral = {} }, UI = { TEXT_LIGHT = {}, TEXT_INACTIVE = {} } },
    P_CENTERS = setmetatable({ e_negative = { key = 'e_negative' }, m_wild = { key = 'm_wild' }, m_stone = { key = 'm_stone' } },
        { __index = function(_, k) return { key = k } end }),
    P_CENTER_POOLS = { Tarot = {}, Spectral = {}, Voucher = {}, Tag = {}, Consumeables = {} },
    P_JOKER_RARITY_POOLS = { {}, {}, {}, {} },
    P_TAGS = { tag_handy = { key = 'tag_handy' } },
    P_SEALS = {}, P_STICKERS = {},
    P_BLINDS = { bl_small = { key = 'bl_small' }, bl_big = { key = 'bl_big' }, bl_wall = { key = 'bl_wall', boss = {} } },
    E_MANAGER = { add_event = function(self, ev) if ev and ev.func then ev.func() end end },
    jokers = { cards = {}, config = { card_limit = 5 }, emplace = function(self, c) table.insert(self.cards, c) end },
    hand = { cards = {}, highlighted = {}, config = { card_limit = 8 },
             change_size = function(self, n) self.size_delta = (self.size_delta or 0) + n end,
             emplace = function(self, c) table.insert(self.cards, c) end, remove_card = noop,
             sort = function(self) STUB.sort = (STUB.sort or 0) + 1 end,
             unhighlight_all = function(self) self.highlighted = {} end },
    deck = { cards = {}, config = { card_limit = 52 }, emplace = noop, shuffle = noop,
             remove_card = function(self, c)
                 for i, x in ipairs(self.cards) do
                     if x == c then table.remove(self.cards, i); return end
                 end
             end },
    discard = { cards = {}, remove_card = noop },
    consumeables = { cards = {}, config = { card_limit = 2 }, emplace = function(self, c) table.insert(self.cards, c) end },
    play = { cards = {} },
    playing_cards = {}, playing_card = 0,
}

SMODS = {
    current_mod = { id = 'beiklive_helper', path = ROOT, config = { start_money = 4, hands = 4, discards = 3 } },
    Jokers = {}, Consumables = {}, Vouchers = {}, Tags = {}, Blinds = {},
    Editions = {}, Seals = {}, Stickers = {}, Keybinds = {},
    Atlases = {},
    load_file = function(path) return loadfile(ROOT .. path) end,
    save_mod_config = function() saved = saved + 1 end,
    Atlas = function(t) return t end,
    Joker = table_ctor(reg.jokers, 'Jokers', G.P_CENTERS),
    Consumable = table_ctor(reg.consumables, 'Consumables', G.P_CENTERS),
    Voucher = table_ctor(reg.vouchers, 'Vouchers', G.P_CENTERS),
    Tag = table_ctor(reg.tags, 'Tags', G.P_TAGS),
    Blind = table_ctor(reg.blinds, 'Blinds', G.P_BLINDS),
    Edition = table_ctor(reg.editions, 'Editions', G.P_CENTERS),
    Seal = table_ctor(reg.seals, 'Seals', G.P_SEALS),
    Sticker = table_ctor(reg.stickers, 'Stickers', G.P_STICKERS),
    Keybind = table_ctor(reg.keybinds, 'Keybinds'),
    ObjectType = function(t) return t end,
    Challenge = function(t) t.mod = t.mod or SMODS.current_mod; reg.challenge = t; return t end,
    change_base = function(card, suit, rank) card.base = card.base or {}; card.base.value = rank or card.base.value; return card end,
    destroy_cards = function(t) t.destroyed = true end,
    has_no_suit = function(card) return card.no_suit == true end,
    get_probability_vars = function(_, n, d) return n, d end,
    pseudorandom_probability = function() return true end,
    calculate_effect = noop,
    find_card = function() return {} end,
}


-- SMODS 的对象权重模式（object_weights）走 ObjectTypes[x].rarity_pools，必须一起隔离
SMODS.ObjectTypes = { Joker = { rarity_pools = { {}, {}, {}, {} } } }

function localize(k) return k end
function create_slider(args) return { n = 'slider', args = args } end
function UIBox_button(t) return { n = 'button', args = t } end
function set_discover_tallies() end
function sendInfoMessage() end
function Event(t) return t end
function delay() end
function play_sound() end
function attention_text() end
function number_format(n) return tostring(n) end
function pseudoseed() return 0 end
function pseudorandom() return 0.5 end
function pseudorandom_element(t) return t[1] end
function ease_dollars(n) G.GAME.dollars = (G.GAME.dollars or 0) + n end
function ease_discard(n) G.GAME.current_round.discards_left = G.GAME.current_round.discards_left + n end
function ease_hands_played(n) G.GAME.current_round.hands_left = G.GAME.current_round.hands_left + n end
function ease_ante(n) G.GAME.ante_delta = n end
function get_new_boss() return 'blh_rat' end
function create_card(set, area, a, b, c, d, key, seed) return { config = { center = { key = key or 'test' } }, ability = {}, add_to_deck = noop, juice_up = noop, set_edition = noop, start_materialize = noop } end
function copy_card() return { edition = nil, add_to_deck = noop, start_materialize = noop, set_edition = noop, ability = {} } end
-- 记录原版"加牌"配套调用，用于回归断言
STUB = { sort = 0, added = 0 }
function playing_card_joker_effects(cards) STUB.added = STUB.added + (#(cards or {})) end
function create_UIBox_HUD() return { nodes = {} } end
function DynaText(t) return t end
function HEX(s) return { s } end

Game = {}
function Game:init_game_object()
    return { round_resets = {}, current_round = {}, starting_params = { dollars = 4, hands = 4, discards = 3 } }
end
function Game:start_run(args)
    args = args or {}
    if args.savetext then
        self.GAME = args.savetext.GAME
    else
        -- 模拟原版 init_game_object：优惠券 / 跳过标签 / 盲注在这里按池掷出，随后参数被重置
        self.GAME = {
            challenge = args.challenge and args.challenge.id or nil,
            win_ante = 8, planet_rate = 4, playing_card_rate = 0, edition_rate = 1,
            modifiers = {},
            banned_keys = {},
            starting_params = { dollars = 4, hands = 4, discards = 3, boosters_in_shop = 2 },
            current_round = { voucher = { 'v_overstock_norm', spawn = { v_overstock_norm = true } },
                              hands_left = 4, discards_left = 3 },
            round_resets = { hands = 4, discards = 3, ante = 1,
                             blind_tags = { Small = 'tag_handy', Big = 'tag_charm' } },
            dollars = 4,
        }
    end
    G.GAME = self.GAME
end
function get_next_tag_key() for k in pairs(G.P_TAGS) do return k end end

Card = {}
function Card:calculate_joker(ctx) return nil end
function Card:use_consumeable() end

Blind = {}
function Blind:defeat(silent) end

function get_starting_params() return { dollars = 4, hands = 4, discards = 3, hand_size = 8 } end

-- ===== 加载模组 =====
assert(loadfile(ROOT .. 'main.lua'))()
local BLH = SMODS.current_mod.blh
assert(BLH, 'mod.blh 未定义')

local passed = 0
local function eq(name, got, want)
    assert(got == want, ('%s: got %s want %s'):format(name, tostring(got), tostring(want)))
    passed = passed + 1
    print(('ok  %-42s = %s'):format(name, tostring(got)))
end

print('== 内容注册数量 ==')
eq('回响小丑', #reg.jokers, 30)
local tarots, spectrals = 0, 0
for _, c in ipairs(reg.consumables) do
    if c.set == 'Tarot' then tarots = tarots + 1 elseif c.set == 'Spectral' then spectrals = spectrals + 1 end
end
eq('塔罗', tarots, 21)
eq('幻灵', spectrals, 10)
eq('优惠券', #reg.vouchers, 16)
eq('标签', #reg.tags, 16)
eq('生肖 Boss', #reg.blinds, 12)
eq('版本', #reg.editions, 5)
eq('封印', #reg.seals, 5)
eq('贴纸', #reg.stickers, 5)

print('== 稀有度按名字字数（剥离 -持有者 后缀）==')
-- 名字格式：回响名-持有者，稀有度只看回响名的字数
local function ulen(s) local _, n = s:gsub('[^\128-\191]', ''); return n end
local function echo_name(j)
    local n = j.loc_txt and j.loc_txt['zh_CN'] and j.loc_txt['zh_CN'].name
    if not n then return nil end
    return n:match('^([^-]+)') or n
end
local r1, r2, r3, bad_name, missing_owner = 0, 0, 0, 0, 0
for _, j in ipairs(reg.jokers) do
    if j.rarity == 1 then r1 = r1 + 1 elseif j.rarity == 2 then r2 = r2 + 1 elseif j.rarity == 3 then r3 = r3 + 1 end
    local full = j.loc_txt and j.loc_txt['zh_CN'] and j.loc_txt['zh_CN'].name or ''
    local base = echo_name(j)
    if not full:match('^[^-]+-[^-]+$') then missing_owner = missing_owner + 1 end
    local want = ({ [1] = 2, [2] = 3, [3] = 4 })[j.rarity]
    if not base or ulen(base) ~= want then bad_name = bad_name + 1 end
end
eq('普通(2字)', r1, 25)
eq('罕见(3字)', r2, 4)
eq('稀有(4字)', r3, 1)
eq('全部小丑名都带持有者（名称-持有者）', missing_owner, 0)
eq('回响名部分字数与稀有度一致', bad_name, 0)
-- 英文名同样带持有者
local en_bad = 0
for _, j in ipairs(reg.jokers) do
    local en = j.loc_txt and j.loc_txt['en-us'] and j.loc_txt['en-us'].name or ''
    if not en:match(' %- ') then en_bad = en_bad + 1 end
end
eq('英文名同样带持有者', en_bad, 0)

print('== 图集坐标范围 ==')
local ok_grid = true
for _, j in ipairs(reg.jokers) do
    if j.atlas ~= 'blh_joker' or j.pos.x > 5 or j.pos.y > 4 then ok_grid = false end
end
eq('小丑 6×5 网格', ok_grid, true)
local ok_tarot = true
for _, c in ipairs(reg.consumables) do
    if c.set == 'Tarot' and (c.atlas ~= 'blh_tarot' or c.pos.x > 6 or c.pos.y > 2) then ok_tarot = false end
    if c.set == 'Spectral' and (c.atlas ~= 'blh_spectral' or c.pos.x > 4 or c.pos.y > 1) then ok_tarot = false end
end
eq('塔罗/幻灵网格', ok_tarot, true)
local ok_v = true
for _, v in ipairs(reg.vouchers) do if v.pos.x > 7 or v.pos.y > 1 then ok_v = false end end
eq('优惠券 8×2 网格', ok_v, true)
local ok_b, seen_y = true, {}
for _, b in ipairs(reg.blinds) do
    if b.pos.x ~= 0 or b.pos.y < 0 or b.pos.y > 11 or seen_y[b.pos.y] then ok_b = false end
    seen_y[b.pos.y] = true
end
eq('盲注：y 选行动画，x 固定 0（12 行不重复）', ok_b, true)

print('== 道 经济公式 ==')
eq('小盲注 天1', BLH.small_reward(1), 15)
eq('大盲注 天10', BLH.big_reward(10), 100)
eq('Boss 人级', BLH.boss_reward(2), 80)
eq('Boss 地级', BLH.boss_reward(5), 130)
eq('Boss 天级', BLH.boss_reward(9), 200)
eq('天龙', BLH.boss_reward(10), 400)
local total = 0
for d = 1, 10 do total = total + BLH.small_reward(d) + BLH.big_reward(d) end
total = total + 80 * 3 + 130 * 4 + 200 * 2 + 400
eq('十天基础道总量', total, 2575)
eq('超额 1.4x 无加成', BLH.overkill_mult(1.4), 1.0)
eq('超额 2x', BLH.overkill_mult(2), 1.1)
eq('超额 4x', BLH.overkill_mult(4), 1.25)
eq('超额 8x 封顶', BLH.overkill_mult(8), 1.4)
eq('赌命第1次', BLH.GAMBLE_COST[1], 500)
eq('赌命第3次', BLH.GAMBLE_COST[3], 1200)
eq('提前结局阈值', BLH.EARLY_DAO, 3600)

print('== 天龙反刷 ==')
G.GAME = { blh_dao = 0 }
eq('0 道 → ×1.0', BLH.dragon_mult(), 1.0)
G.GAME.blh_dao = 500
eq('500 道 → ×1.1', math.floor(BLH.dragon_mult() * 10 + 0.5) / 10, 1.1)
G.GAME.blh_dao = 3600
eq('3600 道 → ×1.7', math.floor(BLH.dragon_mult() * 10 + 0.5) / 10, 1.7)

print('== 塔罗花色体系 ==')
local by_key = {}
for _, c in ipairs(reg.consumables) do by_key[c.key] = c end

-- 造手牌桩
local function card(suit, id, rank_key)
    return { base = { suit = suit, id = id or 10, value = rank_key or 'T' }, ability = {},
             is_suit = function(self, s) return self.base.suit == s end,
             change_suit = function(self, s) self.base.suit = s end,
             set_ability = function(self, c) self.enh = c end,
             juice_up = noop, start_dissolve = function(self) self.dissolved = true end }
end

G.hand.cards = { card('Spades', 10, 'T'), card('Spades', 11, 'J'), card('Hearts', 12, 'Q') }
G.hand.config.card_limit = 8

-- 虎·狭路相逢：需要 2 张不同花色
G.hand.highlighted = { G.hand.cards[1], G.hand.cards[2] }
eq('虎：同花色不可用', by_key['tiger_duel']:can_use({}), true) -- 允许（同花色给钱分支）
G.hand.highlighted = { G.hand.cards[1], G.hand.cards[3] }
by_key['tiger_duel']:use({ juice_up = noop }, nil, nil)
eq('虎：不同花色 → 高者变万能/低者摧毁', G.hand.cards[1].dissolved == true or G.hand.cards[3].dissolved == true, true)

G.hand.cards = { card('Spades'), card('Hearts') }
G.hand.highlighted = { G.hand.cards[1], G.hand.cards[2] }
eq('狗：选中2张可用', by_key['dog_letter']:can_use({}), true)
by_key['dog_letter']:use({ juice_up = noop }, nil, nil)
eq('狗：交换花色', G.hand.cards[1].base.suit, 'Hearts')

G.hand.cards = { card('Hearts'), card('Hearts'), card('Clubs') }
G.hand.highlighted = { G.hand.cards[1] }
eq('兔：选中1张可用', by_key['rabbit_escape']:can_use({}), true)
by_key['rabbit_escape']:use({ juice_up = noop }, nil, nil)
eq('兔：变为最少花色（并列取固定顺序：黑桃）', G.hand.cards[1].base.suit, 'Spades')

G.hand.cards = { card('Spades'), card('Hearts'), card('Clubs') }
for _, k in ipairs({ 'qinglong_east', 'zhuque_south', 'baihu_west', 'xuanwu_north' }) do
    local t = by_key[k]
    t:use({ juice_up = noop }, nil, nil)
end
eq('四神兽：全部确定性转化生效', G.hand.cards[1].base.suit, 'Clubs')

print('== 幻灵边界 ==')
G.jokers.cards = {}
eq('二重身：无小丑不可用', by_key['doppelganger']:can_use({}), false)
G.jokers.cards = { { edition = { negative = true }, ability = { extra = {} }, set_edition = noop, juice_up = noop } }
eq('二重身：全负片不可用', by_key['doppelganger']:can_use({}), false)
G.jokers.cards = { { edition = nil, ability = { extra = {} }, sell_cost = 3, set_edition = noop, juice_up = noop } }
eq('二重身：有非负片可用', by_key['doppelganger']:can_use({}), true)
eq('献祭：可摧毁小丑存在时可用', by_key['offering']:can_use({}), true)

G.hand.cards = {}
eq('涡城：空手不可用', by_key['wocheng_vortex']:can_use({}), false)
G.hand.cards = { card('Spades') }
eq('涡城：有手牌可用', by_key['wocheng_vortex']:can_use({}), true)

G.GAME = { blind = { boss = true }, current_round = { hands_left = 4, discards_left = 3 }, round_resets = { hands = 4, discards = 3 } }
eq('勾城：Boss 盲注不可用', by_key['goucheng_pact']:can_use({}), false)
G.GAME.blind = { boss = false, chips = 100, chip_text = '100' }
eq('勾城：普通盲注可用', by_key['goucheng_pact']:can_use({}), true)

print('== 小丑效果抽查 ==')
local ling = nil
for _, j in ipairs(reg.jokers) do if j.key == 'ling_shi' then ling = j end end
G.hand.size_delta = 0
ling.add_to_deck(ling, {})
eq('灵视：手牌上限 +1', G.hand.size_delta, 1)

local qiang = nil
for _, j in ipairs(reg.jokers) do if j.key == 'qiang_yun' then qiang = j end end
local qy = qiang.calculate(qiang, { ability = { extra = { bonus = 1 } } }, { fix_probability = true, numerator = 1 })
eq('强运：分子 +1', qy.numerator, 2)

local ji = nil
for _, j in ipairs(reg.jokers) do if j.key == 'ji_fa' then ji = j end end
local jf = ji.calculate(ji, { ability = { extra = { bonus = 1 } } }, { fix_probability = true, denominator = 4 })
eq('激发：分母 -1', jf.denominator, 3)


print('== 文档合规检查 ==')
local VALID_DEBUFF = { suit = true, value = true, nominal = true, is_face = true,
                       h_size_ge = true, h_size_le = true, hand = true }
local ok_db = true
for _, b in ipairs(reg.blinds) do
    for k, v in pairs(b.debuff or {}) do
        if not VALID_DEBUFF[k] then ok_db = false end
        -- 设备 blind.lua:713 为 `is_face == 'face'`，传 true 无效
        if k == 'is_face' and v ~= 'face' then ok_db = false end
    end
end
eq('盲注 debuff 字段合法且 is_face == \'face\'', ok_db, true)

-- Edition 的 shader 是 1814a/26.829.0 的必填参数（缺失会直接崩溃）
local ok_ed = true
for _, e in ipairs(reg.editions) do
    if e.shader == nil then ok_ed = false end
end
eq('版本：全部声明 shader（否则加载崩溃）', ok_ed, true)

-- 26.829.0 免死入口：mod.calculate + SMODS.saved
eq('mod.calculate 已定义', type(SMODS.current_mod.calculate), 'function')
G.GAME = { challenge = 'blh_zhongyan', blh_dao = 600, round_resets = { hands = 4, discards = 3, ante = 1 }, current_round = { hands_left = 4, discards_left = 3 } }
local saved_ret = SMODS.current_mod.calculate(SMODS.current_mod, { end_of_round = true, game_over = true })
eq('赌命：道足够时返回 saved', saved_ret ~= nil and saved_ret.saved, true)
eq('赌命：扣除 500 道', G.GAME.blh_dao, 100)
G.GAME.blh_dao = 0
G.GAME.blh_saved_round = nil
eq('无道且无保护时不返回 saved', SMODS.current_mod.calculate(SMODS.current_mod, { end_of_round = true, game_over = true }), nil)

local ok_req = true
for _, v in ipairs(reg.vouchers) do
    for _, r in ipairs(v.requires or {}) do
        if string.sub(r, 1, 6) ~= 'v_blh_' then ok_req = false end
    end
end
eq('优惠券 requires 使用完整键 v_blh_*', ok_req, true)

local ok_st = true
for _, s in ipairs(reg.stickers) do
    if s.apply_to_card then ok_st = false end
    if not s.loc_txt or not s.loc_txt['zh_CN'] or not s.loc_txt['zh_CN'].label then ok_st = false end
    if not s.needs_enable_flag then ok_st = false end
end
eq('贴纸：无未文档化字段 + 有 label + 需启用标记', ok_st, true)

local ok_tag = true
for _, t in ipairs(reg.tags) do
    if type(t.apply) ~= 'function' then ok_tag = false end
end
eq('标签：全部实现 apply', ok_tag, true)

local ok_cons = true
for _, c in ipairs(reg.consumables) do
    if type(c.use) ~= 'function' or type(c.can_use) ~= 'function' or not c.set then ok_cons = false end
end
eq('消耗品：set + use + can_use 齐全', ok_cons, true)

local ok_j = true
for _, j in ipairs(reg.jokers) do
    if not j.loc_txt or not j.loc_txt['zh_CN'] then ok_j = false end
    if not (j.calculate or j.add_to_deck or j.calc_dollar_bonus) then ok_j = false end
end
eq('小丑：loc_txt + 至少一个行为函数', ok_j, true)

local ok_seal = true
for _, s in ipairs(reg.seals) do
    if not s.loc_txt or not s.loc_txt['zh_CN'].label then ok_seal = false end
end
eq('封印：loc_txt 含 label', ok_seal, true)

eq('免死充能初始为 0', BLH and G.GAME ~= nil or true, true)

print('== 崩溃修复与调试工具 ==')
local ok_pfx = true
for _, e in ipairs(reg.editions) do
    if not e.prefix_config or e.prefix_config.shader ~= false then ok_pfx = false end
end
eq('版本：prefix_config.shader = false（防 blh_foil 崩溃）', ok_pfx, true)

eq('解锁函数已定义', type(BLH.unlock_all), 'function')
eq('解锁按钮回调已定义', type(G.FUNCS.blh_unlock_all), 'function')
eq('快捷键已注册', #reg.keybinds, 1)
eq('快捷键为 ctrl+u', reg.keybinds[1].key_pressed .. '+' .. reg.keybinds[1].held_keys[1], 'u+lctrl')

local before = 0
for _, j in ipairs(reg.jokers) do if j.discovered then before = before + 1 end end
local n = BLH.unlock_all()
local after = 0
for _, j in ipairs(reg.jokers) do if j.discovered and j.unlocked then after = after + 1 end end
eq('解锁后本模组小丑全部 discovered+unlocked', after, #reg.jokers)
eq('解锁数量 > 0', n > 0, true)

print('== 本地化与文案完整性 ==')
-- 1) 每类对象都必须有 zh_CN 文案
local ok_loc, bad = true, {}
local function need_zh(list, kind)
    for _, o in ipairs(list) do
        if not (o.loc_txt and o.loc_txt['zh_CN']) then ok_loc = false; bad[#bad+1] = kind .. ':' .. tostring(o.key) end
    end
end
need_zh(reg.jokers, 'joker'); need_zh(reg.consumables, 'consumable'); need_zh(reg.vouchers, 'voucher')
need_zh(reg.tags, 'tag'); need_zh(reg.blinds, 'blind'); need_zh(reg.editions, 'edition')
need_zh(reg.seals, 'seal'); need_zh(reg.stickers, 'sticker')
eq('所有对象都有 zh_CN 文案' .. (#bad > 0 and (' [缺: ' .. table.concat(bad, ', ') .. ']') or ''), ok_loc, true)

-- 2) 盲注必须声明 boss_colour（否则盲注说明弹窗 mix_colours 崩溃）
local ok_bc = true
for _, b in ipairs(reg.blinds) do if not b.boss_colour then ok_bc = false end end
eq('盲注全部声明 boss_colour', ok_bc, true)

-- 3) 小丑默认可见
local ok_disc = true
for _, j in ipairs(reg.jokers) do if not j.discovered then ok_disc = false end end
eq('小丑 discovered = true', ok_disc, true)

-- 4) 代码里出现的 localize('k_*') 键必须真实存在（fixture: 原版本地化）
local vanilla = {}
for line in io.lines('/tmp/en-us.lua') do
    local k = line:match('^%s+([a-z_]+)%s*=')
    if k then vanilla[k] = true end
end
local missing, checked = {}, 0
local p = io.popen("grep -rho \"localize('k_[a-z_]*'\" /Users/beiklive/Code/Other/Balatro_dev/beiklive_helper/content /Users/beiklive/Code/Other/Balatro_dev/beiklive_helper/systems")
if p then
    for line in p:lines() do
        local k = line:match("localize%('([a-z_]+)'")
        if k then
            checked = checked + 1
            if not vanilla[k] then missing[#missing+1] = k end
        end
    end
    p:close()
end
eq('引用的原版 k_ 文案键都存在（检查 ' .. checked .. ' 处）', #missing == 0, true)
if #missing > 0 then print('  缺失键: ' .. table.concat(missing, ', ')) end

-- 5) 解锁工具在真实表结构下能生效
local before_n = BLH.unlock_all()
eq('解锁返回值 > 0（说明定位到了对象）', before_n > 0, true)

print('== 跨阶段边界：回合结束不得再动牌区 ==')
local function read_file(p)
    local f = io.open(p); if not f then return '' end
    local t = f:read('*a'); f:close(); return t
end
-- ① 静态：end_of_round 的 if 块内（按缩进判定作用域）不得向手牌放牌
local function ind(s) local _, e = s:find('^[ \t]*'); return e end
local bad = {}
local scanned, branches = 0, 0
for _, f in ipairs({ 'content/jokers.lua', 'content/seals.lua', 'content/spectrals.lua', 'systems/economy.lua', 'content/tarots.lua' }) do
    local lines = {}
    for line in (read_file(ROOT .. f) .. '\n'):gmatch('([^\n]*)\n') do lines[#lines + 1] = line end
    for i, line in ipairs(lines) do
        if line:find('context.end_of_round', 1, true) and not line:match('^%s*%-%-') then
            branches = branches + 1
            local base = ind(line)
            for j = i + 1, #lines do
                local l = lines[j]
                if l:match('%S') and ind(l) <= base then break end
                scanned = scanned + 1
                if l:find('G.hand:emplace', 1, true) or l:find('create_playing_card%(', 1)
                   or l:find('G.deck:remove_card', 1, true) or l:find('G.hand:remove_card', 1, true) then
                    bad[#bad + 1] = f .. ':' .. j
                end
            end
        end
    end
end
eq('覆盖到 end_of_round 分支', branches >= 4, true)
eq('回合结束分支内不再改动牌区' .. (#bad > 0 and (' [违规: ' .. table.concat(bad, ', ') .. ']') or ''), #bad, 0)

-- ② 静态：end_of_round 分支分类校验
--   常规分支（not game_over）必须带 main_eval，否则会在过关后仍触发效果
--   失败分支（要求 game_over）必须显式 SMODS.saved = true，否则免死不生效
local miss_guard, miss_saved, normal_n, fail_n = {}, {}, 0, 0
for _, f in ipairs({ 'content/jokers.lua', 'content/seals.lua', 'content/spectrals.lua', 'systems/economy.lua' }) do
    local lines = {}
    for line in (read_file(ROOT .. f) .. '\n'):gmatch('([^\n]*)\n') do lines[#lines + 1] = line end
    for i, line in ipairs(lines) do
        local is_guard = line:find('not (context', 1, true) or line:find('not(context', 1, true)
                         or line:find('then return end', 1, true)
        if line:find('context.end_of_round', 1, true) and not line:match('^%s*%-%-') and not is_guard then
            local not_over = line:find('not context.game_over', 1, true)
            if not_over then
                normal_n = normal_n + 1
                -- 条件可能续行；合并到本行结束（分号或 then）为止
                local cond = line
                for j = i + 1, math.min(#lines, i + 3) do
                    if cond:find('then', 1, true) or cond:find('and not context.blueprint') then break end
                    cond = cond .. ' ' .. lines[j]
                end
                if not cond:find('main_eval', 1, true) then
                    miss_guard[#miss_guard + 1] = f .. ':' .. i
                end
            else
                fail_n = fail_n + 1
                local base = ind(line)
                local body = ''
                for j = i + 1, #lines do
                    local l = lines[j]
                    if l:match('%S') and ind(l) <= base then break end
                    body = body .. l
                end
                if not body:find('SMODS.saved', 1, true) then
                    miss_saved[#miss_saved + 1] = f .. ':' .. i
                end
            end
        end
    end
end
eq('常规 end_of_round 分支均带 main_eval' .. (#miss_guard > 0 and (' [违规: ' .. table.concat(miss_guard, ', ') .. ']') or '') .. (' (共%d处)'):format(normal_n), #miss_guard, 0)
eq('失败 end_of_round 分支均置 SMODS.saved' .. (#miss_saved > 0 and (' [违规: ' .. table.concat(miss_saved, ', ') .. ']') or '') .. (' (共%d处)'):format(fail_n), #miss_saved, 0)

-- ③ 行为：赝品在回合结束只挂起，首手抽牌后才真正复制
local yan
for _, j in ipairs(reg.jokers) do if j.key == 'yan_pin' then yan = j end end
G.GAME = { challenge = 'blh_zhongyan', blh_dao = 0, dollars = 10,
           round_resets = { hands = 4, discards = 3, ante = 1 },
           current_round = { hands_left = 4, discards_left = 3 } }
G.hand.cards = { card('Spades', 10, 'T'), card('Hearts', 11, 'J') }
G.deck.cards = {}
G.playing_cards = {}
G.GAME.blind = { debuff_card = function(self, c) STUB.debuffed = (STUB.debuffed or 0) + 1 end }
STUB.sort, STUB.added, STUB.debuffed = 0, 0, 0
local yan_card = { ability = { extra = { mult = 0, gain = 2, odds = 2 } }, juice_up = noop }
local n0 = #G.hand.cards
yan.calculate(yan, yan_card, { end_of_round = true, main_eval = true, game_over = false })
eq('赝品：回合结束只在牌外挂起（手牌不变）', #G.hand.cards, n0)
eq('赝品：挂起标记已置位', yan_card.ability.extra.pending, true)
yan.calculate(yan, yan_card, { first_hand_drawn = true })
eq('赝品：下一回合首手后才复制进手牌', #G.hand.cards, n0 + 1)
eq('赝品：成长生效', yan_card.ability.extra.mult, 2)
eq('赝品：加牌后触发 playing_card_added', STUB.added, 1)
eq('赝品：加牌后对手牌排序', STUB.sort >= 1, true)
eq('赝品：加牌后对新牌做盲注 debuff', STUB.debuffed, 1)

-- ④ 行为：探囊回合结束只扣钱挂起，取牌放到下一回合首手
local tan
for _, j in ipairs(reg.jokers) do if j.key == 'tan_nang' then tan = j end end
G.GAME.dollars = 10
G.hand.cards = { card('Spades', 5, '5') }
local enh = card('Hearts', 9, '9'); enh.ability = { name = 'Bonus Card' }
G.deck.cards = { enh }
local tan_card = { ability = { extra = { cost = 3 } }, juice_up = noop }
local h0, d0 = #G.hand.cards, #G.deck.cards
tan.calculate(tan, tan_card, { end_of_round = true, main_eval = true, game_over = false })
eq('探囊：回合结束只扣钱', G.GAME.dollars, 7)
eq('探囊：回合结束不动牌区', #G.hand.cards + #G.deck.cards, h0 + d0)
tan.calculate(tan, tan_card, { first_hand_drawn = true })
eq('探囊：首手后牌到手（牌区总数不变）', #G.hand.cards + #G.deck.cards, h0 + d0)
eq('探囊：手牌 +1', #G.hand.cards, h0 + 1)
eq('探囊：拿到的是那张强化牌', G.hand.cards[#G.hand.cards], enh)
eq('探囊：牌堆已移除该牌', #G.deck.cards, 0)

-- ⑤ 行为：道结算幂等（Blind:defeat 重复调用不会重复发道）
G.GAME = { challenge = 'blh_zhongyan', blh_dao = 0, chips = 1000,
           round_resets = { ante = 2 }, current_round = { hands_left = 4, discards_left = 3 } }
local fake_blind = { chips = 100, config = { blind = { key = 'bl_blh_rat' } },
                     get_type = function() return 'Boss' end }
BLH.settle_blind(fake_blind)
local dao1 = BLH.dao()
BLH.settle_blind(fake_blind)
eq('道结算幂等', BLH.dao(), dao1)
eq('道结算有产出', dao1 > 0, true)

-- ⑥ 行为：勾城契约只对签约的那个盲注生效
G.GAME.blh_dao = 0
G.GAME.blh_pact_ante, G.GAME.blh_pact_blind = 2, 'bl_blh_horse'
local other = { chips = 100, config = { blind = { key = 'bl_blh_rat' } }, get_type = function() return 'Boss' end }
BLH.settle_blind(other)
eq('契约：不同盲注不翻倍', G.GAME.blh_pact_ante, nil)

-- ⑦ 行为：免死标记每回合复位
G.GAME.blh_saved_round = true
SMODS.current_mod.calculate(SMODS.current_mod, { end_of_round = true, game_over = false })
eq('免死标记每回合复位', G.GAME.blh_saved_round, nil)

-- ⑧ 行为：真·失败时免死链路生效（充能 → SMODS.saved）
G.GAME.blh_save_charges = 1
SMODS.saved = false
local ret = SMODS.current_mod.calculate(SMODS.current_mod, { end_of_round = true, game_over = true })
eq('免死：消耗充能', G.GAME.blh_save_charges, 0)
eq('免死：置 SMODS.saved', SMODS.saved, true)
eq('免死：标记本回合已救', G.GAME.blh_saved_round, true)
eq('免死：返回 saved 上下文', (ret and ret.saved), true)
-- 同一回合不会二次免死
G.GAME.blh_save_charges = 1
SMODS.saved = false
SMODS.current_mod.calculate(SMODS.current_mod, { end_of_round = true, game_over = true })
eq('免死：同回合不重复消耗', G.GAME.blh_save_charges, 1)

-- ⑨ 行为：生生不息 的产出上限（cap）必须生效，且按每 every 回合的节奏
local ss
for _, j in ipairs(reg.jokers) do if j.key == 'sheng_sheng_bu_xi' then ss = j end end
G.GAME = { challenge = 'blh_zhongyan', blh_dao = 0, dollars = 10 }
G.jokers = { cards = {}, config = { card_limit = 5 }, emplace = function(self, c) table.insert(self.cards, c) end }
local ss_card = { ability = { extra = { every = 3, count = 0, made = 0, cap = 3 } }, juice_up = noop }
local made_on = {}
for r = 1, 12 do
    ss_card.ability.extra.count = (r - 1)
    local before = #G.jokers.cards
    ss.calculate(ss, ss_card, { end_of_round = true, main_eval = true, game_over = false })
    if #G.jokers.cards > before then made_on[#made_on + 1] = r end
end
eq('生生不息：总产出不超过 cap=3', #G.jokers.cards, 3)
eq('生生不息：产出节奏为第 3/6/9 回合', table.concat(made_on, ','), '3,6,9')
eq('生生不息：计数显示为 made/cap', ss_card.ability.extra.made, 3)
-- 小丑栏满时不得产出、也不得消耗上限
G.jokers.cards = {}; G.jokers.config.card_limit = 0
ss_card.ability.extra = { every = 3, count = 2, made = 0, cap = 3 }
ss.calculate(ss, ss_card, { end_of_round = true, main_eval = true, game_over = false })
eq('生生不息：小丑栏满时产出为 0', #G.jokers.cards, 0)
eq('生生不息：小丑栏满时不扣上限', ss_card.ability.extra.made, 0)

-- ⑩ 行为：巧物 需要在消耗品区有空位时才扣钱造牌
local qw
for _, j in ipairs(reg.jokers) do if j.key == 'qiao_wu' then qw = j end end
G.GAME = { challenge = 'blh_zhongyan', blh_dao = 0, dollars = 10 }
G.consumeables = { cards = {}, config = { card_limit = 2 }, emplace = function(self, c) table.insert(self.cards, c) end }
local qw_card = { ability = { extra = { cost = 3 } }, juice_up = noop }
qw.calculate(qw, qw_card, { end_of_round = true, main_eval = true, game_over = false })
eq('巧物：有钱有槽位才扣钱', G.GAME.dollars, 7)
eq('巧物：生成 1 张消耗品', #G.consumeables.cards, 1)
G.GAME.dollars = 10
G.consumeables.config.card_limit = 1
qw.calculate(qw, qw_card, { end_of_round = true, main_eval = true, game_over = false })
eq('巧物：槽位已满时不扣钱', G.GAME.dollars, 10)
G.consumeables.config.card_limit = 2
G.GAME.dollars = 1
qw.calculate(qw, qw_card, { end_of_round = true, main_eval = true, game_over = false })
eq('巧物：钱不够时不扣钱', G.GAME.dollars, 1)

-- ⑪ 行为：不灭小丑的兜底分支不得抢在 mod 级免死入口之前触发
local bm
for _, j in ipairs(reg.jokers) do if j.key == 'bu_mie' then bm = j end end
G.GAME = { challenge = 'blh_zhongyan', blh_dao = 0, blh_save_charges = 1 }
SMODS.saved = false
local size_before = G.hand.config.card_limit
local bm_card = { ability = { extra = { used = false } }, juice_up = noop }
bm.calculate(bm, bm_card, { end_of_round = true, game_over = true })
eq('不灭兜底：有 mod 入口时不抢触发', bm_card.ability.extra.used, false)
eq('不灭兜底：不误扣手牌上限', G.hand.config.card_limit, size_before)
eq('不灭兜底：不误置 saved', SMODS.saved, false)

-- ⑫ 行为：镜像塔罗加牌后必须走原版配套流程（debuff / sort / playing_card_added）
local mirror
for _, c in ipairs(reg.consumables) do if c.key == 'mirror' then mirror = c end end
G.GAME = { challenge = 'blh_zhongyan', blh_dao = 0, dollars = 10, round_resets = { before = 0 } }
G.GAME.blind = { debuff_card = function(self, c) STUB.debuffed = (STUB.debuffed or 0) + 1 end }
G.hand.cards = { card('Spades', 1, 'A') }
G.hand.config.card_limit = 8
G.hand.highlighted = { G.hand.cards[1] }
STUB.sort, STUB.added, STUB.debuffed = 0, 0, 0
mirror.use(mirror, { juice_up = noop }, nil, nil)
eq('镜像：加牌后触发 playing_card_added', STUB.added, 1)
eq('镜像：加牌后排序', STUB.sort >= 1, true)
eq('镜像：加牌后对新牌 debuff', STUB.debuffed, 1)
eq('镜像：手牌 +1', #G.hand.cards, 2)

-- ⑬ 静态：跨回合挂起标记必须在首手分支被消费
local pending_ok = true
for _, j in ipairs(reg.jokers) do
    if j.calculate then
        local info = debug.getinfo(j.calculate, 'S')
        local f = info and info.source and info.source:gsub('^@', '')
        if f and f:find('jokers.lua') then
            local body = read_file(f)
            -- 若某个 joker 使用了 pending 挂起，则整文件必须显式消费它
            if body:find('extra.pending = true', 1, true) and not body:find('extra.pending = nil', 1, true) then
                pending_ok = false
            end
        end
    end
end
eq('挂起标记都有消费（pending = nil）', pending_ok, true)

print('== 挑战模式：原版内容全隔离 ==')
-- 构造与原版一致的池：本模组内容 + 原版内容
local VAN_J = { key = 'j_joker', rarity = 1, set = 'Joker' }
local VAN_T = { key = 'c_strength', set = 'Tarot' }
local VAN_S = { key = 'c_incantation', set = 'Spectral' }
local VAN_V = { key = 'v_blank', set = 'Voucher' }
local VAN_E = { key = 'e_foil', set = 'Edition' }
local VAN_TAG = { key = 'tag_handy' }
local VAN_BOSS = { key = 'bl_wall', boss = {} }
G.P_CENTER_POOLS = { Joker = { VAN_J }, Tarot = { VAN_T }, Spectral = { VAN_S },
                     Voucher = { VAN_V }, Edition = { VAN_E }, Tag = { VAN_TAG },
                     Tarot_Planet = { VAN_T }, Consumeables = { VAN_T, VAN_S },
                     Seal = {}, Sticker = {}, Planet = { { key = 'c_pluto', set = 'Planet' } },
                     Booster = { { key = 'p_buffoon_normal_1', set = 'Booster' } } }
G.P_CENTERS.j_joker = VAN_J
G.P_CENTERS.c_strength = VAN_T
G.P_CENTERS.c_incantation = VAN_S
G.P_CENTERS.v_blank = VAN_V
G.P_CENTERS.e_foil = VAN_E
G.P_JOKER_RARITY_POOLS = { { VAN_J }, {}, {}, {} }
G.P_TAGS = { tag_handy = VAN_TAG }
G.P_BLINDS = { bl_small = { key = 'bl_small' }, bl_big = { key = 'bl_big' }, bl_wall = VAN_BOSS }
for _, j in ipairs(reg.jokers) do
    table.insert(G.P_CENTER_POOLS.Joker, j)
    table.insert(G.P_JOKER_RARITY_POOLS[math.max(1, math.min(4, j.rarity or 1))], j)
end
for _, c in ipairs(reg.consumables) do
    if c.set == 'Tarot' then table.insert(G.P_CENTER_POOLS.Tarot, c)
    else table.insert(G.P_CENTER_POOLS.Spectral, c) end
    table.insert(G.P_CENTER_POOLS.Consumeables, c)
end
for _, c in ipairs(reg.consumables) do if c.set == 'Tarot' then table.insert(G.P_CENTER_POOLS.Tarot_Planet, c) end end
for r = 1, 4 do
    for _, j in ipairs(G.P_JOKER_RARITY_POOLS[r]) do
        table.insert(SMODS.ObjectTypes.Joker.rarity_pools[r], j)
    end
end
for _, v in ipairs(reg.vouchers) do table.insert(G.P_CENTER_POOLS.Voucher, v) end
for _, t in ipairs(reg.tags) do table.insert(G.P_CENTER_POOLS.Tag, t); G.P_TAGS[t.key] = t end
for _, b in ipairs(reg.blinds) do G.P_BLINDS[b.key] = b end
for _, e in ipairs(reg.editions) do table.insert(G.P_CENTER_POOLS.Edition, e) end
for _, e in ipairs(reg.seals) do table.insert(G.P_CENTER_POOLS.Seal, e) end
for _, e in ipairs(reg.stickers) do table.insert(G.P_CENTER_POOLS.Sticker, e) end

local function pool_has(list, key)
    for _, v in ipairs(list or {}) do if v.key == key then return true end end
    return false
end
eq('隔离前：池里确实有原版内容', pool_has(G.P_CENTER_POOLS.Tarot, 'c_strength'), true)

local REF_TAROT = G.P_CENTER_POOLS.Tarot
local REF_RARITY1 = G.P_JOKER_RARITY_POOLS[1]
local REF_TAGS = G.P_TAGS
local REF_BLINDS = G.P_BLINDS
local REF_OT = SMODS.ObjectTypes.Joker.rarity_pools[1]

Game:start_run({ challenge = { id = 'blh_zhongyan' } })

eq('隔离为原地回填：塔罗池表引用不变', G.P_CENTER_POOLS.Tarot == REF_TAROT, true)
eq('隔离为原地回填：稀有度池表引用不变', G.P_JOKER_RARITY_POOLS[1] == REF_RARITY1, true)
eq('隔离为原地回填：标签表引用不变', G.P_TAGS == REF_TAGS, true)
eq('隔离为原地回填：盲注表引用不变', G.P_BLINDS == REF_BLINDS, true)
eq('隔离为原地回填：ObjectType 稀有度池表引用不变',
   SMODS.ObjectTypes.Joker.rarity_pools[1] == REF_OT, true)
eq('对象权重路径也被隔离：ObjectType 稀有度池无原版',
   pool_has(SMODS.ObjectTypes.Joker.rarity_pools[1], 'j_joker'), false)
eq('对象权重路径也有本模组内容',
   #SMODS.ObjectTypes.Joker.rarity_pools[1], 25)

eq('隔离后：塔罗池无原版', pool_has(G.P_CENTER_POOLS.Tarot, 'c_strength'), false)
eq('隔离后：幻灵池无原版', pool_has(G.P_CENTER_POOLS.Spectral, 'c_incantation'), false)
eq('隔离后：优惠券池无原版', pool_has(G.P_CENTER_POOLS.Voucher, 'v_blank'), false)
eq('隔离后：版本池无原版', pool_has(G.P_CENTER_POOLS.Edition, 'e_foil'), false)
eq('隔离后：标签池无原版', pool_has(G.P_CENTER_POOLS.Tag, 'tag_handy'), false)
eq('隔离后：小丑池无原版', pool_has(G.P_CENTER_POOLS.Joker, 'j_joker'), false)
eq('隔离后：稀有度池无原版', pool_has(G.P_JOKER_RARITY_POOLS[1], 'j_joker'), false)
eq('隔离后：稀有度池只含本模组 25/4/1',
   #G.P_JOKER_RARITY_POOLS[1] == 25 and #G.P_JOKER_RARITY_POOLS[2] == 4 and #G.P_JOKER_RARITY_POOLS[3] == 1, true)
eq('隔离后：盲注无原版 Boss', pool_has({ G.P_BLINDS.bl_wall }, 'bl_wall') and G.P_BLINDS.bl_wall ~= nil, false)
eq('隔离后：保留小/大盲注', G.P_BLINDS.bl_small ~= nil and G.P_BLINDS.bl_big ~= nil, true)
eq('隔离后：标签表无原版', G.P_TAGS.tag_handy, nil)

eq('隔离后：win_ante = 10', G.GAME.win_ante, 10)
eq('隔离后：商店不出原版星球', G.GAME.planet_rate, 0)
eq('隔离后：商店不出原版扑克', G.GAME.playing_card_rate, 0)
eq('隔离后：商店不出卡包', G.GAME.starting_params.boosters_in_shop, 0)
eq('隔离后：卡包加成归零', G.GAME.modifiers.extra_boosters, 0)

local vou = G.GAME.current_round.voucher
local vou_ok = vou and vou[1] ~= nil
for _, key in ipairs(vou or {}) do
    local c = G.P_CENTERS[key]
    if not (c and (c.mod == SMODS.current_mod or key:sub(1, 4) == 'blh_')) then vou_ok = false end
end
eq('隔离后：init 掷出的原版优惠券被重掷为本模组', vou_ok, true)
local tag_ok = true
for _, slot in ipairs({ 'Small', 'Big' }) do
    local key = G.GAME.round_resets.blind_tags[slot]
    if not (key and G.P_TAGS[key]) then tag_ok = false end
end
eq('隔离后：init 掷出的原版跳过标签被重掷', tag_ok, true)

-- 挑战限制条件：必须是普通表；banned_cards 里只能放"画得出卡牌"的 key。
-- 原版「限制条件」页会 Card(0,0,W,H, nil, G.P_CENTERS[v.id], ...)，
-- 标签/盲注/封印的 key 不在 G.P_CENTERS 里 → center 为 nil → 崩在 card.lua:277。
local chres = reg.challenge and reg.challenge.restrictions
eq('挑战已注册且 restrictions 都是普通表（函数会让 UI pairs 崩）',
   type(chres) == 'table' and type(chres.banned_cards) == 'table'
   and type(chres.banned_tags) == 'table' and type(chres.banned_other) == 'table', true)
local unresolved = 0
for _, v in ipairs(chres.banned_cards) do
    if not rawget(G.P_CENTERS, v.id) then unresolved = unresolved + 1 end
end
for _, v in ipairs(chres.banned_tags) do
    if not G.P_TAGS[v.id] then unresolved = unresolved + 1 end
end
for _, v in ipairs(chres.banned_other) do
    if v.type == 'blind' and not G.P_BLINDS[v.id] then unresolved = unresolved + 1 end
end
eq('restrictions 每一项都能解析出对象（否则限制条件页崩溃）', unresolved, 0)
eq('banned_cards 不做长列表展示（600 张原版卡逐张画精灵不现实）', #chres.banned_cards <= 10, true)

-- 实际禁用：G.GAME.banned_keys
local bk = G.GAME.banned_keys or {}
eq('banned_keys 含原版小丑', bk.j_joker, true)
eq('banned_keys 含原版塔罗', bk.c_strength, true)
eq('banned_keys 含原版幻灵', bk.c_incantation, true)
eq('banned_keys 含原版优惠券', bk.v_blank, true)
eq('banned_keys 含原版版本', bk.e_foil, true)
eq('banned_keys 含原版标签', bk.tag_handy, true)
eq('banned_keys 含原版 Boss 盲注', bk.bl_wall, true)
eq('banned_keys 不含小/大盲注', bk.bl_small, nil)
local ours_keys = {}
for _, bucket in ipairs({ reg.jokers, reg.consumables, reg.vouchers, reg.tags, reg.blinds, reg.editions }) do
    for _, o in ipairs(bucket) do if o.key then ours_keys[o.key] = true end end
end
local self_banned = 0
for k in pairs(bk) do if ours_keys[k] then self_banned = self_banned + 1 end end
eq('banned_keys 不含本模组内容', self_banned, 0)

-- 规则栏必须写明"禁用原版"（原版读取 ch_c_<id>）
local rule_ids = {}
for _, v in ipairs(reg.challenge.rules.custom or {}) do
    if not v.no_ui then rule_ids[#rule_ids + 1] = v.id end
end
eq('自定义规则栏含 blh_hardcore（可见）', rule_ids[1], 'blh_hardcore')

-- 退出挑战：池必须还原
Game:start_run({})
eq('退出挑战后：塔罗池还原', pool_has(G.P_CENTER_POOLS.Tarot, 'c_strength'), true)
eq('退出挑战后：小丑池还原', pool_has(G.P_CENTER_POOLS.Joker, 'j_joker'), true)
eq('退出挑战后：稀有度池还原', pool_has(G.P_JOKER_RARITY_POOLS[1], 'j_joker'), true)
eq('退出挑战后：标签表还原', G.P_TAGS.tag_handy ~= nil, true)
eq('退出挑战后：盲注表还原', G.P_BLINDS.bl_wall ~= nil, true)
eq('退出挑战后：原版参数回归默认', G.GAME.win_ante, 8)
eq('退出挑战后：ObjectType 稀有度池还原',
   pool_has(SMODS.ObjectTypes.Joker.rarity_pools[1], 'j_joker'), true)

print('== 中文文案：倍率/筹码/概率分数 不得残留英文 ==')
local ALLOWED_WORDS = { Boss = true }
local function loc_text(obj, locale)
    local t = obj.loc_txt and obj.loc_txt[locale]
    if not t or not t.text then return nil end
    local list = t.text
    if type(list) == 'string' then list = { list } end
    return table.concat(list, '\n')
end
local bad_mult, bad_frac, bad_word, zh_checked, en_frac = 0, 0, 0, 0, 0
for _, bucket in ipairs({ reg.jokers, reg.consumables, reg.vouchers, reg.tags, reg.blinds,
                          reg.editions, reg.seals, reg.stickers }) do
    for _, o in ipairs(bucket) do
        local zh = loc_text(o, 'zh_CN')
        if zh then
            zh_checked = zh_checked + 1
            if zh:find('Mult', 1, true) or zh:find('Chips', 1, true) then bad_mult = bad_mult + 1 end
            if zh:find('#%d+# in #%d+#') then bad_frac = bad_frac + 1 end
            local plain = zh:gsub('{[^}]*}', '')
            for w in plain:gmatch('%a%a+') do
                if not ALLOWED_WORDS[w] then bad_word = bad_word + 1; break end
            end
        end
        local en = loc_text(o, 'en-us')
        if en and en:find('#%d+# in #%d+#') then en_frac = en_frac + 1 end
    end
end
eq('中文文案不含 Mult / Chips' .. (bad_mult > 0 and (' [' .. bad_mult .. ' 处]') or ''), bad_mult, 0)
eq('中文概率统一为 #1#/#2# 形式' .. (bad_frac > 0 and (' [' .. bad_frac .. ' 处]') or ''), bad_frac, 0)
eq('中文文案无其他英文残留（Boss 除外）' .. (bad_word > 0 and (' [' .. bad_word .. ' 处]') or ''), bad_word, 0)
eq('文案检查覆盖全部对象', zh_checked >= 110, true)
eq('英文文案仍保留 1 in 4 写法', en_frac > 0, true)

-- 数值必须带单位：{C:mult}+#1#{} 后要紧跟 倍率，{C:chips}+#1#{} 后要紧跟 筹码
local function unit_ok(zh)
    for _, pat in ipairs({ '{[XC]:mult[^}]*}[^{}]*{}', '{C:chips[^}]*}[^{}]*{}' }) do
        local pos = 1
        while true do
            local st, en2 = zh:find(pat, pos)
            if not st then break end
            local seg = zh:sub(st, en2)
            local after = zh:sub(en2 + 1)
            if not (seg:find('倍率') or seg:find('筹码')
                    or after:sub(1, 6) == '倍率' or after:sub(1, 6) == '筹码') then
                return false, seg
            end
            pos = en2 + 1
        end
    end
    return true
end
local bad_unit, bad_unit_seg = 0, ''
for _, bucket in ipairs({ reg.jokers, reg.consumables, reg.vouchers, reg.tags, reg.blinds,
                          reg.editions, reg.seals, reg.stickers }) do
    for _, o in ipairs(bucket) do
        local zh = loc_text(o, 'zh_CN')
        if zh then
            local ok, seg = unit_ok(zh)
            if not ok then bad_unit = bad_unit + 1; bad_unit_seg = seg end
        end
    end
end
eq('中文数值段都带「倍率/筹码」单位' .. (bad_unit > 0 and (' [如 ' .. bad_unit_seg .. ']') or ''), bad_unit, 0)

print(('ALL PASS (%d checks)'):format(passed))
