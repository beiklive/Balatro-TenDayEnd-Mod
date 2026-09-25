--- 终焉之地 · 16 张标签
--- 图集：34×34，8 列 × 2 行

SMODS.Atlas { key = 'blh_tag', path = 'blh_tag.png', px = 34, py = 34 }

local BLH = SMODS.current_mod.blh

local function loc(zh_name, en_name, zh_text, en_text)
    return { ['zh_CN'] = { name = zh_name, text = zh_text }, ['en-us'] = { name = en_name, text = en_text } }
end

local function add_joker(key, seed)
    if not (G.jokers and #G.jokers.cards < G.jokers.config.card_limit) then return end
    local card = create_card('Joker', G.jokers, nil, nil, nil, nil, key, seed or 'blh_tag')
    card:add_to_deck()
    G.jokers:emplace(card)
end

local function add_consumable(set, key, seed)
    if not (G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit) then return end
    local card = create_card(set, G.consumeables, nil, nil, nil, nil, key, seed or 'blh_tag')
    card:add_to_deck()
    G.consumeables:emplace(card)
end

-- 鼠·寻道：直接给道（跳过流路线）
SMODS.Tag {
    key = 'rat_dao', atlas = 'blh_tag', pos = { x = 0, y = 0 }, min_ante = 1,
    config = { type = 'immediate', dao = 40 },
    loc_txt = loc('鼠·寻道', 'Rat: Dao Seek',
        { '立即获得 {C:money}#1#{} 道' }, { 'Immediately gain {C:money}#1#{} Dao' }),
    loc_vars = function(self, iq, card) return { vars = { self.config.dao } } end,
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.GOLD, function() return true end)
        BLH.add_dao(self.config.dao)
        tag.triggered = true
        return true
    end,
}

-- 牛·负力：+1 出牌次数
SMODS.Tag {
    key = 'ox_power', atlas = 'blh_tag', pos = { x = 1, y = 0 },
    config = { type = 'immediate' },
    loc_txt = loc('牛·负力', 'Ox: Endurance', { '本回合 {C:attention}+1{} 出牌次数' }, { 'This round: {C:attention}+1{} Hand' }),
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.BLUE, function()
            ease_hands_played(1)
            return true
        end)
        tag.triggered = true
        return true
    end,
}

-- 虎·强势：重掷目标盲注
SMODS.Tag {
    key = 'tiger_strong', atlas = 'blh_tag', pos = { x = 2, y = 0 },
    config = { type = 'new_blind_choice' },
    loc_txt = loc('虎·强势', 'Tiger: Dominance', { '重掷本盲注' }, { 'Rerolls this Blind' }),
    apply = function(self, tag, context)
        if context.type ~= 'new_blind_choice' then return end
        tag:yep('+', G.C.RED, function() return true end)
        if G.GAME.round_resets.blind_choices then
            G.GAME.round_resets.blind_choices.Boss = get_new_boss()
        end
        tag.triggered = true
        return true
    end,
}

-- 兔·脱身：+2 弃牌
SMODS.Tag {
    key = 'rabbit_escape', atlas = 'blh_tag', pos = { x = 3, y = 0 },
    config = { type = 'immediate' },
    loc_txt = loc('兔·脱身', 'Rabbit: Escape', { '本回合 {C:attention}+2{} 弃牌次数' }, { 'This round: {C:attention}+2{} Discards' }),
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.BLUE, function()
            ease_discard(2)
            return true
        end)
        tag.triggered = true
        return true
    end,
}

-- 龙·称量：击败 Boss 得钱
SMODS.Tag {
    key = 'dragon_scale', atlas = 'blh_tag', pos = { x = 4, y = 0 },
    config = { type = 'eval', dollars = 25 },
    loc_txt = loc('龙·称量', 'Dragon: Weighing', { '击败{C:attention}Boss盲注{}时获得 {C:money}$#1#{}' }, { 'Gain {C:money}$#1#{} when you defeat a Boss Blind' }),
    loc_vars = function(self, iq, card) return { vars = { self.config.dollars } } end,
    apply = function(self, tag, context)
        if context.type ~= 'eval' then return end
        if G.GAME.last_blind and G.GAME.last_blind.boss then
            tag:yep('+', G.C.GOLD, function() return true end)
            tag.triggered = true
            return { dollars = self.config.dollars, condition = localize('ph_defeat_the_boss'), pos = self.pos, tag = tag }
        end
    end,
}

-- 蛇·诡问：免费秘术包
SMODS.Tag {
    key = 'snake_riddle', atlas = 'blh_tag', pos = { x = 5, y = 0 },
    config = { type = 'new_blind_choice' },
    loc_txt = loc('蛇·诡问', 'Snake: Riddle', { '免费开启一个{C:attention}秘术包{}' }, { 'Open a free {C:attention}Arcana Pack{}' }),
    apply = function(self, tag, context)
        if context.type ~= 'new_blind_choice' then return end
        tag:yep('+', G.C.PURPLE, function()
            local key = 'p_arcana_normal_' .. math.random(1, 3)
            local card = Card(G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2,
                G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2, G.CARD_W * 1.27, G.CARD_H * 1.27,
                G.P_CARDS.empty, G.P_CENTERS[key], { bypass_discovery_center = true, bypass_discovery_ui = true })
            card.cost = 0
            card.from_tag = true
            G.FUNCS.use_card({ config = { ref_table = card } })
            card:start_materialize()
            return true
        end)
        tag.triggered = true
        return true
    end,
}

-- 马·竞速：按已出牌数给道
SMODS.Tag {
    key = 'horse_speed', atlas = 'blh_tag', pos = { x = 6, y = 0 },
    config = { type = 'immediate', dao_per_hand = 2 },
    loc_txt = loc('马·竞速', 'Horse: Race', { '每张已打出的牌获得 {C:money}#1#{} 道' }, { 'Gain {C:money}#1#{} Dao for each card played' }),
    loc_vars = function(self, iq, card) return { vars = { self.config.dao_per_hand } } end,
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.GOLD, function() return true end)
        local plays = 0
        for _, v in pairs(G.GAME.hands or {}) do plays = plays + (v.played or 0) end
        BLH.add_dao(plays * self.config.dao_per_hand)
        tag.triggered = true
        return true
    end,
}

-- 羊·伪饰：商店小丑变负片
SMODS.Tag {
    key = 'goat_disguise', atlas = 'blh_tag', pos = { x = 7, y = 0 },
    config = { type = 'store_joker_modify', edition = 'negative', odds = 1 },
    loc_txt = loc('羊·伪饰', 'Goat: Disguise', { '商店中的 {C:attention}1{} 张小丑变为{C:dark_edition}负片{}' }, { '{C:attention}1{} Joker in the shop becomes {C:dark_edition}Negative{}' }),
    apply = function(self, tag, context)
        if context.type ~= 'store_joker_modify' or not context.card then return end
        if context.card.edition then return end
        context.card:set_edition('e_negative', true)
        context.card:juice_up(0.3, 0.5)
        tag:yep('+', G.C.DARK_EDITION, function() return true end)
        tag.triggered = true
        return true
    end,
}

-- 猴·取物：免费回响小丑
SMODS.Tag {
    key = 'monkey_take', atlas = 'blh_tag', pos = { x = 0, y = 1 },
    config = { type = 'immediate' },
    loc_txt = loc('猴·取物', 'Monkey: Snatch', { '免费获得 {C:attention}1{} 张回响小丑牌' }, { 'Gain {C:attention}1{} free Echo Joker' }),
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.PURPLE, function() return true end)
        local pool = {}
        for _, j in pairs(SMODS.Jokers or {}) do
            if j.mod == SMODS.current_mod then pool[#pool + 1] = j.key end
        end
        if #pool > 0 then
            add_joker(pseudorandom_element(pool, pseudoseed('blh_monkey_tag')), 'blh_mtag')
        end
        tag.triggered = true
        return true
    end,
}

-- 鸡·夺械：免费生肖塔罗
SMODS.Tag {
    key = 'rooster_weapon', atlas = 'blh_tag', pos = { x = 1, y = 1 },
    config = { type = 'immediate' },
    loc_txt = loc('鸡·夺械', 'Rooster: Seize', { '免费获得 {C:attention}1{} 张生肖塔罗' }, { 'Gain {C:attention}1{} free Zodiac Tarot' }),
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.SECONDARY_SET.Tarot, function() return true end)
        local pool = {}
        for _, c in ipairs(G.P_CENTER_POOLS.Tarot or {}) do pool[#pool + 1] = c.key end
        if #pool > 0 then
            add_consumable('Tarot', pseudorandom_element(pool, pseudoseed('blh_rooster_tag')), 'blh_rtag')
        end
        tag.triggered = true
        return true
    end,
}

-- 狗·传信：免费优惠券
SMODS.Tag {
    key = 'dog_letter', atlas = 'blh_tag', pos = { x = 2, y = 1 },
    config = { type = 'voucher_add' },
    loc_txt = loc('狗·传信', 'Dog: Letter', { '商店中的优惠券 {C:attention}免费{}' }, { 'The next Voucher in the shop is {C:attention}free{}' }),
    apply = function(self, tag, context)
        if context.type ~= 'voucher_add' then return end
        tag:yep('+', G.C.GOLD, function() return true end)
        tag.triggered = true
        return true
    end,
}

-- 猪·博弈：金钱赌命
SMODS.Tag {
    key = 'pig_gamble', atlas = 'blh_tag', pos = { x = 3, y = 1 },
    config = { type = 'immediate' },
    loc_txt = loc('猪·博弈', 'Pig: Gamble', { '{C:green}1/2{} 概率金钱翻倍，否则减半' }, { '{C:green}1 in 2{} chance to double your money, otherwise halve it' }),
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.MONEY, function() return true end)
        if SMODS.pseudorandom_probability(tag, 'blh_pig_tag', 1, 2) then
            ease_dollars(G.GAME.dollars)
        else
            ease_dollars(-math.floor(G.GAME.dollars / 2))
        end
        tag.triggered = true
        return true
    end,
}

-- 玄武·公正：失败保护
SMODS.Tag {
    key = 'xuanwu_fair', atlas = 'blh_tag', pos = { x = 4, y = 1 },
    config = { type = 'immediate' },
    loc_txt = loc('玄武·公正', 'Xuanwu: Justice',
        { '获得 {C:attention}1{} 次免死保护', '{C:inactive}（盲注失败时自动消耗）' },
        { 'Gain {C:attention}1{} protection charge', '{C:inactive}(consumed when you fail a Blind)' }),
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.BLUE, function()
            G.GAME.blh_save_charges = (G.GAME.blh_save_charges or 0) + 1
            return true
        end)
        tag.triggered = true
        return true
    end,
}

-- 白虎·调停：解除 debuff
SMODS.Tag {
    key = 'baihu_mediate', atlas = 'blh_tag', pos = { x = 5, y = 1 },
    config = { type = 'immediate' },
    loc_txt = loc('白虎·调停', 'Baihu: Mediation', { '立即解除当前盲注的限制' }, { 'Immediately removes the current Blind restriction' }),
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.RED, function() return true end)
        if G.GAME.blind and G.GAME.blind.boss then G.GAME.blind:disable() end
        tag.triggered = true
        return true
    end,
}

-- 朱雀·审判：摧毁小丑换钱
SMODS.Tag {
    key = 'zhuque_judge', atlas = 'blh_tag', pos = { x = 6, y = 1 },
    config = { type = 'immediate', dollars = 30 },
    loc_txt = loc('朱雀·审判', 'Zhuque: Judgement', { '摧毁随机 {C:attention}1{} 张小丑，获得 {C:money}$#1#{}' }, { 'Destroys {C:attention}1{} random Joker and gives {C:money}$#1#{}' }),
    loc_vars = function(self, iq, card) return { vars = { self.config.dollars } } end,
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.MONEY, function() return true end)
        if G.jokers and #G.jokers.cards > 0 then
            SMODS.destroy_cards(pseudorandom_element(G.jokers.cards, pseudoseed('blh_zhuque_tag')))
        end
        ease_dollars(self.config.dollars)
        tag.triggered = true
        return true
    end,
}

-- 青龙·之首：优惠券 + 负片小丑
SMODS.Tag {
    key = 'qinglong_head', atlas = 'blh_tag', pos = { x = 7, y = 1 },
    config = { type = 'immediate' },
    loc_txt = loc('青龙·之首', 'Qinglong: The Head', { '免费优惠券 + {C:dark_edition}负片{}小丑' }, { 'Free Voucher + a {C:dark_edition}Negative{} Joker' }),
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.PURPLE, function() return true end)
        local pool = {}
        for _, j in pairs(SMODS.Jokers or {}) do
            if j.mod == SMODS.current_mod then pool[#pool + 1] = j.key end
        end
        if #pool > 0 and G.jokers and #G.jokers.cards < G.jokers.config.card_limit then
            local key = pseudorandom_element(pool, pseudoseed('blh_qinglong_tag'))
            local card = create_card('Joker', G.jokers, nil, nil, nil, nil, key, 'blh_qtag')
            card:set_edition('e_negative', true)
            card:add_to_deck()
            G.jokers:emplace(card)
        end
        if G.GAME.current_round then G.GAME.current_round.voucher = nil end
        tag.triggered = true
        return true
    end,
}
