--- 终焉之地 · 21 张塔罗
--- 基础层 5 + 十二生肖 12（全部处理花色）+ 四神兽 4（确定性单花色转化）
--- 图集：7 列 × 3 行

SMODS.Atlas { key = 'blh_tarot', path = 'blh_tarot.png', px = 71, py = 95 }

local function loc(zh_name, en_name, zh_text, en_text)
    return { ['zh_CN'] = { name = zh_name, text = zh_text }, ['en-us'] = { name = en_name, text = en_text } }
end

local SUITS = { 'Spades', 'Hearts', 'Clubs', 'Diamonds' }
local RANK_KEY = { [2]='2',[3]='3',[4]='4',[5]='5',[6]='6',[7]='7',[8]='8',[9]='9',[10]='T',[11]='J',[12]='Q',[13]='K',[14]='A' }

local function suit_of(card)
    for _, s in ipairs(SUITS) do
        if card:is_suit(s) then return s end
    end
    return nil
end

local function suit_counts()
    local counts = { Spades = 0, Hearts = 0, Clubs = 0, Diamonds = 0 }
    for _, c in ipairs(G.hand.cards) do
        local s = suit_of(c)
        if s then counts[s] = counts[s] + 1 end
    end
    return counts
end

-- 并列时按固定顺序取，避免每次随机
local function pick_suit(counts, want_max)
    local best = SUITS[1]
    for _, s in ipairs(SUITS) do
        if want_max then
            if counts[s] > counts[best] then best = s end
        else
            if counts[s] < counts[best] then best = s end
        end
    end
    return best
end

local function hand_card_count() return (G.hand and #G.hand.cards) or 0 end
local function highlighted() return (G.hand and G.hand.highlighted) or {} end

local function head_start(card)
    G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.4, func = function()
        play_sound('tarot1')
        card:juice_up(0.3, 0.5)
        return true
    end }))
end

local function unhighlight()
    G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.25, func = function()
        G.hand:unhighlight_all()
        return true
    end }))
end

local function each_hand_card(fn, delay_each)
    local cards = {}
    for _, c in ipairs(G.hand.cards) do cards[#cards + 1] = c end
    for i = 1, #cards do
        local c = cards[i]
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = delay_each or 0.08, func = function()
            fn(c, i)
            c:juice_up(0.3, 0.3)
            return true
        end }))
    end
end

--==============================================================
-- 基础层（5）
--==============================================================

SMODS.Consumable {
    key = 'dominion', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 0, y = 0 }, cost = 4, discovered = true,
    config = { max_highlighted = 2 },
    loc_txt = loc('权柄', 'The Dominion',
        { '将选中的 {C:attention}1~2{} 张手牌点数变为 {C:attention}A{}', '{C:inactive}（至少选中 1 张，至多 2 张）' },
        { 'Turns the selected {C:attention}1~2{} cards into {C:attention}Aces{}', '{C:inactive}(select at least 1 card, up to 2)' }),
    can_use = function(self, card) return G.hand ~= nil and #highlighted() > 0 end,
    use = function(self, card, area, copier)
        local targets = {}
        for i = 1, math.min(#highlighted(), self.config.max_highlighted) do targets[#targets + 1] = highlighted()[i] end
        head_start(card)
        for _, t in ipairs(targets) do
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.12, func = function()
                SMODS.change_base(t, nil, 'A')
                play_sound('tarot2')
                t:juice_up(0.3, 0.3)
                return true
            end }))
        end
        unhighlight()
        delay(0.6)
    end,
}

SMODS.Consumable {
    key = 'mirror', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 1, y = 0 }, cost = 4, discovered = true,
    config = { max_highlighted = 1 },
    loc_txt = loc('镜像', 'The Mirror',
        { '复制选中的 {C:attention}1{} 张手牌', '复制品保留其{C:attention}强化 / 版本 / 蜡封{}', '{C:inactive}（需手牌有空位）' },
        { 'Copies {C:attention}1{} selected card', 'the copy keeps its {C:attention}Enhancement / Edition / Seal{}', '{C:inactive}(needs a free hand slot)' }),
    can_use = function(self, card)
        return G.hand ~= nil and #highlighted() == 1 and #G.hand.cards < G.hand.config.card_limit
    end,
    use = function(self, card, area, copier)
        local target = highlighted()[1]
        head_start(card)
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
            G.playing_card = (G.playing_card and G.playing_card + 1) or 1
            local new_card = copy_card(target, nil, nil, G.playing_card)
            new_card:add_to_deck()
            table.insert(G.playing_cards, new_card)
            G.hand:emplace(new_card)
            new_card:start_materialize()
            -- 与原版 Certificate 一致：新手牌立刻吃盲注 debuff、排序并触发"加牌"类小丑
            if G.GAME.blind then G.GAME.blind:debuff_card(new_card) end
            G.hand:sort()
            playing_card_joker_effects({ new_card })
            return true
        end }))
        unhighlight()
        delay(0.5)
    end,
}

SMODS.Consumable {
    key = 'ascension', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 2, y = 0 }, cost = 4, discovered = true,
    config = {},
    loc_txt = loc('阶梯', 'The Ascension',
        { '手中所有牌点数 {C:attention}+1{}', '{C:inactive}（A 变为 2；需至少 1 张手牌）' },
        { '{C:attention}+1{} rank to every card in hand', '{C:inactive}(Aces wrap to 2; needs at least 1 card)' }),
    can_use = function(self, card) return hand_card_count() > 0 end,
    use = function(self, card, area, copier)
        head_start(card)
        each_hand_card(function(c)
            if c.base and c.base.id then
                local id = c.base.id == 14 and 2 or c.base.id + 1
                SMODS.change_base(c, nil, RANK_KEY[id])
            end
        end, 0.08)
        delay(0.5)
    end,
}

SMODS.Consumable {
    key = 'pact', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 3, y = 0 }, cost = 4, discovered = true,
    config = { max_highlighted = 1, extra = { dollars = 10 } },
    loc_txt = loc('契约', 'The Pact',
        { '摧毁选中的 {C:attention}1{} 张手牌', '获得 {C:money}$#1#{}', '{C:inactive}（需选中恰好 1 张；被摧毁的牌永久离开牌堆）' },
        { 'Destroys {C:attention}1{} selected card', 'Earn {C:money}$#1#{}', '{C:inactive}(requires exactly 1 selected; the card is gone for good)' }),
    loc_vars = function(self, iq) return { vars = { self.config.extra.dollars } } end,
    can_use = function(self, card) return G.hand ~= nil and #highlighted() == 1 end,
    use = function(self, card, area, copier)
        local target = highlighted()[1]
        head_start(card)
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
            target:start_dissolve(nil, true)
            return true
        end }))
        unhighlight()
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.5, func = function()
            ease_dollars(self.config.extra.dollars)
            return true
        end }))
        delay(0.6)
    end,
}

SMODS.Consumable {
    key = 'cornucopia', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 4, y = 0 }, cost = 4, discovered = true,
    config = { extra = { per_card = 1 } },
    loc_txt = loc('丰饶', 'The Cornucopia',
        { '手中每张牌获得 {C:money}$#1#{}', '{C:inactive}（按使用时的实际手牌张数结算）' },
        { 'Earn {C:money}$#1#{} for each card in hand', '{C:inactive}(counted at the moment of use)' }),
    loc_vars = function(self, iq) return { vars = { self.config.extra.per_card } } end,
    can_use = function(self, card) return hand_card_count() > 0 end,
    use = function(self, card, area, copier)
        local gain = hand_card_count() * self.config.extra.per_card
        head_start(card)
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
            ease_dollars(gain)
            return true
        end }))
        delay(0.5)
    end,
}

--==============================================================
-- 十二生肖（12）· 全部处理花色
--==============================================================

-- 鼠·仓库寻道：检索同花色
SMODS.Consumable {
    key = 'rat_search', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 5, y = 0 }, cost = 3, discovered = true,
    config = { max_highlighted = 1 },
    loc_txt = loc('鼠·仓库寻道', 'Rat: Warehouse Search',
        { '选中 {C:attention}1{} 张牌，把牌堆中所有{C:attention}同花色{}牌', '加入手牌', '{C:inactive}（需手牌有空位、牌堆里有同花色牌；加到手牌满为止）' },
        { 'Select {C:attention}1{} card: add every card of the', 'same {C:attention}suit{} from your deck to your hand', '{C:inactive}(needs a free slot and a matching card in the deck; stops when hand is full)' }),
    can_use = function(self, card)
        if G.hand == nil or #highlighted() ~= 1 then return false end
        if #G.hand.cards >= G.hand.config.card_limit then return false end
        local suit = suit_of(highlighted()[1])
        if not suit then return false end
        for _, c in ipairs(G.deck.cards) do
            if c:is_suit(suit) then return true end
        end
        return false
    end,
    use = function(self, card, area, copier)
        local suit = suit_of(highlighted()[1])
        local pool = {}
        for _, c in ipairs(G.deck.cards) do
            if c:is_suit(suit) then pool[#pool + 1] = c end
        end
        head_start(card)
        for _, c in ipairs(pool) do
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.1, func = function()
                if #G.hand.cards < G.hand.config.card_limit then
                    G.deck:remove_card(c)
                    G.hand:emplace(c)
                    c:juice_up(0.3, 0.3)
                end
                return true
            end }))
        end
        unhighlight()
        delay(0.5)
    end,
}

-- 牛·障碍赛跑：同花色加成
SMODS.Consumable {
    key = 'ox_run', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 6, y = 0 }, cost = 4, discovered = true,
    config = { max_highlighted = 3, extra = { same = 3, diff = 1 } },
    loc_txt = loc('牛·障碍赛跑', 'Ox: Obstacle Race',
        { '选中至多 {C:attention}3{} 张牌：全部{C:attention}同花色{}则各点数 {C:attention}+#1#{}，', '否则各点数 {C:attention}+#2#{}', '{C:inactive}（至多 3 张；点数上限为 A，不会再升）' },
        { 'Select up to {C:attention}3{} cards: if they all share a {C:attention}suit{},', 'each gains {C:attention}+#1#{} rank, otherwise {C:attention}+#2#{}', '{C:inactive}(up to 3 cards; ranks cap at Ace)' }),
    loc_vars = function(self, iq) return { vars = { self.config.extra.same, self.config.extra.diff } } end,
    can_use = function(self, card) return G.hand ~= nil and #highlighted() > 0 end,
    use = function(self, card, area, copier)
        local targets = {}
        for i = 1, math.min(#highlighted(), self.config.max_highlighted) do targets[#targets + 1] = highlighted()[i] end
        local suit = suit_of(targets[1])
        local same = true
        for _, t in ipairs(targets) do
            if suit_of(t) ~= suit then same = false end
        end
        local step = same and self.config.extra.same or self.config.extra.diff
        head_start(card)
        for _, t in ipairs(targets) do
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.12, func = function()
                local id = math.min(14, (t.base.id or 2) + step)
                SMODS.change_base(t, nil, RANK_KEY[id])
                play_sound('tarot2')
                t:juice_up(0.3, 0.3)
                return true
            end }))
        end
        unhighlight()
        delay(0.6)
    end,
}

-- 虎·狭路相逢：不同花色对抗 → 万能
SMODS.Consumable {
    key = 'tiger_duel', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 0, y = 1 }, cost = 4, discovered = true,
    config = { max_highlighted = 2, extra = { dollars = 3 } },
    loc_txt = loc('虎·狭路相逢', 'Tiger: Narrow Path',
        { '选中 {C:attention}2{} 张{C:attention}不同花色{}牌：点数低者被摧毁，', '高者变为{C:attention}万能牌{}；同花色则每张 +{C:money}$#1#{}（两张共 $#2#）', '{C:inactive}（需选中恰好 2 张；点数相同时摧毁先选的那张）' },
        { 'Select {C:attention}2{} cards of {C:attention}different suits{}:', 'the lower is destroyed and the higher becomes {C:attention}Wild{}; same suit: +{C:money}$#1#{} each ($#2# total)', '{C:inactive}(requires exactly 2 selected; on a tie the first selected is destroyed)' }),
    loc_vars = function(self, iq)
        return { vars = { self.config.extra.dollars, self.config.extra.dollars * 2 } }
    end,
    can_use = function(self, card) return G.hand ~= nil and #highlighted() == 2 end,
    use = function(self, card, area, copier)
        local a, b = highlighted()[1], highlighted()[2]
        head_start(card)
        if suit_of(a) ~= suit_of(b) then
            local low = (a.base.id <= b.base.id) and a or b
            local high = (low == a) and b or a
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
                low:start_dissolve(nil, true)
                high:set_ability(G.P_CENTERS.m_wild)
                high:juice_up(0.4, 0.4)
                play_sound('tarot2')
                return true
            end }))
        else
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
                ease_dollars(self.config.extra.dollars * 2)
                return true
            end }))
        end
        unhighlight()
        delay(0.6)
    end,
}

-- 兔·蓬莱：补齐最少花色
SMODS.Consumable {
    key = 'rabbit_escape', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 1, y = 1 }, cost = 4, discovered = true,
    config = { max_highlighted = 1 },
    loc_txt = loc('兔·蓬莱', 'Rabbit: Penglai',
        { '选中 {C:attention}1{} 张牌，其花色变为你手中{C:attention}数量最少{}的花色', '{C:inactive}（并列时按 黑桃→红桃→梅花→方片 取第一个）' },
        { 'Select {C:attention}1{} card: its suit becomes your {C:attention}least common{} suit', '{C:inactive}(ties resolved in Spades→Hearts→Clubs→Diamonds order)' }),
    can_use = function(self, card) return G.hand ~= nil and #highlighted() == 1 end,
    use = function(self, card, area, copier)
        local target = highlighted()[1]
        local best = pick_suit(suit_counts(), false)
        head_start(card)
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
            target:change_suit(best)
            play_sound('tarot2')
            target:juice_up(0.3, 0.3)
            return true
        end }))
        unhighlight()
        delay(0.5)
    end,
}

-- 龙·跷跷板：归一最多花色
SMODS.Consumable {
    key = 'dragon_balance', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 2, y = 1 }, cost = 4, discovered = true,
    config = {},
    loc_txt = loc('龙·跷跷板', 'Dragon: Seesaw',
        { '手中所有牌花色统一为你手中{C:attention}数量最多{}的花色', '{C:inactive}（需至少 2 张手牌；并列时按 黑桃→红桃→梅花→方片 取第一个）' },
        { 'All cards in hand become your {C:attention}most common{} suit', '{C:inactive}(needs 2+ cards; ties resolved in Spades→Hearts→Clubs→Diamonds order)' }),
    can_use = function(self, card) return hand_card_count() >= 2 end,
    use = function(self, card, area, copier)
        local best = pick_suit(suit_counts(), true)
        head_start(card)
        each_hand_card(function(c) c:change_suit(best) end, 0.06)
        delay(0.5)
    end,
}

-- 蛇·少数与多数：少数多数学结算
SMODS.Consumable {
    key = 'snake_vote', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 3, y = 1 }, cost = 4, discovered = true,
    config = { extra = { chips = 30, dollars = 2 } },
    loc_txt = loc('蛇·少数与多数', 'Snake: Minority Rule',
        { '{C:attention}数量最少{}花色的每张牌{C:attention}永久{}获得 {C:chips}+#1#{}筹码，', '{C:attention}数量最多{}花色的每张牌给 {C:money}$#2#{}', '{C:inactive}（需至少 2 张手牌；并列时按 黑桃→红桃→梅花→方片 取第一个）' },
        { 'Every card of the {C:attention}least common{} suit {C:attention}permanently{} gains {C:chips}+#1#{} Chips,', 'every card of the {C:attention}most common{} suit gives {C:money}$#2#{}', '{C:inactive}(needs 2+ cards; ties resolved in Spades→Hearts→Clubs→Diamonds order)' }),
    loc_vars = function(self, iq) return { vars = { self.config.extra.chips, self.config.extra.dollars } } end,
    can_use = function(self, card) return hand_card_count() >= 2 end,
    use = function(self, card, area, copier)
        local counts = suit_counts()
        local minor, major = pick_suit(counts, false), pick_suit(counts, true)
        head_start(card)
        each_hand_card(function(c)
            if suit_of(c) == minor then
                c.ability.perma_bonus = (c.ability.perma_bonus or 0) + self.config.extra.chips
                c:juice_up(0.3, 0.3)
            elseif suit_of(c) == major then
                ease_dollars(self.config.extra.dollars)
            end
        end, 0.07)
        delay(0.5)
    end,
}

-- 马·木牛流马：花色轮转
SMODS.Consumable {
    key = 'horse_race', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 4, y = 1 }, cost = 4, discovered = true,
    config = {},
    loc_txt = loc('马·木牛流马', 'Horse: Wooden Ox',
        { '手中所有牌花色轮换一位', '{C:inactive}（黑桃→红桃→梅花→方片→黑桃；需至少 1 张手牌）' },
        { 'Rotate the suit of every card in hand', '{C:inactive}(Spades→Hearts→Clubs→Diamonds→Spades; needs at least 1 card)' }),
    can_use = function(self, card) return hand_card_count() > 0 end,
    use = function(self, card, area, copier)
        local function next_suit(s)
            for i, v in ipairs(SUITS) do
                if v == s then return SUITS[i % #SUITS + 1] end
            end
            return SUITS[1]
        end
        head_start(card)
        each_hand_card(function(c)
            local s = suit_of(c)
            if s then c:change_suit(next_suit(s)) end
        end, 0.06)
        delay(0.5)
    end,
}

-- 羊·四情扇：花色随机重掷
SMODS.Consumable {
    key = 'goat_fan', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 5, y = 1 }, cost = 4, discovered = true,
    config = {},
    loc_txt = loc('羊·四情扇', 'Goat: Four Fans',
        { '手中所有牌花色{C:attention}随机重掷{}', '{C:inactive}（需至少 3 张手牌；每张牌独立随机，可能重复）' },
        { 'Rerolls the suit of every card in hand', '{C:inactive}(needs 3+ cards; each card rolls independently)' }),
    can_use = function(self, card) return hand_card_count() >= 3 end,
    use = function(self, card, area, copier)
        head_start(card)
        each_hand_card(function(c)
            local s = pseudorandom_element(SUITS, pseudoseed('blh_goat' .. tostring(c.sort_id or 0)))
            c:change_suit(s)
        end, 0.06)
        delay(0.5)
    end,
}

-- 猴·箱中道：交换花色
SMODS.Consumable {
    key = 'monkey_box', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 6, y = 1 }, cost = 4, discovered = true,
    config = { max_highlighted = 1 },
    loc_txt = loc('猴·箱中道', 'Monkey: Box of Dao',
        { '选中 {C:attention}1{} 张牌，与手中随机另一张牌{C:attention}交换花色{}', '{C:inactive}（需选中恰好 1 张，且手中有 2 张以上）' },
        { 'Select {C:attention}1{} card: swap its suit with another random card in hand', '{C:inactive}(requires exactly 1 selected and 2+ cards in hand)' }),
    can_use = function(self, card) return G.hand ~= nil and #highlighted() == 1 and hand_card_count() >= 2 end,
    use = function(self, card, area, copier)
        local target = highlighted()[1]
        local pool = {}
        for _, c in ipairs(G.hand.cards) do if c ~= target then pool[#pool + 1] = c end end
        local other = pseudorandom_element(pool, pseudoseed('blh_monkey' .. tostring(G.GAME.round or 0)))
        local s1, s2 = suit_of(target), other and suit_of(other)
        head_start(card)
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
            if s1 and s2 then
                target:change_suit(s2)
                other:change_suit(s1)
                play_sound('tarot2')
            end
            return true
        end }))
        unhighlight()
        delay(0.5)
    end,
}

-- 鸡·兵器牌：同花色连带强化
SMODS.Consumable {
    key = 'rooster_arms', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 0, y = 2 }, cost = 4, discovered = true,
    config = { max_highlighted = 1 },
    loc_txt = loc('鸡·兵器牌', 'Rooster: Weapon Cards',
        { '摧毁选中的 {C:attention}1{} 张牌，手中{C:attention}同花色{}的其他牌各变为', '一张随机{C:attention}强化牌{}（会覆盖原有强化）', '{C:inactive}（需选中恰好 1 张；没有同花色其他牌时只摧毁）' },
        { 'Destroy {C:attention}1{} selected card: every other card of the same', '{C:attention}suit{} becomes a random {C:attention}Enhancement{} (overwrites)', '{C:inactive}(requires exactly 1 selected; if nothing else shares the suit, only the card is destroyed)' }),
    can_use = function(self, card) return G.hand ~= nil and #highlighted() == 1 end,
    use = function(self, card, area, copier)
        local target = highlighted()[1]
        local suit = suit_of(target)
        local pool = { 'm_bonus', 'm_mult', 'm_wild', 'm_glass', 'm_steel', 'm_stone', 'm_gold', 'm_lucky' }
        head_start(card)
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
            target:start_dissolve(nil, true)
            return true
        end }))
        each_hand_card(function(c)
            if c ~= target and suit and suit_of(c) == suit then
                c:set_ability(G.P_CENTERS[pseudorandom_element(pool, pseudoseed('blh_rooster' .. tostring(c.sort_id or 0)))])
            end
        end, 0.07)
        unhighlight()
        delay(0.6)
    end,
}

-- 狗·传信人：互换花色
SMODS.Consumable {
    key = 'dog_letter', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 1, y = 2 }, cost = 4, discovered = true,
    config = { max_highlighted = 2 },
    loc_txt = loc('狗·传信人', 'Dog: Messenger',
        { '选中 {C:attention}2{} 张牌，互换两者的{C:attention}花色{}', '{C:inactive}（需选中恰好 2 张；只换花色，点数不变）' },
        { 'Select {C:attention}2{} cards and swap their {C:attention}suits{}', '{C:inactive}(requires exactly 2 selected; ranks are unchanged)' }),
    can_use = function(self, card) return G.hand ~= nil and #highlighted() == 2 end,
    use = function(self, card, area, copier)
        local a, b = highlighted()[1], highlighted()[2]
        local s1, s2 = suit_of(a), suit_of(b)
        head_start(card)
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
            if s1 and s2 then
                a:change_suit(s2)
                b:change_suit(s1)
                play_sound('tarot2')
            end
            return true
        end }))
        unhighlight()
        delay(0.5)
    end,
}

-- 猪·黑白棋子：花色概率赌
SMODS.Consumable {
    key = 'pig_gamble', set = 'Tarot', atlas = 'blh_tarot', pos = { x = 2, y = 2 }, cost = 4, discovered = true,
    config = { max_highlighted = 1, extra = { odds = 2 } },
    loc_txt = loc('猪·黑白棋子', 'Pig: Black and White',
        { '选中 {C:attention}1{} 张牌：{C:green}#1#/#2#{} 概率变为{C:attention}万能牌{}，', '否则其花色变为{C:attention}黑桃{}', '{C:inactive}（需选中恰好 1 张）' },
        { 'Select {C:attention}1{} card: {C:green}#1# in #2#{} chance to become {C:attention}Wild{},', 'otherwise its suit becomes {C:attention}Spades{}', '{C:inactive}(requires exactly 1 selected)' }),
    loc_vars = function(self, iq, card)
        local n, d = SMODS.get_probability_vars(card, 1, self.config.extra.odds, 'blh_pig')
        return { vars = { n, d } }
    end,
    can_use = function(self, card) return G.hand ~= nil and #highlighted() == 1 end,
    use = function(self, card, area, copier)
        local target = highlighted()[1]
        head_start(card)
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.25, func = function()
            if SMODS.pseudorandom_probability(card, 'blh_pig', 1, self.config.extra.odds) then
                target:set_ability(G.P_CENTERS.m_wild)
            else
                target:change_suit('Spades')
            end
            play_sound('tarot2')
            target:juice_up(0.4, 0.4)
            return true
        end }))
        unhighlight()
        delay(0.5)
    end,
}

--==============================================================
-- 四神兽（4）· 确定性单花色转化
--==============================================================

local function make_beast_tarot(key, zh_name, en_name, suit, suit_zh, x, y)
    SMODS.Consumable {
        key = key, set = 'Tarot', atlas = 'blh_tarot', pos = { x = x, y = y }, cost = 3, discovered = true,
        config = {},
        loc_txt = loc(zh_name, en_name,
            { '手中所有牌变为{C:attention}' .. suit_zh .. '{}', '{C:inactive}（需至少 1 张手牌）' },
            { 'Turns every card in hand into {C:attention}' .. suit .. '{}', '{C:inactive}(needs at least 1 card)' }),
        can_use = function(self, card) return hand_card_count() > 0 end,
        use = function(self, card, area, copier)
            head_start(card)
            each_hand_card(function(c) c:change_suit(suit) end, 0.06)
            delay(0.5)
        end,
    }
end

make_beast_tarot('qinglong_east', '青龙·东方', 'Azure Dragon: East', 'Spades', '黑桃', 3, 2)
make_beast_tarot('zhuque_south', '朱雀·南方', 'Vermilion Bird: South', 'Hearts', '红桃', 4, 2)
make_beast_tarot('baihu_west', '白虎·西方', 'White Tiger: West', 'Diamonds', '方片', 5, 2)
make_beast_tarot('xuanwu_north', '玄武·北方', 'Black Tortoise: North', 'Clubs', '梅花', 6, 2)
