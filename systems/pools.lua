--- 终焉之地 · 挑战与池隔离
--- 完全硬核：挑战内原版小丑 / 塔罗 / 幻灵 / 优惠券 / 标签 / 版本 / 封印 / 贴纸 / Boss 盲注
--- 全部不可获得；商店不再出现原版星球牌与卡包

local mod = SMODS.current_mod
local BLH = mod.blh

------------------------------------------------------------------
-- 主题池：所有本模组内容都声明进这个池，便于重建
------------------------------------------------------------------
SMODS.ObjectType {
    key = 'blh_zhongyan',
    default = 'Joker',
    cards = {},
}

local function is_ours(obj)
    return obj ~= nil and (obj.mod == mod or (obj.key and obj.key:sub(1, 4) == 'blh_'))
end

local ORIG = nil

-- 挑战内被重建为"仅本模组"的中央池。
-- 这 10 个池本模组都有自有内容，因此过滤后池非空；
-- 这点很重要：`create_card` 在池里一个可用项都没有时会走"空池兜底"，
-- 强行返回原版卡（j_joker / c_strength / c_incantation / v_blank / tag_handy / e_foil…）。
local POOL_KEYS = {
    'Joker', 'Tarot', 'Tarot_Planet', 'Spectral', 'Consumeables',
    'Voucher', 'Tag', 'Edition', 'Seal', 'Sticker',
}

-- 进入 G.GAME.banned_keys 的原版 set。
-- 刻意不含 Planet / Booster / Enhanced：本模组没有这三类内容，
-- 一旦全部禁用，池里就没有可用项，`create_card` 会命中上面说的空池兜底并把原版卡塞回来；
-- 这三类改为"切断获取途径"处理：见 apply_run_params（商店 rate = 0、卡包数量 = 0）。
local BAN_SETS = {
    Joker = true, Tarot = true, Spectral = true, Voucher = true,
    Edition = true, Seal = true, Sticker = true,
}

------------------------------------------------------------------
-- 原版内容禁用：写进 G.GAME.banned_keys
--
-- 注意：不能塞进挑战的 restrictions.banned_cards。
-- 原版「限制条件」页会为列表里每一项创建卡牌精灵：
--   Card(0,0,W,H, nil, G.P_CENTERS[v.id], ...)
-- 标签 / 盲注 / 封印的 key 不在 G.P_CENTERS 里 → center 为 nil →
-- 崩在 card.lua:277（Card:set_ability 索引 center）。而且原版全部卡牌有 600+ 项，
-- 这个页面会一张张画精灵，移动端也不现实。
-- 所以 restrictions 三个列表保持为空，禁用一律在这里做。
------------------------------------------------------------------
local function apply_banned_keys()
    local bk = G.GAME and G.GAME.banned_keys
    if not bk then return end
    for key, center in pairs(G.P_CENTERS or {}) do
        if not is_ours(center) and BAN_SETS[center.set] then bk[key] = true end
    end
    -- 标签 / 盲注取"隔离前的原始快照"：isolate() 已把全局表过滤成只剩本模组
    for key, tag in pairs((ORIG and ORIG.tags) or G.P_TAGS or {}) do
        if not is_ours(tag) then bk[key] = true end
    end
    -- 只禁 Boss 盲注：小/大盲注是底注结构，禁掉会让选盲界面没有可用盲注
    for key, blind in pairs((ORIG and ORIG.blinds) or G.P_BLINDS or {}) do
        if blind.boss and not is_ours(blind) then bk[key] = true end
    end
    -- 封印只加 banned_keys，不从 G.P_SEALS 里删除：card.lua 会无条件索引 G.P_SEALS[self.seal]，
    -- 删表会让带封印的牌直接报错。
    -- （贴纸不走这里：G.P_STICKERS 在 26.829.0 不存在，贴纸表是 SMODS.Stickers；
    --   本模组贴纸靠 needs_enable_flag + 挑战 rules.custom 限定，见 DESIGN §9.3）
    for key, seal in pairs(G.P_SEALS or {}) do
        if not is_ours(seal) then bk[key] = true end
    end
end

------------------------------------------------------------------
-- 池快照 / 原地回填
------------------------------------------------------------------
local function copy_array(t)
    local o = {}
    for i, v in ipairs(t or {}) do o[i] = v end
    return o
end

local function copy_map(t)
    local o = {}
    for k, v in pairs(t or {}) do o[k] = v end
    return o
end

-- 原地清空 + 回填：SMODS 的 ObjectTypes[x] / rarity_pools 等可能持有同一张表的引用，
-- 直接赋值新表会让它们继续指向旧表（原版内容仍可能被 poll_object 取到）
local function refill(list, items)
    if not list then return end
    for i = #list, 1, -1 do list[i] = nil end
    for _, v in ipairs(items or {}) do list[#list + 1] = v end
end

local function refill_map(tbl, items)
    if not tbl then return end
    for k in pairs(tbl) do tbl[k] = nil end
    for k, v in pairs(items or {}) do tbl[k] = v end
end

local function joker_object_type()
    return SMODS.ObjectTypes and SMODS.ObjectTypes.Joker
end

local function snapshot()
    if ORIG then return end
    ORIG = {
        joker_rarity = {},
        pools = {},
        tags = copy_map(G.P_TAGS),
        blinds = copy_map(G.P_BLINDS),
        joker_rarity_pools = nil,
    }
    for i, v in ipairs(G.P_JOKER_RARITY_POOLS or {}) do ORIG.joker_rarity[i] = copy_array(v) end
    for _, k in ipairs(POOL_KEYS) do ORIG.pools[k] = copy_array(G.P_CENTER_POOLS[k]) end
    local jt = joker_object_type()
    if jt and jt.rarity_pools then
        ORIG.joker_rarity_pools = {}
        for k, v in pairs(jt.rarity_pools) do ORIG.joker_rarity_pools[k] = copy_array(v) end
    end
end

local function filter_pool(pool)
    local out = {}
    for _, v in ipairs(pool or {}) do
        if is_ours(v) then out[#out + 1] = v end
    end
    return out
end

local function index_only(pool)
    local out = {}
    for k, v in pairs(pool or {}) do
        if is_ours(v) then out[k] = v end
    end
    return out
end

-- 按稀有度把本模组小丑分组
local function ours_by_rarity(jokers)
    local out = { {}, {}, {}, {} }
    for _, v in ipairs(jokers or {}) do
        if is_ours(v) and not v.no_collection then
            local r = math.max(1, math.min(4, v.rarity or 1))
            table.insert(out[r], v)
        end
    end
    return out
end

------------------------------------------------------------------
-- 隔离（可重复调用，始终从 ORIG 原始快照过滤，因此幂等）
------------------------------------------------------------------
local function isolate()
    snapshot()

    -- ① 小丑：按稀有度重建（同时覆盖 vanilla 的 G.P_JOKER_RARITY_POOLS 与 SMODS 的 ObjectType.rarity_pools）
    local by_rarity = ours_by_rarity(ORIG.pools.Joker)
    for i = 1, math.max(#(G.P_JOKER_RARITY_POOLS or {}), 4) do
        if G.P_JOKER_RARITY_POOLS[i] then refill(G.P_JOKER_RARITY_POOLS[i], by_rarity[i]) end
    end
    local jt = joker_object_type()
    if jt and jt.rarity_pools then
        for k, list in pairs(jt.rarity_pools) do refill(list, by_rarity[k]) end
    end

    -- ② 中央池：只留本模组（过滤后为空则保持原样，避免空池兜底塞回原版卡）
    for _, k in ipairs(POOL_KEYS) do
        local filtered = filter_pool(ORIG.pools[k])
        if #filtered > 0 and G.P_CENTER_POOLS[k] then refill(G.P_CENTER_POOLS[k], filtered) end
    end

    -- ③ 标签
    refill_map(G.P_TAGS, index_only(ORIG.tags))

    -- ④ 盲注：保留小/大盲注（底注结构），替换全部 Boss
    local blinds = {}
    for k, v in pairs(ORIG.blinds or {}) do
        if k == 'bl_small' or k == 'bl_big' then
            blinds[k] = v
        elseif is_ours(v) then
            blinds[k] = v
        end
    end
    refill_map(G.P_BLINDS, blinds)

    -- ⑤ 主题池：收集界面用（SMODS.Jokers / SMODS.Consumables 在 26.829.0 并不存在，
    --    必须从实际池里收集）
    local theme = G.P_CENTER_POOLS['blh_zhongyan']
    if not theme then
        theme = {}
        G.P_CENTER_POOLS['blh_zhongyan'] = theme
    end
    local items = {}
    for _, list in ipairs(by_rarity) do
        for _, v in ipairs(list) do items[#items + 1] = v end
    end
    for _, v in ipairs(G.P_CENTER_POOLS.Tarot or {}) do items[#items + 1] = v end
    for _, v in ipairs(G.P_CENTER_POOLS.Spectral or {}) do items[#items + 1] = v end
    for _, v in ipairs(G.P_CENTER_POOLS.Voucher or {}) do items[#items + 1] = v end
    refill(theme, items)
end

------------------------------------------------------------------
-- G.GAME 级参数（必须在 init_game_object 之后设置，会被它重置）
------------------------------------------------------------------
local function fix_pre_rolls()
    -- init 阶段会掷出本回合的优惠券与"跳过盲注"标签；掷到非本模组内容时按隔离后的池重掷
    local round = G.GAME.current_round
    if round and round.voucher then
        local bad = false
        for _, key in ipairs(round.voucher) do
            if not is_ours(G.P_CENTERS[key]) then bad = true end
        end
        if bad then
            -- 只取无前置的基础优惠券，避免破坏 requires 链
            local pool = {}
            for _, v in ipairs(G.P_CENTER_POOLS.Voucher or {}) do
                if is_ours(v) and not v.requires then pool[#pool + 1] = v.key end
            end
            local ante = (G.GAME.round_resets and G.GAME.round_resets.ante) or 1
            local pick = #pool > 0 and pseudorandom_element(pool, pseudoseed('blh_voucher' .. tostring(ante))) or nil
            round.voucher = pick and { pick, spawn = { [pick] = true } } or {}
        end
    end
    local resets = G.GAME.round_resets
    if resets and resets.blind_tags then
        for _, slot in ipairs({ 'Small', 'Big' }) do
            local key = resets.blind_tags[slot]
            if key and not is_ours(G.P_TAGS[key]) then
                resets.blind_tags[slot] = get_next_tag_key()
            end
        end
    end
end

local function apply_run_params()
    if not (G.GAME and G.GAME.challenge == BLH.CHALLENGE_ID) then return end
    G.GAME.win_ante = 10                     -- 第 10 天终局（原版默认 8，会把天龙提前到第 8 天）
    G.GAME.planet_rate = 0                   -- 商店不再出现原版星球牌
    G.GAME.playing_card_rate = 0             -- 商店不再出现原版扑克
    G.GAME.modifiers = G.GAME.modifiers or {}
    G.GAME.modifiers.extra_boosters = 0
    if G.GAME.starting_params then G.GAME.starting_params.boosters_in_shop = 0 end
    apply_banned_keys()
    fix_pre_rolls()
end

------------------------------------------------------------------
-- 还原
------------------------------------------------------------------
local function restore()
    if not ORIG then return end
    for i, v in ipairs(ORIG.joker_rarity) do
        if G.P_JOKER_RARITY_POOLS[i] then refill(G.P_JOKER_RARITY_POOLS[i], v) end
    end
    local jt = joker_object_type()
    if jt and jt.rarity_pools and ORIG.joker_rarity_pools then
        for k, list in pairs(jt.rarity_pools) do refill(list, ORIG.joker_rarity_pools[k]) end
    end
    for _, k in ipairs(POOL_KEYS) do
        if G.P_CENTER_POOLS[k] then refill(G.P_CENTER_POOLS[k], ORIG.pools[k]) end
    end
    refill_map(G.P_TAGS, ORIG.tags)
    refill_map(G.P_BLINDS, ORIG.blinds)
end

BLH.restore_pools = restore

------------------------------------------------------------------
-- 开局额外道具：随机 1 张回响小丑 + $4
------------------------------------------------------------------
local function give_starting_joker(args)
    if args and args.savetext then return end
    if G.GAME.blh_started then return end
    G.GAME.blh_started = true
    G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.6, func = function()
        if G.jokers and #G.jokers.cards < G.jokers.config.card_limit then
            local card = create_card('Joker', G.jokers, nil, nil, nil, nil, nil, 'blh_start')
            card:add_to_deck()
            G.jokers:emplace(card)
        end
        return true
    end }))
end

local start_run_ref = Game.start_run
function Game:start_run(args)
    args = args or {}
    -- 隔离必须发生在 init_game_object 之前：本回合的优惠券、跳过标签、盲注都在那里按池掷出
    if args.challenge and args.challenge.id == BLH.CHALLENGE_ID then
        isolate()
    else
        restore()
    end
    start_run_ref(self, args)
    -- 读档进入挑战时 init_game_object 不再执行（G.GAME 来自存档），这里补隔离与参数
    if G.GAME.challenge == BLH.CHALLENGE_ID then
        isolate()
        apply_run_params()
        give_starting_joker(args)
    end
end

------------------------------------------------------------------
-- 挑战定义
------------------------------------------------------------------
SMODS.Challenge {
    key = 'zhongyan',
    loc_txt = {
        ['zh_CN'] = { name = '终焉之地' },
        ['en-us'] = { name = 'Ten Day Ultimatum' },
    },
    deck = { type = 'Challenge Deck' },
    rules = {
        -- 文档：rules.custom 写入 G.GAME.modifiers[id]；no_ui = true 表示不在挑战界面显示文案。
        -- 不带 no_ui 的会显示在「自定义规则」栏（localize 键 ch_c_<id>）。
        custom = {
            -- 「禁用原版」是本模式的核心规则，需要在规则栏里写明
            { id = 'blh_hardcore' },
            { id = 'enable_blh_memory', no_ui = true },
            { id = 'enable_blh_deep_echo', no_ui = true },
            { id = 'enable_blh_native', no_ui = true },
            { id = 'enable_blh_ant', no_ui = true },
            { id = 'enable_blh_mask', no_ui = true },
        },
        -- 文档支持：dollars / discards / hands / reroll_cost / joker_slots / consumable_slots / hand_size
        modifiers = {
            { id = 'dollars', value = 4 },
            { id = 'hands', value = 4 },
            { id = 'discards', value = 3 },
        },
    },
    jokers = {},
    consumeables = {},
    vouchers = {},
    -- 三个列表必须保持为空：
    -- 原版「限制条件」页会为 banned_cards 每一项创建卡牌精灵 Card(..., G.P_CENTERS[v.id])，
    -- 放标签/盲注（不在 G.P_CENTERS）会让 center 为 nil，崩在 card.lua:277；
    -- 放"全部原版卡"则有 600+ 项，页面要逐张画精灵，移动端不可行。
    -- 实际禁用统一在 apply_banned_keys() 里写 G.GAME.banned_keys（见文件上方注释）。
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {},
    },
}
