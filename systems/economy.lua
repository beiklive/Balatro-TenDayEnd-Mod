--- 终焉之地 · 金钱经济系统
--- 规则：金钱奖励仅由击败盲注额外产出（走原版 ease_dollars，HUD 直接可见）；
---       性能奖励封顶；赌命消耗金钱；天龙强度随持有金钱提升

local mod = SMODS.current_mod
local BLH = {}
mod.blh = BLH

BLH.CHALLENGE_ID = 'blh_zhongyan'
BLH.JOKER_PREFIX = 'blh_'
BLH.GAMBLE_COST = { 20, 35, 55 }
-- 持有金钱 ≥ 该值时天龙提前降临
BLH.EARLY_MONEY = 250
-- 每持有这么多金钱，天龙强度 +10%
BLH.DRAGON_PER = 25

------------------------------------------------------------------
-- 基础读写（道已并入金钱：一律用原版 G.GAME.dollars / ease_dollars）
------------------------------------------------------------------
function BLH.money()
    return (G.GAME and G.GAME.dollars) or 0
end

function BLH.in_challenge()
    return G.GAME ~= nil and G.GAME.challenge == BLH.CHALLENGE_ID
end

------------------------------------------------------------------
-- 基础产出公式
------------------------------------------------------------------
-- 数值按"金钱经济"重新定标（原道经济数值的 1/5 ~ 1/8，
-- 因为原版金钱的稀缺度远高于道；原值见 AUDIT/DESIGN 的历史记录）
function BLH.small_reward(ante) return 3 + math.floor(ante / 2) end
function BLH.big_reward(ante) return 5 + ante end

function BLH.boss_reward(ante)
    if ante <= 3 then
        return 12      -- 人级
    elseif ante <= 7 then
        return 20      -- 地级
    elseif ante <= 9 then
        return 30      -- 天级
    end
    return 50          -- 天龙
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
-- 结算：击败盲注时额外给钱
------------------------------------------------------------------
function BLH.settle_blind(blind)
    if not BLH.in_challenge() then return end
    if not (blind and blind.get_type) then return end

    local ante = G.GAME.round_resets.ante
    local kind = blind:get_type()

    -- 幂等：Blind:defeat 可能被重复调用（例如中途读档），奖励不能重复发。
    -- 关键：G.GAME.blind 整局只创建一次（device game.lua:2522），
    -- 而 Blind:set_blind（blind.lua:99-135）只重置固定字段、**不会清自定义字段**
    -- → 标记若挂在 blind 对象上会跨盲注残留，导致第 2 个盲注起再也不发奖。
    -- 改成记在 G.GAME（按 ante + 盲注 key 区分，且随存档保留）。
    local blind_key = blind.config and blind.config.blind and blind.config.blind.key or nil
    local marker = tostring(ante) .. ':' .. tostring(blind_key or kind)
    G.GAME.blh_settled = G.GAME.blh_settled or {}
    if G.GAME.blh_settled[marker] then return end
    G.GAME.blh_settled[marker] = true

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
    total = total + (G.GAME.current_round.hands_left or 0)
    total = total + (G.GAME.current_round.discards_left or 0)

    -- 勾城·契约：只对签约的那个盲注生效（按 ante + 盲注 key 匹配）
    if G.GAME.blh_pact_ante == ante and G.GAME.blh_pact_blind == blind_key then
        total = total * 2
    end
    G.GAME.blh_pact_ante, G.GAME.blh_pact_blind = nil, nil

    -- 走原版 money 通道：HUD 金额直接变化并弹「+$N」（instant=true 跳过缓动）
    ease_dollars(total, true)
    BLH.check_early()

    return total
end

-- 持有金钱 ≥ EARLY_MONEY：天龙提前降临（提前结局）
function BLH.check_early()
    if BLH.money() < BLH.EARLY_MONEY or G.GAME.blh_dragon_early then return end
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

-- 天龙强度随持有金钱提升：每 DRAGON_PER 金钱 +10%（不设上限：钱越多越难）
function BLH.dragon_mult()
    return 1 + math.floor(BLH.money() / BLH.DRAGON_PER) * 0.1
end

------------------------------------------------------------------
-- 赌命（花得起 GAMBLE_COST 就免死一次，费用递增）
------------------------------------------------------------------
function BLH.gamble_count()
    return (G.GAME and G.GAME.blh_gamble) or 0
end

function BLH.gamble_cost()
    local n = BLH.gamble_count() + 1
    return BLH.GAMBLE_COST[math.min(n, #BLH.GAMBLE_COST)]
end

function BLH.can_gamble()
    return BLH.in_challenge() and BLH.money() >= BLH.gamble_cost()
end

function BLH.do_gamble()
    local cost = BLH.gamble_cost()
    ease_dollars(-cost, true)
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

-- 死亡结算：免死充能 → 不灭（免费）→ 赌命（消耗金钱）
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
-- 同时也处理「白虎·调停」挂起的解除盲注限制（需要 setting_blind 时机）
mod.calculate = function(self, context)
    if not context then return end
    -- 白虎·调停：跳过盲注时挂起，等下一个盲注 set_blind 之后再解除它的限制
    if context.setting_blind and G.GAME and G.GAME.blh_break_blind then
        -- 只在 Boss 盲注消费：标签是跳盲拿到的，下一个盲注往往是大盲注（没有可解除的限制），
        -- 先清标记会让标签白白消耗
        if G.GAME.blind and G.GAME.blind.boss then
            G.GAME.blh_break_blind = nil
            G.GAME.blind:disable()
            return { message = localize('k_disabled_ex'), colour = G.C.RED }
        end
        return
    end
    if not context.end_of_round then return end
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

-- 说明：原「道」HUD 补丁已删除。金钱是本模组唯一的产出资源，
-- 原版 HUD 的 $ 计数就是唯一显示入口（不再自绘计数器，也就没有显示不出来的问题）。

------------------------------------------------------------------
-- 初始化与结算挂载
------------------------------------------------------------------
local init_game_object_ref = Game.init_game_object
function Game:init_game_object()
    local ret = init_game_object_ref(self)
    ret.blh_gamble = 0
    ret.blh_settled = {}
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

--- 内容文件给钱请直接 ease_dollars(n)（或在自己的 calculate 里 return { dollars = n }）。
--- 注意：不要往 SMODS 全局表挂自己的函数（污染 SMODS 命名空间，可能与未来版本冲突）。

return BLH
