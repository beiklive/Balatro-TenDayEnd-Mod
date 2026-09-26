--- beiklive助手 v2 · 十日终焉「终焉之地」
--- 系统：道经济 + HUD + 挑战与池隔离
--- 内容：30 回响小丑 / 21 塔罗 / 10 幻灵 / 16 优惠券 / 16 标签 / 12 生肖盲注 / 5 版本 / 5 封印 / 5 贴纸
--- PREFIX: blh

local mod = SMODS.current_mod

-- 崩溃界面显示的信息（官方 Mod Object 文档：mod.debug_info）
mod.debug_info = {
    version = 'v2.3.6',
    mode = '终焉之地',
    content = '30 回响小丑 / 21 塔罗 / 10 幻灵 / 16 优惠券 / 16 标签 / 12 生肖盲注 / 5 版本 / 5 封印 / 5 贴纸',
}

-- 加载顺序重要：systems/economy.lua 必须先定义 mod.blh
local FILES = {
    'systems/economy.lua',
    'systems/pools.lua',
    'systems/debug.lua',
    'content/jokers.lua',
    'content/tarots.lua',
    'content/spectrals.lua',
    'content/vouchers.lua',
    'content/tags.lua',
    'content/blinds.lua',
    'content/editions.lua',
    'content/seals.lua',
    'content/stickers.lua',
}

for _, file in ipairs(FILES) do
    local chunk, err = SMODS.load_file(file)
    assert(chunk, err)
    chunk()
end

------------------------------------------------------------------
-- 设置页：起始金钱 / 出牌次数 / 弃牌次数
------------------------------------------------------------------
local DEFAULTS = { start_money = 4, hands = 4, discards = 3 }
local LIMITS = {
    start_money = { min = 0, max = 100 },
    hands       = { min = 1, max = 20 },
    discards    = { min = 0, max = 20 },
}

local base = { hands = nil, discards = nil }

local function clamp(key)
    local v = math.floor((tonumber(mod.config[key]) or DEFAULTS[key]) + 0.5)
    local lim = LIMITS[key]
    if v < lim.min then
        v = lim.min
    elseif v > lim.max then
        v = lim.max
    end
    mod.config[key] = v
end

local function clamp_all()
    for key in pairs(DEFAULTS) do clamp(key) end
end

clamp_all()

local persisted = {
    start_money = mod.config.start_money,
    hands = mod.config.hands,
    discards = mod.config.discards,
}

local get_starting_params_ref = get_starting_params
function get_starting_params()
    local params = get_starting_params_ref()
    clamp_all()
    params.dollars  = mod.config.start_money
    params.hands    = mod.config.hands
    params.discards = mod.config.discards
    base.hands, base.discards = mod.config.hands, mod.config.discards
    return params
end

local function sync_current_run()
    local game = G.GAME
    if not (game and game.starting_params and game.round_resets) then return end
    local resets = game.round_resets
    if base.hands then
        resets.hands = resets.hands + (mod.config.hands - base.hands)
    else
        resets.hands = mod.config.hands
    end
    if base.discards then
        resets.discards = resets.discards + (mod.config.discards - base.discards)
    else
        resets.discards = mod.config.discards
    end
    base.hands, base.discards = mod.config.hands, mod.config.discards
    game.starting_params.hands    = mod.config.hands
    game.starting_params.discards = mod.config.discards
    game.starting_params.dollars  = mod.config.start_money
    if G.STATE == G.STATES.BLIND_SELECT and game.current_round then
        game.current_round.hands_left = resets.hands
        game.current_round.discards_left = resets.discards
    end
end

function G.FUNCS.blh_config_changed()
    clamp_all()
    sync_current_run()
    if persisted.start_money ~= mod.config.start_money
        or persisted.hands ~= mod.config.hands
        or persisted.discards ~= mod.config.discards then
        persisted.start_money = mod.config.start_money
        persisted.hands = mod.config.hands
        persisted.discards = mod.config.discards
        SMODS.save_mod_config(mod)
    end
end

local function create_setting(key, label)
    local lim = LIMITS[key]
    return create_slider({
        label = label, w = 4, h = 0.4,
        ref_table = mod.config, ref_value = key,
        min = lim.min, max = lim.max,
        callback = 'blh_config_changed',
    })
end

local function create_note(key)
    return { n = G.UIT.R, config = { align = 'cm', padding = 0.02 }, nodes = {
        { n = G.UIT.T, config = { text = localize(key), scale = 0.25, colour = G.C.UI.TEXT_INACTIVE } },
    } }
end

mod.config_tab = function()
    return {
        n = G.UIT.ROOT,
        config = { align = 'cm', padding = 0.1, r = 0.1, colour = G.C.BLACK, minw = 6, minh = 4 },
        nodes = {
            { n = G.UIT.R, config = { align = 'cm', padding = 0.05 }, nodes = {
                { n = G.UIT.T, config = { text = localize('blh_title'), scale = 0.5, colour = G.C.UI.TEXT_LIGHT } },
            } },
            create_setting('start_money', localize('blh_start_money')),
            create_setting('hands', localize('blh_hands')),
            create_setting('discards', localize('blh_discards')),
            create_note('blh_note_1'),
            create_note('blh_note_2'),
            create_note('blh_note_3'),
            { n = G.UIT.R, config = { align = 'cm', padding = 0.1 }, nodes = {
                UIBox_button({
                    button = 'blh_unlock_all',
                    label = { localize('blh_unlock_btn') },
                    colour = G.C.PURPLE,
                    minw = 5,
                    minh = 0.6,
                }),
            } },
        },
    }
end
