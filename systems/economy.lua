--- 终焉之地 · 道 经济系统
--- 规则：道仅由击败盲注产出；性能奖励封顶；唯一消耗是赌命；天龙强度随道提升

local mod = SMODS.current_mod
local BLH = {}
mod.blh = BLH

BLH.CHALLENGE_ID = 'blh_zhongyan'
BLH.JOKER_PREFIX = 'blh_'
BLH.GAMBLE_COST = { 500, 800, 1200 }
BLH.EARLY_DAO = 3600

------------------------------------------------------------------
-- 基础读写
------------------------------------------------------------------
function BLH.dao()
    return (G.GAME and G.GAME.blh_dao) or 0
end

function BLH.add_dao(n)
    if not (G.GAME and G.GAME.blh_dao) then return end
    G.GAME.blh_dao = math.max(0, G.GAME.blh_dao + n)
end

function BLH.in_challenge()
    return G.GAME ~= nil and G.GAME.challenge == BLH.CHALLENGE_ID
end

------------------------------------------------------------------
-- 基础产出公式
------------------------------------------------------------------
function BLH.small_reward(ante) return 10 + 5 * ante end
function BLH.big_reward(ante) return 20 + 8 * ante end

function BLH.boss_reward(ante)
    if ante <= 3 then
        return 80      -- 人级
    elseif ante <= 7 then
        return 130     -- 地级
    elseif ante <= 9 then
        return 200     -- 天级
    end
    return 400         -- 天龙
end

-- 超额分数档位（封顶 +40%，反通胀第二道闸）
function BLH.overkill_mult(ratio)
    if ratio >= 6 then
        return 1.40
    elseif ratio >= 3 then
        return 1.25
    elseif ratio >= 1.5 then
        return 1.10
    end
    return 1.00
end

------------------------------------------------------------------
-- 结算：击败盲注时给道
------------------------------------------------------------------
function BLH.settle_blind(blind)
    if not BLH.in_challenge() then return end
    if not (blind and blind.get_type) then return end
    -- 幂等：Blind:defeat 有可能被重复调用（例如中途读档），道不能重复发
    if blind.blh_settled then return end
    blind.blh_settled = true

    local ante = G.GAME.round_resets.ante
    local kind = blind:get_type()
    local base
    if kind == 'Boss' then
        base = BLH.boss_reward(ante)
    elseif kind == 'Big' then
        base = BLH.big_reward(ante)
    else
        base = BLH.small_reward(ante)
    end

    local ratio = 1
    if G.GAME.blind and G.GAME.blind.chips and G.GAME.blind.chips > 0 then
        ratio = G.GAME.chips / G.GAME.blind.chips
    end

    local total = math.floor(base * BLH.overkill_mult(ratio))
    total = total + (G.GAME.current_round.hands_left or 0) * 4
    total = total + (G.GAME.current_round.discards_left or 0) * 3

    -- 勾城·契约：只对签约的那个盲注生效（按 ante + 盲注 key 匹配）
    local blind_key = blind.config and blind.config.blind and blind.config.blind.key or nil
    if G.GAME.blh_pact_ante == ante and G.GAME.blh_pact_blind == blind_key then
        total = total * 2
    end
    G.GAME.blh_pact_ante, G.GAME.blh_pact_blind = nil, nil

    BLH.add_dao(total)
    BLH.announce(total)
    BLH.check_early()

    return total
end

function BLH.announce(total)
    G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
        attention_text({
            text = '+' .. tostring(total) .. ' ' .. localize('blh_dao_name'),
            scale = 1.1,
            hold = 1.2,
            major = G.GAME.blind,
            backdrop_colour = G.C.GOLD,
            align = 'cm',
            offset = { x = 0, y = -0.3 },
            silent = true,
        })
        play_sound('coin2', 1.1, 0.5)
        return true
    end }))
end

-- 道 ≥ 3600：天龙提前降临（提前结局）
function BLH.check_early()
    if BLH.dao() < BLH.EARLY_DAO or G.GAME.blh_dragon_early then return end
    if G.GAME.won then return end   -- 已经通关就不再改底注
    G.GAME.blh_dragon_early = true
    local ante = G.GAME.round_resets.ante
    if ante < G.GAME.win_ante then
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 1.4, func = function()
            attention_text({
                text = localize('blh_dragon_descend'),
                scale = 1.3,
                hold = 2,
                backdrop_colour = G.C.RED,
                align = 'cm',
                silent = true,
            })
            ease_ante(G.GAME.win_ante - G.GAME.round_resets.ante)
            return true
        end }))
    end
end

-- 天龙强度随道提升：每 500 道 +10%
function BLH.dragon_mult()
    return 1 + math.floor(BLH.dao() / 500) * 0.1
end

------------------------------------------------------------------
-- 赌命（道 ≥ 500 免死）
------------------------------------------------------------------
function BLH.gamble_count()
    return (G.GAME and G.GAME.blh_gamble) or 0
end

function BLH.gamble_cost()
    local n = BLH.gamble_count() + 1
    return BLH.GAMBLE_COST[math.min(n, #BLH.GAMBLE_COST)]
end

function BLH.can_gamble()
    return BLH.in_challenge() and BLH.dao() >= BLH.gamble_cost()
end

function BLH.do_gamble()
    local cost = BLH.gamble_cost()
    BLH.add_dao(-cost)
    G.GAME.blh_gamble = BLH.gamble_count() + 1
    G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.1, func = function()
        attention_text({
            text = localize('blh_gamble_ex'),
            scale = 1.3,
            hold = 1.6,
            backdrop_colour = G.C.PURPLE,
            align = 'cm',
            silent = true,
        })
        play_sound('timpani')
        return true
    end }))
    return true
end

------------------------------------------------------------------
-- 不灭（小丑）与赌命的免死入口
-- 走原版 Mr. Bones 的 saved 机制（已核对 state_events.lua: eval.saved → game_over = false）
------------------------------------------------------------------
-- 26.829.0 起 end_round 走 SMODS.calculate_context（不再逐个 calculate_joker），
-- 因此免死必须由 calculate 函数据返回 saved 实现：
--   ① mod.calculate —— 处理免死充能 / 不灭（有则优先）/ 赌命
--   ② 不灭小丑自身的 calculate —— 兜底（若某版本未派发 mod 计算）
local function try_revive_charge()
    if (G.GAME.blh_save_charges or 0) > 0 then
        G.GAME.blh_save_charges = G.GAME.blh_save_charges - 1
        attention_text({ text = localize('blh_fair_saved'), scale = 1.2, hold = 1.4, backdrop_colour = G.C.BLUE, align = 'cm', silent = true })
        return true
    end
    return false
end

local function try_revive_bumie()
    for _, joker in ipairs((G.jokers and G.jokers.cards) or {}) do
        local center = joker.config and joker.config.center
        if center and center.key == 'j_blh_bu_mie' and not joker.ability.extra.used then
            joker.ability.extra.used = true
            G.hand:change_size(-1)
            G.E_MANAGER:add_event(Event({ func = function()
                joker:juice_up(0.5, 0.5)
                attention_text({ text = localize('blh_bumie_ex'), scale = 1.2, hold = 1.4, major = joker, backdrop_colour = G.C.BLUE, align = 'cm', silent = true })
                return true
            end }))
            return true
        end
    end
    return false
end

-- 死亡结算：免死充能 → 不灭（免费）→ 赌命（消耗道）
function BLH.try_revive()
    if not BLH.in_challenge() then return false end
    if G.GAME.blh_saved_round then return false end
    if try_revive_charge() then return true end
    if try_revive_bumie() then return true end
    if BLH.can_gamble() then
        BLH.do_gamble()
        return true
    end
    return false
end

-- mod 级计算：26.829.0 的免死入口（end_round → SMODS.calculate_context → SMODS.saved）
mod.calculate = function(self, context)
    if not (context and context.end_of_round) then return end
    -- 每回合复位：否则救过一次后整局都触发不了
    if not context.game_over then
        G.GAME.blh_saved_round = nil
        return
    end
    if BLH.try_revive() then
        G.GAME.blh_saved_round = true
        SMODS.saved = true
        return { saved = true }
    end
end

-- HUD：道 计数器
------------------------------------------------------------------
local create_hud_ref = create_UIBox_HUD
function create_UIBox_HUD()
    local hud = create_hud_ref()
    if BLH.in_challenge() then
        table.insert(hud.nodes, {
            n = G.UIT.O,
            config = {
                object = DynaText({
                    string = { { ref_table = G.GAME, ref_value = 'blh_dao', prefix = localize('blh_dao_name') .. ': ' } },
                    colours = { G.C.GOLD },
                    scale = 0.45,
                    shadow = true,
                    pop_in = 0,
                    non_recalc = true,
                }),
                align = 'tm',
                offset = { x = 0, y = 0.7 },
                major = G.ROOM_ATTACH,
            },
        })
    end
    return hud
end

------------------------------------------------------------------
-- 初始化与结算挂载
------------------------------------------------------------------
local init_game_object_ref = Game.init_game_object
function Game:init_game_object()
    local ret = init_game_object_ref(self)
    ret.blh_dao = 0
    ret.blh_gamble = 0
    ret.blh_dragon_early = false
    ret.blh_pact_ante = nil
    ret.blh_pact_blind = nil
    ret.blh_saved_round = nil
    ret.blh_save_charges = 0
    return ret
end

local blind_defeat_ref = Blind.defeat
function Blind:defeat(silent)
    blind_defeat_ref(self, silent)
    BLH.settle_blind(self)
end

--- 供其他内容文件使用：给道（标签/封印等）
function SMODS.blh_add_dao(n)
    BLH.add_dao(n)
end

return BLH
