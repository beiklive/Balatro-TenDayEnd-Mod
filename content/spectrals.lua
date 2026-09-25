--- 终焉之地 · 10 张幻灵
--- 旧 5（小丑与负片）+ 五城 5（手牌与轮回）
--- 图集：5 列 × 2 行

SMODS.Atlas { key = 'blh_spectral', path = 'blh_spectral.png', px = 71, py = 95 }

local function loc(zh_name, en_name, zh_text, en_text)
    return { ['zh_CN'] = { name = zh_name, text = zh_text }, ['en-us'] = { name = en_name, text = en_text } }
end

local function is_negative(card) return card.edition ~= nil and card.edition.negative == true end

local function eligible_jokers(allow_eternal)
    local list = {}
    for _, joker in ipairs((G.jokers and G.jokers.cards) or {}) do
        if not is_negative(joker) and (allow_eternal or not joker.ability.eternal) then
            list[#list + 1] = joker
        end
    end
    return list
end

local function most_valuable()
    local best
    for _, j in ipairs(eligible_jokers(true)) do
        if not best or (j.sell_cost or 0) > (best.sell_cost or 0) then best = j end
    end
    return best
end

local function least_valuable()
    local worst
    for _, j in ipairs(eligible_jokers(false)) do
        if not worst or (j.sell_cost or 0) < (worst.sell_cost or 0) then worst = j end
    end
    return worst
end

local ENHANCEMENTS = { 'm_bonus', 'm_mult', 'm_wild', 'm_glass', 'm_steel', 'm_stone', 'm_gold', 'm_lucky' }

local function hand_card_count() return (G.hand and #G.hand.cards) or 0 end

-- 记录本局使用过的消耗品（玉城·记忆 需要）
local use_consumeable_ref = Card.use_consumeable
function Card:use_consumeable(area, copier)
    local ret = use_consumeable_ref(self, area, copier)
    -- 只在真正用掉（非复制触发）时记录；放在原函数之后，避免把被拒绝使用/被 debuff 的牌也算进去
    if not copier and G.GAME and not self.debuff then
        G.GAME.blh_used_consumables = G.GAME.blh_used_consumables or {}
        local key = self.config and self.config.center and self.config.center.key
        if key then
            table.insert(G.GAME.blh_used_consumables, key)
            while #G.GAME.blh_used_consumables > 10 do table.remove(G.GAME.blh_used_consumables, 1) end
        end
    end
    return ret
end

--==============================================================
-- 旧 5
--==============================================================

SMODS.Consumable {
    key = 'doppelganger', set = 'Spectral', atlas = 'blh_spectral', pos = { x = 0, y = 0 }, cost = 4, discovered = true,
    config = {},
    loc_txt = loc('二重身', 'Doppelgänger',
        { '复制价值最高的{C:attention}小丑牌{}', '复制品为{C:dark_edition}负片{}', '{C:inactive}（全部小丑均为负片时无法使用）' },
        { 'Creates a {C:dark_edition}Negative{} copy of', 'your most valuable {C:attention}Joker{}', '{C:inactive}(unusable when every Joker is Negative)' }),
    loc_vars = function(self, iq) iq[#iq + 1] = G.P_CENTERS.e_negative end,
    can_use = function(self, card) return #eligible_jokers(true) > 0 end,
    use = function(self, card, area, copier)
        local target = most_valuable()
        if not target then return end
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.4, func = function()
            local copy = copy_card(target, nil, nil, nil, true)
            copy:start_materialize()
            copy:add_to_deck()
            copy:set_edition('e_negative', true)
            G.jokers:emplace(copy)
            return true
        end }))
        SMODS.calculate_effect({ message = localize('k_duplicated_ex') }, card)
        delay(0.6)
    end,
}

SMODS.Consumable {
    key = 'antimatter', set = 'Spectral', atlas = 'blh_spectral', pos = { x = 1, y = 0 }, cost = 4, discovered = true,
    config = {},
    loc_txt = loc('反物质', 'Antimatter',
        { '将所有已拥有的{C:attention}小丑牌{}', '变为{C:dark_edition}负片{}', '{C:inactive}（会覆盖已有的其他版本）' },
        { 'Turns all owned {C:attention}Jokers{}', '{C:dark_edition}Negative{}', '{C:inactive}(overwrites other editions)' }),
    loc_vars = function(self, iq) iq[#iq + 1] = G.P_CENTERS.e_negative end,
    can_use = function(self, card) return #eligible_jokers(true) > 0 end,
    use = function(self, card, area, copier)
        local targets = eligible_jokers(true)
        for i = 1, #targets do
            local joker = targets[i]
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.12, func = function()
                joker:set_edition('e_negative', true)
                return true
            end }))
        end
        delay(0.4)
    end,
}

SMODS.Consumable {
    key = 'offering', set = 'Spectral', atlas = 'blh_spectral', pos = { x = 2, y = 0 }, cost = 4, discovered = true,
    config = { extra = { mult = 3 } },
    loc_txt = loc('献祭', 'Offering',
        { '摧毁价值最低的可摧毁小丑', '获得其售价 {C:money}×#1#{} 的金钱', '{C:inactive}（永恒小丑无法被献祭）' },
        { 'Destroys your least valuable Joker', 'Earn {C:money}#1#×{} its sell value', '{C:inactive}(Eternal Jokers are spared)' }),
    loc_vars = function(self, iq) return { vars = { self.config.extra.mult } } end,
    can_use = function(self, card) return #eligible_jokers(false) > 0 end,
    use = function(self, card, area, copier)
        local target = least_valuable()
        if not target then return end
        local gain = math.max(1, math.floor((target.sell_cost or 0) * self.config.extra.mult))
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.3, func = function()
            SMODS.destroy_cards(target)
            ease_dollars(gain)
            return true
        end }))
        delay(0.6)
    end,
}

SMODS.Consumable {
    key = 'entropy', set = 'Spectral', atlas = 'blh_spectral', pos = { x = 3, y = 0 }, cost = 4, discovered = true,
    config = {},
    loc_txt = loc('熵增', 'Entropy',
        { '手中所有牌变为随机{C:attention}强化牌{}', '{C:inactive}（保留点数与花色）' },
        { 'Turns every card in hand into a random {C:attention}Enhancement{}', '{C:inactive}(rank and suit are kept)' }),
    can_use = function(self, card) return hand_card_count() > 0 end,
    use = function(self, card, area, copier)
        local targets = {}
        for _, c in ipairs(G.hand.cards) do targets[#targets + 1] = c end
        for i = 1, #targets do
            local c = targets[i]
            local key = pseudorandom_element(ENHANCEMENTS, pseudoseed('blh_entropy' .. i .. (c.sort_id or 0)))
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.1, func = function()
                c:set_ability(G.P_CENTERS[key])
                c:juice_up(0.3, 0.3)
                return true
            end }))
        end
        delay(0.4)
    end,
}

SMODS.Consumable {
    key = 'echo', set = 'Spectral', atlas = 'blh_spectral', pos = { x = 4, y = 0 }, cost = 4, discovered = true,
    config = {},
    loc_txt = loc('回声', 'Echo',
        { '返还本回合已用掉的{C:attention}出牌次数{}', '{C:inactive}（未用掉出牌次数时无法使用）' },
        { 'Refunds every {C:attention}Hand{} played this round', '{C:inactive}(unusable if no Hand was spent)' }),
    can_use = function(self, card)
        return G.GAME ~= nil and G.GAME.current_round ~= nil and G.GAME.round_resets ~= nil
            and G.GAME.current_round.hands_left < G.GAME.round_resets.hands
    end,
    use = function(self, card, area, copier)
        local refund = G.GAME.round_resets.hands - G.GAME.current_round.hands_left
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.4, func = function()
            play_sound('timpani')
            card:juice_up(0.3, 0.5)
            ease_hands_played(refund)
            return true
        end }))
        delay(0.6)
    end,
}

--==============================================================
-- 五城
--==============================================================

-- 道城·轮回：返还所有已消耗次数
SMODS.Consumable {
    key = 'daocheng_cycle', set = 'Spectral', atlas = 'blh_spectral', pos = { x = 0, y = 1 }, cost = 4, discovered = true,
    config = {},
    loc_txt = loc('道城·轮回', 'Daocheng: Samsara',
        { '返还本回合已消耗的{C:attention}出牌次数{}与{C:attention}弃牌次数{}', '{C:inactive}（本回合没消耗过时无法使用）' },
        { 'Refunds the {C:attention}Hands{} and {C:attention}Discards{} spent this round', '{C:inactive}(unusable if you have not spent any this round)' }),
    can_use = function(self, card)
        if not (G.GAME and G.GAME.current_round and G.GAME.round_resets) then return false end
        return G.GAME.current_round.hands_left < G.GAME.round_resets.hands
            or G.GAME.current_round.discards_left < G.GAME.round_resets.discards
    end,
    use = function(self, card, area, copier)
        local dh = G.GAME.round_resets.hands - G.GAME.current_round.hands_left
        local dd = G.GAME.round_resets.discards - G.GAME.current_round.discards_left
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.4, func = function()
            play_sound('timpani')
            if dh > 0 then ease_hands_played(dh) end
            if dd > 0 then ease_discard(dd) end
            return true
        end }))
        delay(0.6)
    end,
}

-- 玉城·记忆：恢复已用消耗品
SMODS.Consumable {
    key = 'yucheng_memory', set = 'Spectral', atlas = 'blh_spectral', pos = { x = 1, y = 1 }, cost = 4, discovered = true,
    config = {},
    loc_txt = loc('玉城·记忆', 'Yucheng: Memory',
        { '从本局已使用的最后 {C:attention}3{} 张消耗品中', '随机恢复 {C:attention}1{} 张', '{C:inactive}（需本局用过消耗品，且消耗品区有空位）' },
        { 'Recovers {C:attention}1{} random consumable from the', 'last {C:attention}3{} you used this run', '{C:inactive}(needs a used consumable and a free consumable slot)' }),
    can_use = function(self, card)
        local used = G.GAME and G.GAME.blh_used_consumables
        return used ~= nil and #used > 0 and #G.consumeables.cards < G.consumeables.config.card_limit
    end,
    use = function(self, card, area, copier)
        local used = G.GAME.blh_used_consumables
        local pool = {}
        for i = math.max(1, #used - 2), #used do pool[#pool + 1] = used[i] end
        local key = pseudorandom_element(pool, pseudoseed('blh_yucheng' .. tostring(G.GAME.round or 0)))
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.4, func = function()
            local c = create_card('Consumeables', G.consumeables, nil, nil, nil, nil, key, 'blh_yu')
            c:add_to_deck()
            G.consumeables:emplace(c)
            return true
        end }))
        delay(0.6)
    end,
}

-- 涡城·漩涡：手牌洗回重抽
SMODS.Consumable {
    key = 'wocheng_vortex', set = 'Spectral', atlas = 'blh_spectral', pos = { x = 2, y = 1 }, cost = 4, discovered = true,
    config = {},
    loc_txt = loc('涡城·漩涡', 'Wocheng: Vortex',
        { '把手牌全部洗回牌堆', '然后重抽等量的牌', '{C:inactive}（需至少有 1 张手牌）' },
        { 'Shuffles your whole hand back into the deck', 'then draws the same number of cards', '{C:inactive}(needs at least 1 card in hand)' }),
    can_use = function(self, card) return hand_card_count() > 0 end,
    use = function(self, card, area, copier)
        local n = hand_card_count()
        local cards = {}
        for _, c in ipairs(G.hand.cards) do cards[#cards + 1] = c end
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.3, func = function()
            for _, c in ipairs(cards) do
                G.hand:remove_card(c)
                G.deck:emplace(c)
            end
            G.deck:shuffle()
            for _ = 1, n do
                if #G.deck.cards > 0 then
                    local c = G.deck.cards[#G.deck.cards]
                    G.deck:remove_card(c)
                    G.hand:emplace(c)
                end
            end
            play_sound('whoosh2')
            return true
        end }))
        delay(0.7)
    end,
}

-- 勾城·契约：风险与奖励翻倍
SMODS.Consumable {
    key = 'goucheng_pact', set = 'Spectral', atlas = 'blh_spectral', pos = { x = 3, y = 1 }, cost = 4, discovered = true,
    config = { extra = { penalty = 0.5, reward = 2 } },
    loc_txt = loc('勾城·契约', 'Goucheng: Contract',
        { '与本盲注签约：所需分数 {C:red}+#1#{}', '击败该盲注时，获得的{C:attention}道{} {C:money}×#2#{}', '{C:inactive}（只能在小盲注 / 大盲注时使用，Boss 盲注不可用）' },
        { 'Sign a contract with this Blind: it needs {C:red}+#1#{} score', 'defeating it grants {C:money}×#2#{} the usual {C:attention}Dao{}', '{C:inactive}(only usable on Small / Big Blinds, not on Boss Blinds)' }),
    loc_vars = function(self, iq)
        return { vars = { tostring(self.config.extra.penalty * 100) .. '%', self.config.extra.reward } }
    end,
    can_use = function(self, card)
        return G.GAME ~= nil and G.GAME.blind ~= nil and not G.GAME.blind.boss
    end,
    use = function(self, card, area, copier)
        -- 契约绑定到"当前这个盲注"，而不是只记 ante
        G.GAME.blh_pact_ante = G.GAME.round_resets.ante
        G.GAME.blh_pact_blind = G.GAME.blind and G.GAME.blind.config
            and G.GAME.blind.config.blind and G.GAME.blind.config.blind.key or nil
        if G.GAME.blind and G.GAME.blind.chips then
            G.GAME.blind.chips = G.GAME.blind.chips * (1 + self.config.extra.penalty)
            G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
        end
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.3, func = function()
            play_sound('tarot1')
            attention_text({ text = localize('blh_pact_signed'), scale = 1.2, hold = 1.4, major = G.GAME.blind, backdrop_colour = G.C.GOLD, align = 'cm', silent = true })
            return true
        end }))
        delay(0.6)
    end,
}

-- 索城·索引：按点数检索
SMODS.Consumable {
    key = 'suocheng_index', set = 'Spectral', atlas = 'blh_spectral', pos = { x = 4, y = 1 }, cost = 4, discovered = true,
    config = {},
    loc_txt = loc('索城·索引', 'Suocheng: Index',
        { '把牌堆中与手中{C:attention}点数最高{}的牌同点数的牌', '全部加入手牌', '{C:inactive}（需手牌有空位、牌堆里有同点数牌）' },
        { 'Adds every card in your deck that shares the rank of', 'the {C:attention}highest-ranked{} card in your hand', '{C:inactive}(needs a free slot and a matching card in the deck)' }),
    can_use = function(self, card)
        if hand_card_count() == 0 or #G.hand.cards >= G.hand.config.card_limit then return false end
        local top
        for _, c in ipairs(G.hand.cards) do if not top or c.base.id > top.base.id then top = c end end
        if not top then return false end
        for _, c in ipairs(G.deck.cards) do if c.base.id == top.base.id then return true end end
        return false
    end,
    use = function(self, card, area, copier)
        local top
        for _, c in ipairs(G.hand.cards) do if not top or c.base.id > top.base.id then top = c end end
        local pool = {}
        for _, c in ipairs(G.deck.cards) do if c.base.id == top.base.id then pool[#pool + 1] = c end end
        for _, c in ipairs(pool) do
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.08, func = function()
                if #G.hand.cards < G.hand.config.card_limit then
                    G.deck:remove_card(c)
                    G.hand:emplace(c)
                    c:juice_up(0.3, 0.3)
                end
                return true
            end }))
        end
        delay(0.5)
    end,
}
