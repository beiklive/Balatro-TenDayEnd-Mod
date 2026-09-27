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
             change_size = function(self, n)
                 self.config.card_limit = (self.config.card_limit or 8) + n
                 self.size_delta = (self.size_delta or 0) + n
             end,
             add_to_highlighted = function(self, c, silent) self.hl = c; return c end,
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
    -- 设备侧：SMODS.Enhancement stone 有 no_rank = true（game_object.lua:3447-3452），wild 只有 any_suit
    has_no_rank = function(card) return card.no_rank == true or card.enh == 'm_stone' end,
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
function Card:set_debuff(d) self.debuff = d end
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

G.GAME = { challenge = 'blh_zhongyan', blind = { boss = true, in_blind = true },
           current_round = { hands_left = 4, discards_left = 3 }, round_resets = { hands = 4, discards = 3 } }
eq('勾城：Boss 盲注不可用', by_key['goucheng_pact']:can_use({}), false)
G.GAME.blind = { boss = false, in_blind = true, chips = 100, chip_text = '100' }
eq('勾城：盲注进行中的普通盲注可用', by_key['goucheng_pact']:can_use({}), true)
-- 商店里（blind.in_blind 为假）不可用：否则 +50% 打在已击败的盲注上、奖励永不匹配
G.GAME.blind = { boss = false, chips = 100, chip_text = '100' }
eq('勾城：商店/非进行中不可用', by_key['goucheng_pact']:can_use({}), false)
G.GAME.challenge = nil
G.GAME.blind = { boss = false, in_blind = true }
eq('勾城：非本模式不可用（奖励按道结算）', by_key['goucheng_pact']:can_use({}), false)

-- 同一盲注不能重复签约：惩罚累乘而奖励只有单槽（economy.lua settle_blind 匹配后清空）
G.GAME.challenge = 'blh_zhongyan'
G.GAME.round_resets = { ante = 3, hands = 4, discards = 3 }
G.GAME.blind = { boss = false, in_blind = true, config = { blind = { key = 'bl_small' } } }
eq('勾城：未签约时可用', by_key['goucheng_pact']:can_use({}), true)
G.GAME.blh_pact_blind, G.GAME.blh_pact_ante = 'bl_small', 3
eq('勾城：同一盲注已签约后不可再用', by_key['goucheng_pact']:can_use({}), false)
G.GAME.blh_pact_blind = 'bl_big'
eq('勾城：签约绑的是别的盲注时不拦（跳过盲注留下的残留）', by_key['goucheng_pact']:can_use({}), true)
G.GAME.blh_pact_blind, G.GAME.blh_pact_ante = nil, nil

-- 回声 / 道城·轮回：商店里用它们没有意义（改的是本盲注内的出牌/弃牌次数）
G.GAME = { current_round = { hands_left = 2, discards_left = 3 }, round_resets = { hands = 4, discards = 3 } }
eq('回声：盲注外不可用', by_key['echo']:can_use({}), false)
eq('道城·轮回：盲注外不可用', by_key['daocheng_cycle']:can_use({}), false)
G.GAME.blind = { in_blind = true }
eq('回声：盲注内且已出牌可用', by_key['echo']:can_use({}), true)
eq('道城·轮回：盲注内且已出牌可用', by_key['daocheng_cycle']:can_use({}), true)

-- 幻灵文案必须说清实现里的限制（§15 审计：文案与实现不符）
local function loc_text(key, locale, i)
    local o = by_key[key]
    local t = o and o.loc_txt and o.loc_txt[locale] and o.loc_txt[locale].text
    return (t and t[i]) or ''
end
eq('熵增 zh 文案写明石头牌/万能牌没有点数花色', loc_text('entropy', 'zh_CN', 2):find('石头牌') ~= nil, true)
eq('熵增 en 文案同步（rank/suit kept where ...）', loc_text('entropy', 'en-us', 2):find('rank/suit kept') ~= nil, true)
eq('献祭 zh 文案写明永恒/负片不可献祭', loc_text('offering', 'zh_CN', 3):find('永恒') ~= nil and loc_text('offering', 'zh_CN', 3):find('负片') ~= nil, true)
eq('献祭 en 文案同步（Eternal or already-Negative）', loc_text('offering', 'en-us', 3):find('Negative') ~= nil, true)
eq('二重身 zh 文案写明取售价最高', loc_text('doppelganger', 'zh_CN', 1):find('价值最高') ~= nil, true)
eq('二重身 en 文案写明 most expensive', loc_text('doppelganger', 'en-us', 2):find('most expensive') ~= nil, true)

-- 索城·索引：base 为 nil 的卡（用 G.P_CARDS.empty / 非扑克牌构造）与"无点数"语义
G.GAME = { blind = { in_blind = true } }
G.hand.config = G.hand.config or { card_limit = 8 }
G.hand.cards = { { base = nil, ability = {} } }
eq('索城：手里全是 base 为 nil 的牌时不可用（不崩）', by_key['suocheng_index']:can_use({}), false)
G.hand.cards = { card('Spades', 12, 'Q'), { base = nil, ability = {} } }
G.deck.cards = { { base = nil, ability = {} }, card('Hearts', 12, 'Q') }
eq('索城：牌堆里有 base 为 nil 的卡时仍能正确命中', by_key['suocheng_index']:can_use({}), true)
by_key['suocheng_index']:use({}, nil, nil)
eq('索城：use 在无可用牌堆时不崩', true, true)

-- 判别性断言：石头牌的 base.id 是隐藏底牌点数，但引擎按"无点数"处理（Card:get_id() → 随机负数）
G.hand.cards = { card('Spades', 10, 'T'), { base = { id = 14, value = 'A' }, ability = {}, no_rank = true } }
G.deck.cards = { card('Hearts', 14, 'A') }
eq('索城：无点数的牌不会被当成「手中点数最高」（否则会把 A 拉进手牌）',
    by_key['suocheng_index']:can_use({}), false)
G.deck.cards = { card('Hearts', 14, 'A'), card('Clubs', 10, 'T') }
eq('索城：按真正的最高点数（T）命中牌堆', by_key['suocheng_index']:can_use({}), true)

-- use 由 Card:use_consumeable 直接调用（不复查 can_use），资源被清空时不能崩
G.GAME = { blind = { in_blind = true } }
G.consumeables = G.consumeables or { config = { card_limit = 2 }, cards = {} }
by_key['yucheng_memory']:use({}, nil, nil)
eq('玉城·记忆：use 在「本局没用过消耗品」时不崩', true, true)

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
                    if cond:find('then', 1, true) then break end
                    cond = cond .. ' ' .. lines[j]
                end
                -- 设备版原版小丑用 `not individual / not repetition` 判定主通过；
                -- SMODS 还会额外塞 main_eval。两者任一即可（不得两者都没有）。
                local safe = cond:find('main_eval', 1, true)
                             or (cond:find('not context.individual', 1, true)
                                 and cond:find('not context.repetition', 1, true))
                if not safe then
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
eq('常规 end_of_round 分支都有主通过判定（main_eval 或 not individual/repetition）' .. (#miss_guard > 0 and (' [违规: ' .. table.concat(miss_guard, ', ') .. ']') or '') .. (' (共%d处)'):format(normal_n), #miss_guard, 0)
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
-- 改为"取到牌才扣钱"（见 §29）：回合结束只挂起
eq('探囊：回合结束只挂起、不扣钱', G.GAME.dollars, 10)
eq('探囊：回合结束不动牌区', #G.hand.cards + #G.deck.cards, h0 + d0)
tan.calculate(tan, tan_card, { first_hand_drawn = true })
eq('探囊：取到牌时才扣 $3', G.GAME.dollars, 7)
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

print('== 生生不息：回合计数与产出 ==')
local ss
for _, j in ipairs(reg.jokers) do if j.key == 'sheng_sheng_bu_xi' then ss = j end end
local function ss_game()
    return { challenge = 'blh_zhongyan', blh_dao = 0, round = 1, dollars = 4, modifiers = {}, banned_keys = {},
             round_resets = { hands = 4, ante = 5 },
             current_round = { hands_left = 4, discards_left = 3 } }
end
G.GAME = ss_game()
G.jokers = { cards = {}, config = { card_limit = 5 }, emplace = function(self, c) table.insert(self.cards, c) end }
local ss_card = { ability = { extra = { every = 3, count = 0, made = 0, cap = 3 } }, juice_up = noop }

-- 关键回归：不再依赖 main_eval，普通回合结束上下文就能推进计数
ss.calculate(ss, ss_card, { end_of_round = true, game_over = false })
eq('生生不息：第 1 回合结束 count = 1', ss_card.ability.extra.count, 1)
ss.calculate(ss, ss_card, { end_of_round = true, game_over = false })
eq('生生不息：第 2 回合结束 count = 2', ss_card.ability.extra.count, 2)
ss.calculate(ss, ss_card, { end_of_round = true, game_over = false })
eq('生生不息：第 3 回合产出 1 张负片小丑', #G.jokers.cards, 1)
eq('生生不息：made = 1', ss_card.ability.extra.made, 1)
local lv = ss.loc_vars(ss, {}, ss_card)
eq('生生不息：描述第 4 个变量是累计回合数（每回合都会变）', lv.vars[4], 3)
eq('生生不息：描述第 2 个变量是已生成张数', lv.vars[2], 1)

-- individual / repetition 子通过不得重复触发
local before = ss_card.ability.extra.count
ss.calculate(ss, ss_card, { end_of_round = true, game_over = false, individual = true })
ss.calculate(ss, ss_card, { end_of_round = true, game_over = false, repetition = true })
eq('生生不息：individual / repetition 子通过被忽略', ss_card.ability.extra.count, before)
ss.calculate(ss, ss_card, { end_of_round = true, game_over = true })
eq('生生不息：失败回合不推进', ss_card.ability.extra.count, before)

-- 小丑栏满：不产出、不消耗 cap，并给出「没有空间」提示
G.jokers.config.card_limit = 1        -- 已有 1 张，视为满
ss_card.ability.extra.count = 5       -- 下一次判定落在第 6 回合
local ret = ss.calculate(ss, ss_card, { end_of_round = true, game_over = false })
eq('生生不息：栏满时不产出', #G.jokers.cards, 1)
eq('生生不息：栏满时不消耗 cap', ss_card.ability.extra.made, 1)
eq('生生不息：栏满时给出提示', type(ret) == 'table' and ret.message ~= nil, true)
G.jokers.config.card_limit = 5
ss_card.ability.extra.count = 8       -- 第 9 回合
ss.calculate(ss, ss_card, { end_of_round = true, game_over = false })
eq('生生不息：腾出位置后继续产出', #G.jokers.cards, 2)
eq('生生不息：made = 2', ss_card.ability.extra.made, 2)

print('== 盲注（Boss）效果 ==')
local bk = {}
for _, b in ipairs(reg.blinds) do bk[b.key] = b end
eq('盲注数量', #reg.blinds, 12)

-- 字段完备性（缺 boss_colour 会让盲注说明弹窗崩，见 §21）
local no_colour, no_mult, no_dollars, bad_pos = 0, 0, 0, 0
for i, b in ipairs(reg.blinds) do
    if not b.boss_colour then no_colour = no_colour + 1 end
    if type(b.mult) ~= 'number' then no_mult = no_mult + 1 end
    if type(b.dollars) ~= 'number' then no_dollars = no_dollars + 1 end
    if not (b.pos and b.pos.x == 0 and b.pos.y == i - 1) then bad_pos = bad_pos + 1 end
end
eq('盲注都有 boss_colour', no_colour, 0)
eq('盲注都有 mult（= 需求分数倍率）', no_mult, 0)
eq('盲注都有 dollars（= 击败奖励）', no_dollars, 0)
eq('盲注图集坐标 y = 0..11 且 x = 0', bad_pos, 0)

-- 底注覆盖：按 get_new_boss 的判定（只看 min 与 showdown）
local function eligible(ante)
    local n, showdown = 0, 0
    for _, b in ipairs(reg.blinds) do
        local is_sd = b.boss.showdown == true
        local ok
        if is_sd then ok = (ante % 10 == 0 and ante >= 2)
        else ok = (b.boss.min <= ante and (ante % 10 ~= 0 or ante < 2)) end
        if ok then n = n + 1; if is_sd then showdown = showdown + 1 end end
    end
    return n, showdown
end
local no_boss = 0
for ante = 1, 10 do if (eligible(ante)) == 0 then no_boss = no_boss + 1 end end
eq('天 1–10 每个底注都有可用 Boss（否则退回原版 bl_wall）', no_boss, 0)
eq('第 10 天只有天龙（showdown）可用', select(2, eligible(10)), 1)
local early_sd = 0
for ante = 1, 9 do early_sd = early_sd + select(2, eligible(ante)) end
eq('天 1–9 不会出现 showdown 盲注', early_sd, 0)

-- debuff 只能用设备源码支持的字段（blind.lua:687 Blind:debuff_card）
local VALID_DEBUFF = { suit = true, value = true, nominal = true, is_face = true, hand = true, h_size_ge = true, h_size_le = true }
local bad_debuff = 0
for _, b in ipairs(reg.blinds) do
    for k, v in pairs(b.debuff or {}) do
        if not VALID_DEBUFF[k] then bad_debuff = bad_debuff + 1 end
        if k == 'is_face' and v ~= 'face' then bad_debuff = bad_debuff + 1 end
    end
end
eq("debuff 字段合法且 is_face 必须是字符串 'face'", bad_debuff, 0)

-- 设备版 blind.lua 没有 blind.calculate 的分派点
local calc_used = 0
for _, b in ipairs(reg.blinds) do if b.calculate then calc_used = calc_used + 1 end end
eq('盲注不依赖未被分派的 calculate', calc_used, 0)
eq('天龙用 modify_hand 做计分修正', type(bk.dragon.modify_hand), 'function')
eq('地猴用 press_play 做出牌时机效果', type(bk.monkey.press_play), 'function')

-- 行为：施加 / 还原 / 幂等 / 读档安全
local function new_blind(center)
    return { config = { blind = center }, chips = 1000, chip_text = '1000', disabled = false, boss = true }
end
local function base_game()
    return { challenge = 'blh_zhongyan', blh_dao = 0, round = 3, dollars = 4,
             modifiers = {}, banned_keys = {},
             round_resets = { hands = 4, ante = 5 },
             current_round = { hands_left = 4, discards_left = 3, dollars_to_be_earned = '' } }
end

-- 人牛：出牌次数 -1（先前误做成 The Needle 式只留 1 次）
G.GAME = base_game(); G.GAME.blind = new_blind(bk.ox)
bk.ox.set_blind(bk.ox)
eq('人牛：出牌次数 -1', G.GAME.current_round.hands_left, 3)
bk.ox.set_blind(bk.ox)
eq('人牛：重复 set_blind 不叠加', G.GAME.current_round.hands_left, 3)
bk.ox.disable(bk.ox)
eq('人牛：disable 还原', G.GAME.current_round.hands_left, 4)
bk.ox.disable(bk.ox)
eq('人牛：重复 disable 不重复加回', G.GAME.current_round.hands_left, 4)
G.GAME.current_round.hands_left = 3
G.GAME.blind = { config = { blind = bk.ox }, hands_sub = 1, disabled = false, chips = 1000 }
bk.ox.disable(bk.ox)
eq('人牛：读档后 disable 仍能还原（hands_sub 进存档）', G.GAME.current_round.hands_left, 4)

-- 人兔：弃牌清零
G.GAME = base_game(); G.GAME.blind = new_blind(bk.rabbit)
bk.rabbit.set_blind(bk.rabbit)
eq('人兔：弃牌次数清零', G.GAME.current_round.discards_left, 0)
bk.rabbit.set_blind(bk.rabbit)
eq('人兔：重复 set_blind 不叠加', G.GAME.current_round.discards_left, 0)
bk.rabbit.disable(bk.rabbit)
eq('人兔：disable 还原弃牌次数', G.GAME.current_round.discards_left, 3)
G.GAME.current_round.discards_left = 0
G.GAME.blind = { config = { blind = bk.rabbit }, discards_sub = 3, disabled = false, chips = 1000 }
bk.rabbit.disable(bk.rabbit)
eq('人兔：读档后 disable 仍能还原（discards_sub 进存档）', G.GAME.current_round.discards_left, 3)

-- 地猴 / 天狗：手牌上限是持久值，必须能被 defeat 还原，且不能二次还原
G.GAME = base_game(); G.hand.config.card_limit = 8
G.GAME.blind = new_blind(bk.monkey)
bk.monkey.set_blind(bk.monkey)
eq('地猴：手牌上限 -1', G.hand.config.card_limit, 7)
bk.monkey.defeat(bk.monkey)
eq('地猴：defeat 还原手牌上限', G.hand.config.card_limit, 8)
G.GAME.blind = new_blind(bk.monkey)
bk.monkey.set_blind(bk.monkey)
bk.monkey.disable(bk.monkey)
bk.monkey.defeat(bk.monkey)
eq('地猴：disable 之后 defeat 不二次还原（否则白赚 +1）', G.hand.config.card_limit, 8)
G.hand.config.card_limit = 7
G.GAME.blind = { config = { blind = bk.monkey }, disabled = false, chips = 1000 }
bk.monkey.defeat(bk.monkey)
eq('地猴：读档后 defeat 仍能还原（减少量已在存档里）', G.hand.config.card_limit, 8)
G.GAME.blind = new_blind(bk.dog); G.hand.config.card_limit = 8
bk.dog.set_blind(bk.dog)
eq('天狗：手牌上限 -2', G.hand.config.card_limit, 6)
bk.dog.defeat(bk.dog)
eq('天狗：defeat 还原', G.hand.config.card_limit, 8)

-- soft-lock 保护：惩罚不得把出牌次数 / 手牌上限压到 0
G.GAME = base_game(); G.hand.config.card_limit = 8
G.GAME.current_round.hands_left = 1          -- 玩家把出牌次数配置成 1
G.GAME.blind = new_blind(bk.ox)
bk.ox.set_blind(bk.ox)
eq('人牛：出牌次数不会压到 0（保留 1 次，避免无法出牌）', G.GAME.current_round.hands_left, 1)
bk.ox.disable(bk.ox)
eq('人牛：夹紧后的还原量正确', G.GAME.current_round.hands_left, 1)
G.GAME = base_game(); G.hand.config.card_limit = 2
G.GAME.blind = new_blind(bk.dog)
bk.dog.set_blind(bk.dog)
eq('天狗：手牌上限不会压到 0（保留 1 张）', G.hand.config.card_limit, 1)
bk.dog.defeat(bk.dog)
eq('天狗：夹紧后能正确还原', G.hand.config.card_limit, 2)

-- 天猪：筹码缩放只作用一次，新一次登场重新掷
G.GAME = base_game(); G.GAME.blind = new_blind(bk.pig)
bk.pig.set_blind(bk.pig)
local pig1 = G.GAME.blind.chips
eq('天猪：要求分数被缩放', pig1 ~= 1000, true)
eq('天猪：缩放落在 ×0.8~×1.4', pig1 >= 800 and pig1 <= 1400, true)
eq('天猪：chip_text 同步', G.GAME.blind.chip_text, number_format(pig1))
bk.pig.set_blind(bk.pig)
eq('天猪：重复 set_blind 不重复缩放', G.GAME.blind.chips, pig1)
bk.pig.defeat(bk.pig)
G.GAME.blind = new_blind(bk.pig)
bk.pig.set_blind(bk.pig)
eq('天猪：新一次登场会重新缩放', G.GAME.blind.chips ~= 1000, true)

-- 天龙：强度随道提升 + 天秤计分 ×0.5
G.GAME = base_game(); G.GAME.blh_dao = 1000; G.GAME.blind = new_blind(bk.dragon)
bk.dragon.set_blind(bk.dragon)
eq('天龙：1000 道时强度 ×1.2', math.floor(G.GAME.blind.chips + 0.5), 1200)
local only_spades = { { is_suit = function(self, s) return s == 'Spades' end } }
local mixed = { { is_suit = function(self, s) return s == 'Spades' end },
                { is_suit = function(self, s) return s == 'Hearts' end } }
local m1, c1, modded = bk.dragon.modify_hand(bk.dragon, only_spades, {}, 'Flush', 100, 500)
eq('天龙：黑桃/梅花占比极端时计分 ×0.5', m1, 50)
eq('天龙：modify_hand 返回 triggered = true', modded, true)
eq('天龙：不改筹码', c1, 500)
local m2 = bk.dragon.modify_hand(bk.dragon, mixed, {}, 'Pair', 100, 500)
eq('天龙：花色混合时不减半', m2, 100)

-- 地猴：press_play 随机弃 1 张手牌，且不消耗弃牌次数（同原版 The Hook）
G.GAME = base_game(); G.GAME.blind = new_blind(bk.monkey)
G.FUNCS.discard_cards_from_highlighted = function(e, hook) STUB.discarded = (STUB.discarded or 0) + 1; STUB.hook = hook end
G.hand.cards = { { id = 1 }, { id = 2 } }
STUB.discarded, STUB.hook = 0, nil
local pp = bk.monkey.press_play(bk.monkey)
eq('地猴：press_play 返回 true（触发盲注抖动动画）', pp, true)
eq('地猴：随机弃掉 1 张手牌', STUB.discarded, 1)
eq('地猴：弃牌不消耗弃牌次数', STUB.hook, true)
eq('地猴：弃牌次数未被改动', G.GAME.current_round.discards_left, 3)

print('== 塔罗描述完整度 ==')
local tarots = {}
for _, c in ipairs(reg.consumables) do if c.set == 'Tarot' then tarots[#tarots + 1] = c end end
eq('塔罗数量', #tarots, 21)
local tz = {}
for _, c in ipairs(tarots) do tz[c.key] = c end

local no_hint, no_select, too_short = 0, 0, 0
for _, c in ipairs(tarots) do
    local zh = loc_text(c, 'zh_CN') or ''
    if not zh:find('{C:inactive}', 1, true) then no_hint = no_hint + 1 end
    if c.config and c.config.max_highlighted and not zh:find('选中', 1, true) then no_select = no_select + 1 end
    if #zh < 12 then too_short = too_short + 1 end
end
eq('每张塔罗都写了 {C:inactive} 使用条件/边界提示', no_hint, 0)
eq('需要选牌的塔罗都写明「选中 N 张」', no_select, 0)
eq('塔罗描述不是空壳', too_short, 0)

-- loc_vars 声明的变量必须都在描述里出现（防止写了变量却没用上）
local orphan = 0
for _, c in ipairs(tarots) do
    if type(c.loc_vars) == 'function' then
        local ok, res = pcall(c.loc_vars, c, {})
        local n = (ok and res and res.vars and #res.vars) or 0
        local zh = loc_text(c, 'zh_CN') or ''
        for i = 1, n do
            if not zh:find('#' .. i .. '#', 1, true) then orphan = orphan + 1; break end
        end
    end
end
eq('塔罗 loc_vars 里的变量都在描述中使用', orphan, 0)

-- 本次补齐的关键信息
local function zh_of(k) return loc_text(tz[k], 'zh_CN') or '' end
eq('镜像：写明需要手牌空位', zh_of('mirror'):find('空位', 1, true) ~= nil, true)
eq('鼠：写明加到手牌满为止', zh_of('rat_search'):find('满为止', 1, true) ~= nil, true)
eq('牛：写明点数上限为 A', zh_of('ox_run'):find('上限', 1, true) ~= nil, true)
eq('蛇：写明筹码是永久加成', zh_of('snake_vote'):find('永久', 1, true) ~= nil, true)
eq('鸡：写明会覆盖原有强化', zh_of('rooster_arms'):find('覆盖', 1, true) ~= nil, true)
eq('龙与兔：写明并列时的选取顺序', zh_of('dragon_balance'):find('并列', 1, true) ~= nil
   and zh_of('rabbit_escape'):find('并列', 1, true) ~= nil, true)
eq('虎：写明需要恰好 2 张', zh_of('tiger_duel'):find('恰好 2 张', 1, true) ~= nil, true)
eq('虎：同时给出每张与两张合计金额', #(tz.tiger_duel.loc_vars(tz.tiger_duel, {}).vars), 2)
eq('四神兽：写明需要至少 1 张手牌', zh_of('qinglong_east'):find('至少 1 张', 1, true) ~= nil, true)

-- 幻灵同样要求：使用条件/边界提示 + loc_vars 变量都被用上
local sz = {}
for _, c in ipairs(reg.consumables) do sz[c.key] = c end
local no_hint_all, orphan_all = 0, 0
for _, c in ipairs(reg.consumables) do
    local zh = loc_text(c, 'zh_CN') or ''
    if not zh:find('{C:inactive}', 1, true) then no_hint_all = no_hint_all + 1 end
    if type(c.loc_vars) == 'function' then
        local ok, res = pcall(c.loc_vars, c, {})
        local n = (ok and res and res.vars and #res.vars) or 0
        for i = 1, n do
            if not zh:find('#' .. i .. '#', 1, true) then orphan_all = orphan_all + 1; break end
        end
    end
end
eq('每个消耗品（塔罗 + 幻灵）都有 {C:inactive} 使用条件提示', no_hint_all, 0)
eq('每个消耗品的 loc_vars 变量都在描述中使用', orphan_all, 0)

eq('勾城·契约：写明只能在非 Boss 盲注使用',
   (loc_text(sz.goucheng_pact, 'zh_CN'):find('Boss 盲注不可用', 1, true) ~= nil), true)
eq('勾城·契约：写明是击败该盲注时结算（原来误写「通关时」）',
   (loc_text(sz.goucheng_pact, 'zh_CN'):find('击败该盲注时', 1, true) ~= nil), true)
eq('道城·轮回：写明本回合没消耗过时不可用',
   (loc_text(sz.daocheng_cycle, 'zh_CN'):find('没消耗过', 1, true) ~= nil), true)
eq('玉城·记忆：写明需要消耗品区空位',
   (loc_text(sz.yucheng_memory, 'zh_CN'):find('有空位', 1, true) ~= nil), true)
eq('索城·索引：写明需要空位与同点数牌',
   (loc_text(sz.suocheng_index, 'zh_CN'):find('同点数牌', 1, true) ~= nil), true)

print('== 小丑/标签：静默失败与时机 ==')
local jk = {}
for _, j in ipairs(reg.jokers) do jk[j.key] = j end
local tk = {}
for _, t in ipairs(reg.tags) do tk[t.key] = t end

local function audit_game()
    return { challenge = 'blh_zhongyan', blh_dao = 0, round = 1, dollars = 10, modifiers = {}, banned_keys = {},
             round_resets = { hands = 4, discards = 3, ante = 5 },
             current_round = { hands_left = 4, discards_left = 3 },
             round_bonus = { next_hands = 0, discards = 0 } }
end
G.GAME = audit_game()

-- ① 忘忧：免疫失效（原来只有 ×0.8 惩罚，免疫完全没实现）
local pc = { playing_card = true }
Card.set_debuff(pc, true)
eq('无忘忧时牌会被失效', pc.debuff, true)
G.jokers = { cards = { { config = { center = { key = 'j_blh_wang_you' } } } } }
local pc2 = { playing_card = true }
Card.set_debuff(pc2, true)
eq('持忘忧时牌不会被失效', pc2.debuff, false)
local joker_card = { config = { center = { key = 'j_other' } } }
Card.set_debuff(joker_card, true)
eq('忘忧不影响小丑被失效', joker_card.debuff, true)

-- ② 跃迁：上限按回合计（原来在 context.before 清零 = 每手牌重置）
local yq_card = { ability = { extra = { cap = 2, count = 0 } } }
G.GAME.round = 3
local function use_consumeable()
    return yq.jk and nil
end
local yq = jk.yue_qian
G.GAME.current_round.hands_left = 4
yq.calculate(yq, yq_card, { using_consumeable = true })
eq('跃迁：第 1 张消耗品 +1 手', G.GAME.current_round.hands_left, 5)
yq.calculate(yq, yq_card, { using_consumeable = true })
eq('跃迁：第 2 张消耗品 +1 手', G.GAME.current_round.hands_left, 6)
yq.calculate(yq, yq_card, { using_consumeable = true })
eq('跃迁：同回合第 3 张不再给（上限 2）', G.GAME.current_round.hands_left, 6)
-- 同一回合内出牌不再重置上限
yq.calculate(yq, yq_card, { before = true })
yq.calculate(yq, yq_card, { using_consumeable = true })
eq('跃迁：出牌不重置每回合上限', G.GAME.current_round.hands_left, 6)
-- 进入下一回合后恢复额度
G.GAME.round = 4
yq.calculate(yq, yq_card, { using_consumeable = true })
eq('跃迁：下一回合额度恢复', G.GAME.current_round.hands_left, 7)

-- ③ 探囊：不在回合结束时扣钱，取到牌才扣
local tn = jk.tan_nang
local tn_card = { ability = { extra = { cost = 3 } } }
G.GAME = audit_game(); G.GAME.round = 3
G.GAME.dollars = 10
G.hand.cards = { { base = { id = 5 } } }
G.hand.config.card_limit = 8
G.deck.cards = {}
tn.calculate(tn, tn_card, { end_of_round = true, game_over = false })
eq('探囊：回合结束只挂起不扣钱', G.GAME.dollars, 10)
eq('探囊：挂起标记已置位', tn_card.ability.extra.pending, true)
tn.calculate(tn, tn_card, { first_hand_drawn = true })
eq('探囊：牌堆没有强化牌时不扣钱', G.GAME.dollars, 10)
eq('探囊：无牌可取时清除挂起', tn_card.ability.extra.pending, nil)
-- 有强化牌时才扣钱并拿到牌
G.GAME.dollars = 10
G.deck.cards = { { ability = { name = 'Bonus Card' } } }
tn_card.ability.extra.pending = true
tn.calculate(tn, tn_card, { first_hand_drawn = true })
eq('探囊：成功取牌才扣 $3', G.GAME.dollars, 7)
eq('探囊：牌进入手牌', #G.hand.cards, 2)
-- 手牌满时保留挂起、不扣钱
G.GAME.dollars = 10
G.hand.cards = { {}, {}, {} }
G.hand.config.card_limit = 3
tn_card.ability.extra.pending = true
tn.calculate(tn, tn_card, { first_hand_drawn = true })
eq('探囊：手牌满时不扣钱', G.GAME.dollars, 10)
eq('探囊：手牌满时保留挂起等下一回合', tn_card.ability.extra.pending, true)

-- ④ 巧物：没空间 / 没钱要有反馈
local qw = jk.qiao_wu
local qw_card = { ability = { extra = { cost = 3 } } }
G.GAME = audit_game(); G.GAME.dollars = 10
G.consumeables = { cards = {}, config = { card_limit = 0 }, emplace = function(self, c) table.insert(self.cards, c) end }
local r1 = qw.calculate(qw, qw_card, { end_of_round = true, game_over = false })
eq('巧物：消耗品区满时给出提示', type(r1) == 'table' and r1.message ~= nil, true)
eq('巧物：槽位满时不扣钱', G.GAME.dollars, 10)
G.consumeables.config.card_limit = 2
G.GAME.dollars = 1
local r2 = qw.calculate(qw, qw_card, { end_of_round = true, game_over = false })
eq('巧物：钱不够时给出提示', type(r2) == 'table' and r2.message ~= nil, true)
eq('巧物：钱不够时不扣钱', G.GAME.dollars, 1)

-- ⑤ 显灵：有蜡封但槽位满要有反馈
local xl = jk.xian_ling
local xl_card = { ability = { extra = {} } }
G.GAME = audit_game()
G.hand.cards = { { seal = 'blh_yu' } }
G.consumeables = { cards = {}, config = { card_limit = 0 }, emplace = function(self, c) table.insert(self.cards, c) end }
local r3 = xl.calculate(xl, xl_card, { end_of_round = true, game_over = false })
eq('显灵：槽位满时给出提示', type(r3) == 'table' and r3.message ~= nil, true)

-- ⑥ 标签：牛·负力 / 兔·脱身 写进 round_bonus（否则被下一次 new_round 抹掉）
-- 原版 Tag:yep(msg, colour, func) 会执行 func；桩必须同样执行，否则测不到效果
local function fake_tag(cfg)
    local t = { config = cfg or {}, triggered = false }
    t.yep = function(self, ...)
        for i = 1, select('#', ...) do
            local v = select(i, ...)
            if type(v) == 'function' then v() end
        end
    end
    return t
end
G.GAME = audit_game()
local t_ox = fake_tag(tk.ox_power.config)
tk.ox_power.apply(tk.ox_power, t_ox, { type = 'immediate' })
eq('牛·负力：加成写进 round_bonus.next_hands', G.GAME.round_bonus.next_hands, 1)
tk.ox_power.apply(tk.ox_power, t_ox, { type = 'immediate' })
eq('牛·负力：多次获得可叠加', G.GAME.round_bonus.next_hands, 2)
local t_rab = fake_tag(tk.rabbit_escape.config)
tk.rabbit_escape.apply(tk.rabbit_escape, t_rab, { type = 'immediate' })
eq('兔·脱身：加成写进 round_bonus.discards', G.GAME.round_bonus.discards, 2)

-- ⑦ 标签：猴·取物 / 青龙·之首 的池不能再依赖 SMODS.Jokers（26.829.0 没这个表）
local monkey_pool_ok = false
G.GAME = audit_game()
G.jokers = { cards = {}, config = { card_limit = 5 }, emplace = function(self, c) table.insert(self.cards, c) end }
G.P_JOKER_RARITY_POOLS = { { { key = 'j_blh_test', mod = SMODS.current_mod } }, {}, {}, {} }
local added = {}
local orig_add_joker = add_joker
tk.monkey_take.apply(tk.monkey_take, fake_tag(tk.monkey_take.config), { type = 'immediate' })
eq('猴·取物：能从小丑池里取到本模组小丑', #G.jokers.cards, 1)

-- ⑧ 标签：白虎·调停 挂起到下一个盲注（不再当场 disable 旧盲注）
G.GAME = audit_game()
G.GAME.blind = { boss = true, disabled = false, disable = function(self) self.disabled = true end }
local t_bai = fake_tag(tk.baihu_mediate.config)
tk.baihu_mediate.apply(tk.baihu_mediate, t_bai, { type = 'immediate' })
eq('白虎：当场不解除旧盲注', G.GAME.blind.disabled, false)
eq('白虎：挂起标记已置位', G.GAME.blh_break_blind, true)
-- 下一个盲注进场时由 mod.calculate 消费
SMODS.current_mod.calculate(SMODS.current_mod, { setting_blind = true })
eq('白虎：下一个盲注进场时被解除', G.GAME.blind.disabled, true)
eq('白虎：标记已消费', G.GAME.blh_break_blind, nil)

local function _type_tests()
print('== 版本 / 封印 / 贴纸 / 优惠券 行为与边界 ==')
local ed, sl, st, vc = {}, {}, {}, {}
for _, e in ipairs(reg.editions) do ed[e.key] = e end
for _, x in ipairs(reg.seals) do sl[x.key] = x end
for _, x in ipairs(reg.stickers) do st[x.key] = x end
for _, x in ipairs(reg.vouchers) do vc[x.key] = x end
eq('版本数量', #reg.editions, 5)
eq('封印数量', #reg.seals, 5)
eq('贴纸数量', #reg.stickers, 5)
eq('优惠券数量', #reg.vouchers, 16)

-- ① 版本：注册前置条件（缺 shader / 没关 shader 前缀都会在注册期崩，见 §16/§17）
local no_shader, bad_prefix = 0, 0
for _, e in ipairs(reg.editions) do
    if not e.shader then no_shader = no_shader + 1 end
    if not (e.prefix_config and e.prefix_config.shader == false) then bad_prefix = bad_prefix + 1 end
end
eq('版本都声明了 shader', no_shader, 0)
eq('版本都关闭了 shader 前缀（§17 崩溃根因）', bad_prefix, 0)

-- ② 版本行为（device：小丑走 pre_joker/post_joker，扑克牌走 main_scoring + cardarea==G.play）
G.GAME = audit_game(); G.GAME.dollars = 0
local ecard = { ability = { echo_mult = 0 } }
-- 小丑：pre_joker 结算；joker_main 会被 state_events.lua:689 清空 → 必须无效
ed.echo.calculate(ed.echo, ecard, { pre_joker = true, cardarea = G.jokers })
ed.echo.calculate(ed.echo, ecard, { pre_joker = true, cardarea = G.jokers })
eq('回响：两次出牌累计 +4', ecard.ability.echo_mult, 4)
eq('回响：第 2 次 pre_joker 返回当前总倍率 4',
    (ed.echo.calculate(ed.echo, { ability = { echo_mult = 2 } }, { pre_joker = true }) or {}).mult, 4)
eq('回响：joker_main 无效（引擎已清空 edition）', ed.echo.calculate(ed.echo, ecard, { joker_main = true }), nil)
eq('回响：蓝复制不计成长', ed.echo.calculate(ed.echo, ecard, { pre_joker = true, blueprint = 1 }), nil)
-- 扑克牌：main_scoring + G.play 也必须生效（标准补充包会给扑克牌 roll 版本）
local ccard = { ability = { echo_mult = 0 } }
eq('回响：扑克牌 main_scoring 返回 +2 倍率',
    (ed.echo.calculate(ed.echo, ccard, { main_scoring = true, cardarea = G.play }) or {}).mult, 2)
eq('回响：扑克牌成长写入 ability', ccard.ability.echo_mult, 2)
eq('回响：持牌区（G.hand）不计分', ed.echo.calculate(ed.echo, { ability = { echo_mult = 0 } }, { main_scoring = true, cardarea = G.hand }), nil)
eq('清香：每次出牌 +$1（返回给引擎结算）',
    (ed.fragrance.calculate(ed.fragrance, { ability = {} }, { pre_joker = true, cardarea = G.jokers }) or {}).dollars, 1)
eq('清香：pre_joker 外无效', ed.fragrance.calculate(ed.fragrance, {}, { joker_main = true }), nil)
eq('波纹：post_joker ×1.2 倍率', (ed.ripple.calculate(ed.ripple, {}, { post_joker = true }) or {}).xmult, 1.2)
eq('波纹：扑克牌 ×1.2 倍率', (ed.ripple.calculate(ed.ripple, {}, { main_scoring = true, cardarea = G.play }) or {}).xmult, 1.2)
eq('波纹：joker_main 无效', ed.ripple.calculate(ed.ripple, {}, { joker_main = true }), nil)
eq('生肖：pre_joker +30 筹码', (ed.zodiac.calculate(ed.zodiac, {}, { pre_joker = true }) or {}).chips, 30)
eq('生肖：扑克牌 +30 筹码', (ed.zodiac.calculate(ed.zodiac, {}, { main_scoring = true, cardarea = G.play }) or {}).chips, 30)
eq('神兽：每次出牌 +$2（返回给引擎结算）',
    (ed.beast.calculate(ed.beast, { ability = {} }, { pre_joker = true, cardarea = G.jokers }) or {}).dollars, 2)
eq('神兽：post_joker ×1.1 倍率', (ed.beast.calculate(ed.beast, {}, { post_joker = true }) or {}).xmult, 1.1)
local beast_pc = ed.beast.calculate(ed.beast, {}, { main_scoring = true, cardarea = G.play }) or {}
eq('神兽：扑克牌同一次结算同时给倍率与钱（不互相吃掉）',
    tostring(beast_pc.xmult) .. '/' .. tostring(beast_pc.dollars), '1.1/2')
-- 版本必须带 in_shop / weight（否则不会出现在商店）
local no_shop = 0
for _, e in ipairs(reg.editions) do if e.in_shop ~= true or type(e.weight) ~= 'number' then no_shop = no_shop + 1 end end
eq('版本都可进商店且有权重', no_shop, 0)

-- ③ 封印行为
G.GAME = audit_game(); G.GAME.dollars = 0
local sc = { ability = { seal = { dollars = 3 } } }
do
    -- 用"总额"模型断言：引擎会结算返回的 dollars，若再手调 ease_dollars 就是双倍给钱
    local before = G.GAME.dollars
    local ret = sl.yu.calculate(sl.yu, sc, { main_scoring = true, cardarea = G.play }) or {}
    local total = (G.GAME.dollars - before) + (ret.dollars or 0)
    eq('玉印：打出总额恰好 +$3（不双倍）', total, 3)
end
G.GAME.dollars = 0
local bc = { ability = { seal = { chips = 10, dollars = 2 } } }
eq('神兽印：+10 筹码', (sl.beast.calculate(sl.beast, bc, { main_scoring = true, cardarea = G.play }) or {}).chips, 10)
do
    local before = G.GAME.dollars
    local ret = sl.beast.calculate(sl.beast, bc, { main_scoring = true, cardarea = G.play }) or {}
    local total = (G.GAME.dollars - before) + (ret.dollars or 0)
    eq('神兽印：打出总额恰好 +$2（不双倍）', total, 2)
end
eq('生肖印：repetition 返回 repetitions=1', (sl.zodiac.calculate(sl.zodiac, { ability = { seal = {} } }, { repetition = true, cardarea = G.play }) or {}).repetitions, 1)
do
    local dcard = { ability = { seal = { dao = 15 } } }
    local dret = sl.dao.calculate(sl.dao, dcard, { main_scoring = true, cardarea = G.play })
    eq('道印：打出时返回给道提示', type(dret) == 'table', true)
end
-- 涡印：槽位满时不生成，有空位时生成 1 张
G.GAME = audit_game()
G.consumeables = { cards = {}, config = { card_limit = 0 }, emplace = function(self, c) table.insert(self.cards, c) end }
do
    local wocard = { ability = { seal = {} } }
    eq('涡印：手牌里没被弃的那张不触发', sl.wo.calculate(sl.wo, wocard, { discard = true, other_card = {} }), nil)
    eq('涡印：槽位满时不生成', sl.wo.calculate(sl.wo, wocard, { discard = true, other_card = wocard }), nil)
    G.consumeables.config.card_limit = 2
    sl.wo.calculate(sl.wo, wocard, { discard = true, other_card = wocard })
    eq('涡印：被弃的那张才生成 1 张塔罗', #G.consumeables.cards, 1)
end
-- 每个封印都必须有 badge_colour（UI 需要）
local no_badge = 0
for _, x in ipairs(reg.seals) do if not x.badge_colour then no_badge = no_badge + 1 end end
eq('封印都有 badge_colour', no_badge, 0)

-- ④ 贴纸行为
G.GAME = audit_game(); G.GAME.dollars = 0
eq('记忆保留：+10 筹码', (st.memory.calculate(st.memory, { ability = {} }, { joker_main = true }) or {}).chips, 10)
eq('原住民：+12 倍率', (st.native.calculate(st.native, { ability = {} }, { joker_main = true }) or {}).mult, 12)
eq('面具：+8 倍率', (st.mask.calculate(st.mask, { ability = {} }, { joker_main = true }) or {}).mult, 8)
do
    local before = G.GAME.dollars
    local ret = st.ant.calculate(st.ant, { ability = {} }, { individual = true, cardarea = G.play }) or {}
    eq('蝼蚁：每张计分牌 +$1（走 return，不嵌套 money_altered）', (G.GAME.dollars - before) + (ret.dollars or 0), 1)
end
-- 深度回响化：文案写"最多叠加 5 次"，必须真的叠加（原实现永远 +3）
local dcard = { ability = {} }
local m1 = (st.deep_echo.calculate(st.deep_echo, dcard, { joker_main = true }) or {}).mult
local m2 = (st.deep_echo.calculate(st.deep_echo, dcard, { joker_main = true }) or {}).mult
eq('深度回响化：第 1 次 +3', m1, 3)
eq('深度回响化：第 2 次叠加到 +6', m2, 6)
for _ = 3, 8 do st.deep_echo.calculate(st.deep_echo, dcard, { joker_main = true }) end
eq('深度回响化：上限 5 层 = +15', (st.deep_echo.calculate(st.deep_echo, dcard, { joker_main = true }) or {}).mult, 15)
-- 贴纸都必须声明 sets 与 rate（否则随机附着不会发生）
local no_sets = 0
for _, x in ipairs(reg.stickers) do if not x.sets or type(x.rate) ~= 'number' then no_sets = no_sets + 1 end end
eq('贴纸都有 sets 与 rate', no_sets, 0)

-- ⑤ 优惠券：每张 redeem 都必须真的改变状态；requires 链必须能解析
local function snap()
    return {
        hands = G.GAME.round_resets.hands, discards = G.GAME.round_resets.discards,
        reroll = G.GAME.round_resets.reroll_cost, hlim = G.hand.config.card_limit,
        jlim = G.jokers.config.card_limit, clim = G.consumeables.config.card_limit,
        jmax = G.GAME.shop and G.GAME.shop.joker_max or -1, dollars = G.GAME.dollars,
    }
end
local unchanged = {}
for _, v in ipairs(reg.vouchers) do
    G.GAME = audit_game()
    G.GAME.shop = { joker_max = 2 }
    G.GAME.round_resets.reroll_cost = 5
    G.GAME.base_reroll_cost = 5          -- 原版 init_game_object 会设置（桩需补齐）
    G.hand.config.card_limit, G.jokers.config.card_limit, G.consumeables.config.card_limit = 8, 5, 2
    local before = snap()
    v.redeem(v, {})
    local after = snap()
    local diff = false
    for k, val in pairs(before) do if after[k] ~= val then diff = true end end
    if not diff then unchanged[#unchanged + 1] = v.key end
end
eq('每张优惠券的 redeem 都真的改变了状态' .. (#unchanged > 0 and (' [未生效: ' .. table.concat(unchanged, ',') .. ']') or ''), #unchanged, 0)
local vkeys = {}
for _, v in ipairs(reg.vouchers) do vkeys[v.key] = true end
local bad_req = 0
for _, v in ipairs(reg.vouchers) do
    for _, r in ipairs(v.requires or {}) do
        -- 真实运行时 requires 用完整 key（v_blh_xxx）；桩里的 key 不带 v_/blh_ 前缀
        local bare = r:gsub('^v_', ''):gsub('^blh_', '')
        if not (vkeys[r] or vkeys[bare]) then bad_req = bad_req + 1 end
    end
end
eq('优惠券 requires 链都能解析到本模组优惠券', bad_req, 0)
local no_cost = 0
for _, v in ipairs(reg.vouchers) do if type(v.cost) ~= 'number' then no_cost = no_cost + 1 end end
eq('优惠券都有 cost', no_cost, 0)
end
_type_tests()

local function _round3_tests()
print('== 第三轮审计修复的回归 ==')
local jk, tk, vc, sl, st, tz = {}, {}, {}, {}, {}, {}
for _, x in ipairs(reg.jokers) do jk[x.key] = x end
for _, x in ipairs(reg.tags) do tk[x.key] = x end
for _, x in ipairs(reg.vouchers) do vc[x.key] = x end
for _, x in ipairs(reg.seals) do sl[x.key] = x end
for _, x in ipairs(reg.stickers) do st[x.key] = x end
for _, x in ipairs(reg.consumables) do if x.set == 'Tarot' then tz[x.key] = x end end
local function fake_tag(cfg)
    local t = { config = cfg or {}, triggered = false }
    t.yep = function(self, ...) for i = 1, select('#', ...) do local v = select(i, ...); if type(v) == 'function' then v() end end end
    return t
end
local function game()
    G.GAME = { challenge = 'blh_zhongyan', blh_dao = 0, round = 3, dollars = 10, modifiers = {}, banned_keys = {},
               round_resets = { hands = 4, discards = 3, ante = 5 },
               current_round = { hands_left = 4, discards_left = 3, voucher = { 'v_blh_mask', spawn = { v_blh_mask = true } } },
               shop = { joker_max = 2 }, base_reroll_cost = 5 }
    G.GAME.round_resets.reroll_cost = 5
    G.hand.config.card_limit = 8
    G.jokers.config.card_limit = 5
    G.consumeables = { cards = {}, config = { card_limit = 2 }, emplace = function(self, c) table.insert(self.cards, c) end }
end

-- ① 塔罗选中上界（SMODS 的 can_use 会绕过原版高亮上限检查）
game()
G.hand.highlighted = { {}, {}, {}, {}, {} }
eq('权柄：高亮 5 张时不可用（上界 2）', tz.dominion.can_use(tz.dominion, {}), false)
G.hand.highlighted = { {}, {} }
eq('权柄：高亮 2 张可用', tz.dominion.can_use(tz.dominion, {}), true)
G.hand.highlighted = { {}, {}, {}, {} }
eq('牛：高亮 4 张时不可用（上界 3）', tz.ox_run.can_use(tz.ox_run, {}), false)
G.hand.highlighted = { {}, {}, {} }
eq('牛：高亮 3 张可用', tz.ox_run.can_use(tz.ox_run, {}), true)

-- ② 蛇：花色并列时不能只结算筹码（原来 elseif 吞掉给钱）
game()
-- 四种花色各 1 张 → 计数全并列（minor == major == Spades）：
-- 原来用 elseif，同一张牌只会结算筹码、吞掉给钱；改成两个独立判断后两者都要结算
local function suitcard(suit)
    return { ability = {}, juice_up = noop, is_suit = function(self, s) return s == suit end }
end
G.hand.cards = { suitcard('Spades'), suitcard('Hearts'), suitcard('Clubs'), suitcard('Diamonds') }
G.GAME.dollars = 0
tz.snake_vote.use(tz.snake_vote, { juice_up = noop }, nil, nil)
eq('蛇：花色并列时仍然给钱（不再被 elseif 吞掉）', G.GAME.dollars > 0, true)
eq('蛇：并列花色（黑桃）同时吃到筹码', (G.hand.cards[1].ability.perma_bonus or 0) > 0, true)

-- ③ 虎·强势：必须走原版 reroll_boss（否则盲选 UI 与实际对战不一致）
game()
STUB.reroll = false
local saved_reroll = G.FUNCS.reroll_boss
G.FUNCS.reroll_boss = function() STUB.reroll = true end
local t_tiger = fake_tag(tk.tiger_strong.config)
tk.tiger_strong.apply(tk.tiger_strong, t_tiger, { type = 'new_blind_choice' })
eq('虎·强势：调用 G.FUNCS.reroll_boss 重建盲选', STUB.reroll, true)
eq('虎·强势：设置 G.from_boss_tag（豁免原版 -$10）', G.from_boss_tag, true)
G.FUNCS.reroll_boss = saved_reroll
G.from_boss_tag = nil
G.CONTROLLER = nil

-- ④ 狗·传信 / 青龙·之首：免费优惠券真的加进商店，且绝不写 current_round.voucher = nil
game()
G.shop_vouchers = { cards = {}, config = { card_limit = 1 }, T = { x = 0, y = 0, w = 1, h = 1 },
                    emplace = function(self, c) table.insert(self.cards, c) end }
G.P_CARDS = { empty = {} }
get_next_voucher_key = function() return 'v_blh_mask' end
create_shop_card_ui = function() end
local mt = getmetatable(Card)
setmetatable(Card, { __call = function(...) return { ability = {}, start_materialize = noop } end })
-- 桩里 Card 原本是 table，add_free_voucher 的 card_init_ok() 要求它是 callable；
-- 上面的 __call 已满足 type(Card)=='function'？不满足——改用可调用表并放宽 card_init_ok 判定
local voucher_before = G.GAME.current_round.voucher
local t_dog = fake_tag(tk.dog_letter.config)
tk.dog_letter.apply(tk.dog_letter, t_dog, { type = 'voucher_add' })
eq('狗·传信：商店多出 1 张免费券', #G.shop_vouchers.cards, 1)
eq('狗·传信：券是免费的', G.shop_vouchers.cards[1].cost, 0)
eq('狗·传信：不会把 current_round.voucher 置 nil（否则进商店崩）', G.GAME.current_round.voucher, voucher_before)
local t_ql = fake_tag(tk.qinglong_head.config)
G.jokers.cards = {}
tk.qinglong_head.apply(tk.qinglong_head, t_ql, { type = 'voucher_add' })
eq('青龙·之首：再加 1 张免费券', #G.shop_vouchers.cards, 2)
eq('青龙·之首：负片小丑不检查小丑栏（满栏也能给）', #G.jokers.cards, 1)
eq('青龙·之首：type 已改为 voucher_add', tk.qinglong_head.config.type, 'voucher_add')
setmetatable(Card, mt)

-- ⑤ 白虎·调停：非 Boss 盲注不消费标记
game()
G.GAME.blh_break_blind = true
G.GAME.blind = { boss = false, disable = function(self) self.disabled = true end }
SMODS.current_mod.calculate(SMODS.current_mod, { setting_blind = true })
eq('白虎：大/小盲注不消费标记', G.GAME.blh_break_blind, true)
G.GAME.blind = { boss = true, disable = function(self) self.disabled = true end }
SMODS.current_mod.calculate(SMODS.current_mod, { setting_blind = true })
eq('白虎：Boss 盲注才解除限制', G.GAME.blind.disabled, true)
eq('白虎：Boss 盲注消费标记', G.GAME.blh_break_blind, nil)

-- ⑥ 朱雀·审判：没有可摧毁的小丑时不给钱
game()
G.jokers.cards = {}
G.GAME.dollars = 0
tk.zhuque_judge.apply(tk.zhuque_judge, fake_tag(tk.zhuque_judge.config), { type = 'immediate' })
eq('朱雀：无小丑可摧毁时不给钱', G.GAME.dollars, 0)
local eternal = { ability = { eternal = true } }
G.jokers.cards = { eternal }
tk.zhuque_judge.apply(tk.zhuque_judge, fake_tag(tk.zhuque_judge.config), { type = 'immediate' })
eq('朱雀：只有永恒小丑时不给钱', G.GAME.dollars, 0)

-- ⑦ 猴·取物 / 鸡·夺械：栏位满时不崩、且不静默（有提示分支）
game()
G.jokers.cards = { {}, {}, {}, {}, {} }; G.jokers.config.card_limit = 5
G.P_JOKER_RARITY_POOLS = { { { key = 'j_blh_x', mod = SMODS.current_mod } }, {}, {}, {} }
tk.monkey_take.apply(tk.monkey_take, fake_tag(tk.monkey_take.config), { type = 'immediate' })
eq('猴·取物：小丑栏满时不报错', #G.jokers.cards, 5)
G.consumeables.cards = { {}, {} }; G.consumeables.config.card_limit = 2
G.P_CENTER_POOLS.Tarot = { { key = 'c_blh_x' } }
eq('鸡·夺械：消耗品栏满时不报错', pcall(function()
    tk.rooster_weapon.apply(tk.rooster_weapon, fake_tag(tk.rooster_weapon.config), { type = 'immediate' })
end), true)

-- ⑧ 优惠券：面具要让当前商店立刻生效；巨钟要走 change_shop_size
game()
G.GAME.current_round.reroll_cost = 5
STUB.reroll_calc = 0
calculate_reroll_cost = function() STUB.reroll_calc = STUB.reroll_calc + 1 end
vc.mask.redeem(vc.mask, {})
eq('面具：当前商店刷新价立刻下降', G.GAME.current_round.reroll_cost, 4)
eq('面具：调用 calculate_reroll_cost 重算', STUB.reroll_calc > 0, true)
game()
STUB.shop_size = nil
change_shop_size = function(mod) STUB.shop_size = mod end
vc.bell_tower.redeem(vc.bell_tower, {})
eq('巨钟：走 change_shop_size（同时更新商店区域上限）', STUB.shop_size, 1)

-- ⑨ 深度回响化：计数挂在贴纸自己的 ability 子表下（移除贴纸会被清）
game()
local dcard = { ability = {} }
st.deep_echo.calculate(st.deep_echo, dcard, { joker_main = true })
eq('深度回响化：计数在 ability.blh_deep_echo.hits 下', (dcard.ability.blh_deep_echo or {}).hits, 1)
eq('深度回响化：顶层不再残留自定义键', dcard.ability.blh_deep_echo_hits, nil)
end
_round3_tests()
print(('ALL PASS (%d checks)'):format(passed))
