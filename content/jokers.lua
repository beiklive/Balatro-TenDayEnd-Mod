--- 终焉之地 · 30 张回响小丑
--- 稀有度按原著回响名字字数：2 字=普通(1)、3 字=罕见(2)、4 字=稀有(3)

SMODS.Atlas { key = 'blh_joker', path = 'blh_joker.png', px = 71, py = 95 }

local function loc(zh_name, en_name, zh_text, en_text)
    return { ['zh_CN'] = { name = zh_name, text = zh_text }, ['en-us'] = { name = en_name, text = en_text } }
end

local BLH = SMODS.current_mod.blh
local RANK_KEY = { [2]='2',[3]='3',[4]='4',[5]='5',[6]='6',[7]='7',[8]='8',[9]='9',[10]='T',[11]='J',[12]='Q',[13]='K',[14]='A' }

local function hand_count() return (G.hand and #G.hand.cards) or 0 end
local function round_id() return (G.GAME.round_resets.ante or 1) * 1000 + (G.GAME.round or 0) end

local function once(card)
    local id = round_id()
    if card.ability.extra.rnd == id then return false end
    card.ability.extra.rnd = id
    return true
end

local function neg_count()
    local n = 0
    for _, j in ipairs((G.jokers and G.jokers.cards) or {}) do
        if j.edition and j.edition.negative then n = n + 1 end
    end
    return n
end

local function random_hand_card(exclude)
    local pool = {}
    for _, c in ipairs((G.hand and G.hand.cards) or {}) do
        if c ~= exclude then pool[#pool + 1] = c end
    end
    if #pool == 0 then return nil end
    return pseudorandom_element(pool, pseudoseed('blh_hand' .. tostring(G.GAME.round or 0) .. tostring(#pool)))
end

-- 原版 Marble Joker 的写法：create_playing_card 会同时登记进 G.playing_cards 并 emplace 到目标区域
local function add_playing_card(enhancement, area)
    area = area or G.deck
    if not area then return end
    local card = create_playing_card({
        front = pseudorandom_element(G.P_CARDS, pseudoseed('blh_front')),
        center = G.P_CENTERS[enhancement or 'c_base'],
    }, area, nil, nil, { G.C.SECONDARY_SET.Enhanced })
    -- 原版 create_playing_card 已维护 G.playing_cards；手动改 deck.config.card_limit 会在
    -- SMODS 的 card_limits 模型下写入无意义的 mod，故不再手改
    -- 与原版 Marble 一致：新加入的牌要触发 playing_card_added 类效果
    if card then playing_card_joker_effects({ card }) end
    return card
end

--==============================================================
-- 3.1 洞见
--==============================================================

-- 灵视：手牌上限 +1
SMODS.Joker {
    key = 'ling_shi', discovered = true, atlas = 'blh_joker', pos = { x = 0, y = 0 }, rarity = 1, cost = 5,
    config = { extra = {} },
    loc_txt = loc('灵视-苏闪', 'Spirit Sight - Su Shan', { '手牌上限 {C:attention}+1{}' }, { 'Hand size {C:attention}+1{}' }),
    add_to_deck = function(self, card) G.hand:change_size(1) end,
    remove_from_deck = function(self, card) G.hand:change_size(-1) end,
}

-- 灵闻：同花/顺子返还 1 次出牌
SMODS.Joker {
    key = 'ling_wen', discovered = true, atlas = 'blh_joker', pos = { x = 1, y = 0 }, rarity = 1, cost = 5,
    config = { extra = {} },
    loc_txt = loc('灵闻-齐夏', 'Spirit Hearing - Qi Xia',
        { '每回合首次打出{C:attention}同花{}或{C:attention}顺子{}', '返还 {C:attention}1{} 次出牌次数' },
        { 'First {C:attention}Flush{} or {C:attention}Straight{} each round', 'refunds {C:attention}1{} Hand' }),
    calculate = function(self, card, context)
        if context.before and not context.blueprint and once(card) then
            if next(context.poker_hands['Flush']) or next(context.poker_hands['Straight']) then
                ease_hands_played(1)
                return { message = localize('k_again_ex'), colour = G.C.BLUE }
            end
        end
    end,
}

-- 灵嗅：强化/版本/蜡封数量 -> Chips
SMODS.Joker {
    key = 'ling_xiu', discovered = true, atlas = 'blh_joker', pos = { x = 2, y = 0 }, rarity = 1, cost = 5,
    config = { extra = { chips = 15, cap = 90 } },
    loc_txt = loc('灵嗅-郑应雄', 'Spirit Smell - Zheng Yingxiong',
        { '计分时手中每张带{C:attention}强化/版本/蜡封{}的牌', '{C:chips}+#1#{}筹码（上限 #2#）' },
        { '{C:chips}+#1#{} Chips per Enhanced,', 'Editioned or Sealed card in hand (max #2#)' }),
    loc_vars = function(self, iq, card) return { vars = { card.ability.extra.chips, card.ability.extra.cap } } end,
    calculate = function(self, card, context)
        if context.joker_main then
            local n = 0
            for _, c in ipairs(G.hand.cards) do
                if (c.ability and c.ability.name ~= 'Default') or c.edition or c.seal then n = n + 1 end
            end
            local chips = math.min(n * card.ability.extra.chips, card.ability.extra.cap)
            if chips > 0 then return { chips = chips } end
        end
    end,
}

-- 魂迁：弃牌时把点数转移给随机手牌
SMODS.Joker {
    key = 'hun_qian', discovered = true, atlas = 'blh_joker', pos = { x = 3, y = 0 }, rarity = 1, cost = 6,
    config = { extra = {} },
    loc_txt = loc('魂迁-章晨泽', 'Soul Shift - Zhang Chenze',
        { '弃掉 {C:attention}1{} 张牌时，把它的点数 {C:attention}+1{}', '转移给一张随机手牌' },
        { 'When a card is discarded, move its rank {C:attention}+1{}', 'onto a random card in hand' }),
    calculate = function(self, card, context)
        if context.discard and not context.blueprint and not context.other_card.debuff then
            local target = random_hand_card()
            if target and target.base and target.base.id then
                local id = context.other_card.base.id + 1
                if id > 14 then id = 2 end
                SMODS.change_base(target, nil, RANK_KEY[id])
                return { message = localize('k_upgrade_ex'), colour = G.C.CHIPS }
            end
        end
    end,
}

--==============================================================
-- 3.2 破法
--==============================================================

-- 离析：概率摧毁手牌
SMODS.Joker {
    key = 'li_xi', discovered = true, atlas = 'blh_joker', pos = { x = 4, y = 0 }, rarity = 1, cost = 6,
    config = { extra = { odds = 4, dollars = 2 } },
    loc_txt = loc('离析-赵海博', 'Disintegration - Zhao Haibo',
        { '每次出牌后 {C:green}#1#/#2#{} 概率', '摧毁一张随机手牌并获得 {C:money}$#3#{}' },
        { '{C:green}#1# in #2#{} chance after each hand', 'to destroy a random card in hand and gain {C:money}$#3#{}' }),
    loc_vars = function(self, iq, card)
        local n, d = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'blh_lixi')
        return { vars = { n, d, card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            local target = random_hand_card()
            if target and SMODS.pseudorandom_probability(card, 'blh_lixi', 1, card.ability.extra.odds) then
                SMODS.destroy_cards(target)
                ease_dollars(card.ability.extra.dollars)
                return { message = localize('k_nope_ex'), colour = G.C.RED }
            end
        end
    end,
}

-- 招灾：回合结束概率摧毁手牌换取永久 Mult
SMODS.Joker {
    key = 'zhao_zai', discovered = true, atlas = 'blh_joker', pos = { x = 5, y = 0 }, rarity = 1, cost = 6,
    config = { extra = { odds = 3, mult = 0, gain = 8 } },
    loc_txt = loc('招灾-韩一墨', 'Calamity - Han Yimo',
        { '回合结束 {C:green}#1#/#2#{} 概率摧毁随机 {C:attention}2{} 张手牌，', '本牌永久 {C:mult}+#3#{}倍率', '{C:inactive}（当前为{C:mult}+#4#{C:inactive}倍率）' },
        { '{C:green}#1# in #2#{} chance at end of round to destroy', '{C:attention}2{} random cards in hand; gains {C:mult}+#3#{} Mult', '{C:inactive}(Currently {C:mult}+#4#{C:inactive} Mult)' }),
    loc_vars = function(self, iq, card)
        local n, d = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'blh_zhaozai')
        return { vars = { n, d, card.ability.extra.gain, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.game_over and not context.blueprint
            and not context.individual and not context.repetition then
            if SMODS.pseudorandom_probability(card, 'blh_zhaozai', 1, card.ability.extra.odds) then
                local targets = {}
                for _, c in ipairs(G.hand.cards) do targets[#targets + 1] = c end
                for i = 1, math.min(2, #targets) do
                    if targets[i] then SMODS.destroy_cards(targets[i]) end
                end
                card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.gain
                return { message = localize('k_upgrade_ex'), colour = G.C.MULT }
            end
            return { message = localize('k_safe_ex') }
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- 爆燃：弃牌概率爆炸
SMODS.Joker {
    key = 'bao_ran', discovered = true, atlas = 'blh_joker', pos = { x = 0, y = 1 }, rarity = 1, cost = 5,
    config = { extra = { odds = 4, dollars = 4 } },
    loc_txt = loc('爆燃-宋明辉', 'Detonation - Song Minghui',
        { '弃掉牌时 {C:green}#1#/#2#{} 概率引爆该牌', '获得 {C:money}$#3#{}' },
        { '{C:green}#1# in #2#{} chance when discarding', 'to detonate the card for {C:money}$#3#{}' }),
    loc_vars = function(self, iq, card)
        local n, d = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'blh_baoran')
        return { vars = { n, d, card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.discard and not context.blueprint and not context.other_card.debuff then
            if SMODS.pseudorandom_probability(card, 'blh_baoran', 1, card.ability.extra.odds) then
                ease_dollars(card.ability.extra.dollars)
                return { message = localize('blh_msg_boom'), colour = G.C.MONEY }
            end
        end
    end,
}

-- 破万法：解除盲注限制
SMODS.Joker {
    key = 'po_wan_fa', discovered = true, atlas = 'blh_joker', pos = { x = 1, y = 1 }, rarity = 2, cost = 7,
    config = { extra = {} },
    loc_txt = loc('破万法-乔家劲', 'Law Breaker - Qiao Jiajin',
        { '每回合首次出牌时解除当前盲注的限制', '并返还 {C:attention}1{} 次出牌次数' },
        { 'Each round, the first hand removes', 'the current Blind restriction and refunds {C:attention}1{} Hand' }),
    calculate = function(self, card, context)
        if context.before and not context.blueprint and once(card) then
            if G.GAME.blind and G.GAME.blind.boss then
                G.GAME.blind:disable()
                ease_hands_played(1)
                return { message = localize('k_disabled_ex'), colour = G.C.RED }
            end
        end
    end,
}

--==============================================================
-- 3.3 生成与复制
--==============================================================

-- 巧物：花钱造塔罗
SMODS.Joker {
    key = 'qiao_wu', discovered = true, atlas = 'blh_joker', pos = { x = 2, y = 1 }, rarity = 1, cost = 6,
    config = { extra = { cost = 3 } },
    loc_txt = loc('巧物-张丽娟', 'Craftwork - Zhang Lijuan',
        { '回合结束时花 {C:money}$#1#{}，', '生成 {C:attention}1{} 张随机塔罗牌' },
        { 'At end of round, pay {C:money}$#1#{}', 'to create {C:attention}1{} random Tarot' }),
    loc_vars = function(self, iq, card) return { vars = { card.ability.extra.cost } } end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.game_over and not context.blueprint
            and not context.individual and not context.repetition then
            if G.GAME.dollars >= card.ability.extra.cost and #G.consumeables.cards < G.consumeables.config.card_limit then
                ease_dollars(-card.ability.extra.cost)
                G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
                    if #G.consumeables.cards < G.consumeables.config.card_limit then
                        local c = create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'blh_qiao')
                        c:add_to_deck()
                        G.consumeables:emplace(c)
                    else
                        -- 延迟期间槽位被别人占满：退款，不能白扣钱
                        ease_dollars(card.ability.extra.cost)
                    end
                    return true
                end }))
                return { message = localize('blh_msg_tarot'), colour = G.C.SECONDARY_SET.Tarot }
            end
        end
    end,
}

-- 显灵：手牌有蜡封则生成幻灵
SMODS.Joker {
    key = 'xian_ling', discovered = true, atlas = 'blh_joker', pos = { x = 3, y = 1 }, rarity = 1, cost = 6,
    config = { extra = {} },
    loc_txt = loc('显灵-李香玲', 'Apparition - Li Xiangling',
        { '回合结束时，若手牌中有带{C:attention}蜡封{}的牌，', '生成 {C:attention}1{} 张随机幻灵牌' },
        { 'At end of round, if a card in hand has a {C:attention}Seal{},', 'create {C:attention}1{} random Spectral card' }),
    calculate = function(self, card, context)
        if context.end_of_round and not context.game_over and not context.blueprint
            and not context.individual and not context.repetition then
            local sealed = false
            for _, c in ipairs(G.hand.cards) do if c.seal then sealed = true break end end
            if sealed and #G.consumeables.cards < G.consumeables.config.card_limit then
                G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
                    if #G.consumeables.cards < G.consumeables.config.card_limit then
                        local c = create_card('Spectral', G.consumeables, nil, nil, nil, nil, nil, 'blh_xian')
                        c:add_to_deck()
                        G.consumeables:emplace(c)
                    end
                    return true
                end }))
                return { message = localize('blh_msg_spectral'), colour = G.C.SECONDARY_SET.Spectral }
            end
        end
    end,
}

-- 原物：每回合造一张石头牌进牌堆
SMODS.Joker {
    key = 'yuan_wu', discovered = true, atlas = 'blh_joker', pos = { x = 4, y = 1 }, rarity = 1, cost = 5,
    config = { extra = {} },
    loc_txt = loc('原物-老孙', 'Prime Matter - Lao Sun',
        { '每次{C:attention}选择盲注{}时，', '牌堆中加入 {C:attention}1{} 张石头牌' },
        { 'When a {C:attention}Blind is selected{},', 'add {C:attention}1{} Stone card to your deck' }),
    -- 时机用原版 Marble Joker 的 setting_blind：回合结束往牌堆塞牌会与牌堆回收/存档交错
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.3, func = function()
                add_playing_card('m_stone')
                return true
            end }))
            return { message = localize('blh_msg_stone'), colour = G.C.SECONDARY_SET.Enhanced }
        end
    end,
}

-- 赝品：复制手牌但打折，永久成长
SMODS.Joker {
    key = 'yan_pin', discovered = true, atlas = 'blh_joker', pos = { x = 5, y = 1 }, rarity = 1, cost = 6,
    config = { extra = { mult = 0, gain = 2, odds = 2 } },
    loc_txt = loc('赝品-秦丁冬', 'Forgery - Qin Dingdong',
        { '回合结束 {C:green}#1#/#2#{} 概率复制一张手牌，', '每次复制本牌永久 {C:mult}+#3#{}倍率', '{C:inactive}（当前为{C:mult}+#4#{C:inactive}倍率）' },
        { '{C:green}#1# in #2#{} chance at end of round to copy a card in hand;', 'gains {C:mult}+#3#{} Mult each time', '{C:inactive}(Currently {C:mult}+#4#{C:inactive} Mult)' }),
    loc_vars = function(self, iq, card)
        local n, d = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'blh_yanpin')
        return { vars = { n, d, card.ability.extra.gain, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        -- 回合结束只掷骰并挂起：此时往手牌塞牌会被回合重置清掉
        if context.end_of_round and not context.game_over and not context.blueprint
            and not context.individual and not context.repetition then
            if SMODS.pseudorandom_probability(card, 'blh_yanpin', 1, card.ability.extra.odds) then
                card.ability.extra.pending = true
                return { message = localize('k_duplicated_ex'), colour = G.C.MULT }
            end
            return { message = localize('k_safe_ex') }
        end
        -- 下一回合首手抽完牌后再复制（原版 Certificate 用的就是 first_hand_drawn）
        if context.first_hand_drawn and not context.blueprint and card.ability.extra.pending then
            card.ability.extra.pending = nil
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
                if hand_count() > 0 and #G.hand.cards < G.hand.config.card_limit then
                    local src = random_hand_card()
                    if src then
                        G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                        local new_card = copy_card(src, nil, nil, G.playing_card)
                        new_card:add_to_deck()
                        table.insert(G.playing_cards, new_card)
                        G.hand:emplace(new_card)
                        -- 与原版 Certificate 一致：新手牌立刻吃盲注 debuff、排序并触发"加牌"类小丑
                        if G.GAME.blind then G.GAME.blind:debuff_card(new_card) end
                        G.hand:sort()
                        playing_card_joker_effects({ new_card })
                        card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.gain
                    end
                end
                return true
            end }))
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- 探囊：花钱取牌
SMODS.Joker {
    key = 'tan_nang', discovered = true, atlas = 'blh_joker', pos = { x = 0, y = 2 }, rarity = 1, cost = 6,
    config = { extra = { cost = 3 } },
    loc_txt = loc('探囊-李尚武', 'Pilfer - Li Shangwu',
        { '回合结束时花 {C:money}$#1#{}，', '把牌堆中随机 {C:attention}1{} 张强化牌加入手牌' },
        { 'At end of round, pay {C:money}$#1#{}', 'to add a random Enhanced card from your deck to hand' }),
    loc_vars = function(self, iq, card) return { vars = { card.ability.extra.cost } } end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.game_over and not context.blueprint
            and not context.individual and not context.repetition then
            if G.GAME.dollars < card.ability.extra.cost then return end
            ease_dollars(-card.ability.extra.cost)
            card.ability.extra.pending = true
            return { message = localize('blh_msg_card'), colour = G.C.CHIPS }
        end
        -- 下一回合首手抽完后取牌（当下时刻手牌区已就绪，不会再被回合重置清掉）
        if context.first_hand_drawn and not context.blueprint and card.ability.extra.pending then
            card.ability.extra.pending = nil
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
                if #G.hand.cards < G.hand.config.card_limit then
                    local pool = {}
                    for _, c in ipairs(G.deck.cards) do
                        if c.ability and c.ability.name ~= 'Default' then pool[#pool + 1] = c end
                    end
                    if #pool > 0 then
                        local pick = pseudorandom_element(pool, pseudoseed('blh_tannang' .. tostring(G.GAME.round or 0)))
                        G.deck:remove_card(pick)
                        G.hand:emplace(pick)
                        if G.GAME.blind then G.GAME.blind:debuff_card(pick) end
                        G.hand:sort()
                    end
                end
                return true
            end }))
        end
    end,
}

-- 癫人：持有金钱换永久 Mult
SMODS.Joker {
    key = 'dian_ren', discovered = true, atlas = 'blh_joker', pos = { x = 1, y = 2 }, rarity = 1, cost = 6,
    config = { extra = { threshold = 20, mult = 0, gain = 3 } },
    loc_txt = loc('癫人-楚天秋', 'Madman - Chu Tianqiu',
        { '回合结束时若持有 {C:money}$#1#{} 以上，', '本牌永久 {C:mult}+#2#{}倍率', '{C:inactive}（当前为{C:mult}+#3#{C:inactive}倍率）' },
        { 'At end of round, if you have at least {C:money}$#1#{},', 'gains {C:mult}+#2#{} Mult', '{C:inactive}(Currently {C:mult}+#3#{C:inactive} Mult)' }),
    loc_vars = function(self, iq, card)
        return { vars = { card.ability.extra.threshold, card.ability.extra.gain, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.game_over and not context.blueprint
            and not context.individual and not context.repetition then
            if G.GAME.dollars >= card.ability.extra.threshold then
                card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.gain
                return { message = localize('k_upgrade_ex'), colour = G.C.MULT }
            end
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- 双生花：把最强强化扩散给同点数手牌
SMODS.Joker {
    key = 'shuang_sheng_hua', discovered = true, atlas = 'blh_joker', pos = { x = 2, y = 2 }, rarity = 2, cost = 7,
    config = { extra = { odds = 2 } },
    loc_txt = loc('双生花-钱多多', 'Twin Blossom - Qian Duoduo',
        { '每次出牌 {C:green}#1#/#2#{} 概率', '把手中最强的强化复制给同点数的其他手牌' },
        { '{C:green}#1# in #2#{} chance each hand to copy', 'the strongest enhancement to same-rank cards in hand' }),
    loc_vars = function(self, iq, card)
        local n, d = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'blh_shuang')
        return { vars = { n, d } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            if not SMODS.pseudorandom_probability(card, 'blh_shuang', 1, card.ability.extra.odds) then return end
            local best, best_rank = nil, nil
            for _, c in ipairs(G.hand.cards) do
                if c.ability and c.ability.name and c.ability.name ~= 'Default' then
                    best = c; best_rank = c.base.value; break
                end
            end
            if not best then return end
            local n = 0
            for _, c in ipairs(G.hand.cards) do
                if c ~= best and c.base.value == best_rank then
                    c:set_ability(G.P_CENTERS[best.config.center.key], nil, true)
                    n = n + 1
                end
            end
            if n > 0 then return { message = localize('k_upgrade_ex'), colour = G.C.MULT } end
        end
    end,
}

-- 生生不息：定期造负片小丑
SMODS.Joker {
    key = 'sheng_sheng_bu_xi', discovered = true, atlas = 'blh_joker', pos = { x = 3, y = 2 }, rarity = 3, cost = 8,
    config = { extra = { every = 3, count = 0, made = 0, cap = 3 } },
    loc_txt = loc('生生不息-齐夏', 'Endless Creation - Qi Xia',
        { '每 {C:attention}#1#{} 个回合生成 1 张随机{C:dark_edition}负片{}小丑牌',
          '{C:inactive}（已积累 #4# 回合，已生成 #2#/#3#）' },
        { 'Every {C:attention}#1#{} rounds, create a random {C:dark_edition}Negative{} Joker',
          '{C:inactive}(#4# rounds banked, created #2#/#3#)' }),
    -- #4# 是累计回合数（每回合都变），#2# 只在真正生成时 +1：
    -- 之前只显示 #2#，玩家推进回合看不到任何变化，会以为没生效
    loc_vars = function(self, iq, card)
        local e = (card and card.ability and card.ability.extra) or self.config.extra
        return { vars = { e.every, e.made or 0, e.cap, e.count or 0 } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.game_over and not context.blueprint
            and not context.individual and not context.repetition then
            local extra = card.ability.extra
            extra.count = (extra.count or 0) + 1
            -- 每 every 个回合一次，且总产出不超过 cap（原用 count 差值判断，cap=3 时会产出 9 次）
            if extra.count % extra.every == 0 and (extra.made or 0) < extra.cap then
                if not (G.jokers and #G.jokers.cards < G.jokers.config.card_limit) then
                    -- 小丑栏已满：不消耗这次机会，但要说清原因，否则看起来像没生效
                    return { message = localize('k_no_space_ex'), colour = G.C.RED }
                end
                G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.3, func = function()
                    if G.jokers and #G.jokers.cards < G.jokers.config.card_limit then
                        local c = create_card('Joker', G.jokers, nil, nil, nil, nil, nil, 'blh_ssbx')
                        c:set_edition('e_negative', true)
                        c:add_to_deck()
                        G.jokers:emplace(c)
                        extra.made = (extra.made or 0) + 1
                    end
                    return true
                end }))
                return { message = localize('k_duplicated_ex'), colour = G.C.DARK_EDITION }
            end
        end
    end,
}

--==============================================================
-- 3.4 概率与赌运
--==============================================================

-- 强运：概率分子 +1
SMODS.Joker {
    key = 'qiang_yun', discovered = true, atlas = 'blh_joker', pos = { x = 4, y = 2 }, rarity = 1, cost = 5,
    config = { extra = { bonus = 1 } },
    loc_txt = loc('强运-云瑶', 'Fortune - Yun Yao',
        { '所有概率效果的分子 {C:green}+#1#{}', '{C:inactive}(1/4 → 2/4)' },
        { 'All probability rolls get {C:green}+#1#{} to the numerator', '{C:inactive}(1/4 → 2/4)' }),
    loc_vars = function(self, iq, card) return { vars = { card.ability.extra.bonus } } end,
    calculate = function(self, card, context)
        if context.fix_probability and not context.blueprint then
            return { numerator = (context.numerator or 1) + card.ability.extra.bonus }
        end
    end,
}

-- 激发：概率分母 -1
SMODS.Joker {
    key = 'ji_fa', discovered = true, atlas = 'blh_joker', pos = { x = 5, y = 2 }, rarity = 1, cost = 5,
    config = { extra = { bonus = 1 } },
    loc_txt = loc('激发-林檎', 'Awakening - Lin Qin',
        { '所有概率效果的分母 {C:green}-#1#{}', '{C:inactive}(1/4 → 1/3）' },
        { 'All probability rolls get {C:green}-#1#{} from the denominator', '{C:inactive}(1/4 → 1/3)' }),
    loc_vars = function(self, iq, card) return { vars = { card.ability.extra.bonus } } end,
    calculate = function(self, card, context)
        if context.fix_probability and not context.blueprint then
            return { denominator = math.max(1, (context.denominator or 2) - card.ability.extra.bonus) }
        end
    end,
}

-- 祸水：高风险高回报
SMODS.Joker {
    key = 'huo_shui', discovered = true, atlas = 'blh_joker', pos = { x = 0, y = 3 }, rarity = 1, cost = 5,
    config = { extra = { odds = 2, xmult = 1.5, penalty = 0.05 } },
    loc_txt = loc('祸水-肖冉', 'Bane - Xiao Ran',
        { '每次计分 {C:green}#1#/#2#{} 概率 {X:mult,C:white}×#3#{}倍率，', '否则本盲注所需分数 {C:red}+#4#{}' },
        { '{C:green}#1# in #2#{} chance each hand for {X:mult,C:white}×#3#{} Mult,', 'otherwise this Blind needs {C:red}+#4#{} more score' }),
    loc_vars = function(self, iq, card)
        local n, d = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'blh_huoshui')
        return { vars = { n, d, card.ability.extra.xmult, tostring(card.ability.extra.penalty * 100) .. '%' } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and not context.blueprint then
            if SMODS.pseudorandom_probability(card, 'blh_huoshui', 1, card.ability.extra.odds) then
                return { xmult = card.ability.extra.xmult, message = localize('blh_msg_lucky') }
            end
            -- 官方文档：返回 xblindsize 即乘算当前盲注需求，比手改 chips 更规范
            return { xblindsize = 1 + card.ability.extra.penalty, message = localize('k_nope_ex') }
        end
    end,
}

-- 入梦：手牌上限成长
SMODS.Joker {
    key = 'ru_meng', discovered = true, atlas = 'blh_joker', pos = { x = 1, y = 3 }, rarity = 1, cost = 6,
    config = { extra = { odds = 4, count = 0, cap = 3 } },
    loc_txt = loc('入梦-程敖宇', 'Dreamwalk - Cheng Aoyu',
        { '回合结束 {C:green}#1#/#2#{} 概率手牌上限 {C:attention}+1{}', '{C:inactive}（本牌已触发 #3#/#4#，整局最多 #4# 次）' },
        { '{C:green}#1# in #2#{} chance at end of round for {C:attention}+1{} hand size', '{C:inactive}(Triggered #3#/#4# times this run)' }),
    loc_vars = function(self, iq, card)
        local n, d = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'blh_rumeng')
        return { vars = { n, d, card.ability.extra.count, card.ability.extra.cap } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.game_over and not context.blueprint
            and not context.individual and not context.repetition then
            local extra = card.ability.extra
            if extra.count < extra.cap
                and SMODS.pseudorandom_probability(card, 'blh_rumeng' .. tostring(extra.count), 1, extra.odds) then
                extra.count = extra.count + 1
                G.hand:change_size(1)
                return { message = localize('k_upgrade_ex'), colour = G.C.BLUE }
            end
        end
    end,
}

-- 因果：未弃牌则倍率
SMODS.Joker {
    key = 'yin_guo', discovered = true, atlas = 'blh_joker', pos = { x = 2, y = 3 }, rarity = 1, cost = 6,
    config = { extra = { xmult = 1.5, chips = 15 } },
    loc_txt = loc('因果-江若雪', 'Causality - Jiang Ruoxue',
        { '本回合未弃过牌时 {X:mult,C:white}×#1#{}倍率，', '否则 {C:chips}+#2#{}筹码' },
        { '{X:mult,C:white}×#1#{} Mult if you have not discarded this round,', 'otherwise {C:chips}+#2#{} Chips' }),
    loc_vars = function(self, iq, card) return { vars = { card.ability.extra.xmult, card.ability.extra.chips } } end,
    calculate = function(self, card, context)
        if context.discard then card.ability.extra.discarded = true end
        if context.before and not context.blueprint then card.ability.extra.discarded = false end
        if context.joker_main then
            if card.ability.extra.discarded then
                return { chips = card.ability.extra.chips }
            end
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

--==============================================================
-- 3.5 免伤与存续
--==============================================================

-- 替罪：弃牌换钱
SMODS.Joker {
    key = 'ti_zui', discovered = true, atlas = 'blh_joker', pos = { x = 3, y = 3 }, rarity = 1, cost = 5,
    config = { extra = { dollars = 1 } },
    loc_txt = loc('替罪-陈俊南', 'Scapegoat - Chen Junnan',
        { '每弃掉 1 张牌获得 {C:money}$#1#{}' },
        { 'Earn {C:money}$#1#{} for each card discarded' }),
    loc_vars = function(self, iq, card) return { vars = { card.ability.extra.dollars } } end,
    calculate = function(self, card, context)
        if context.discard and not context.blueprint and not context.other_card.debuff then
            ease_dollars(card.ability.extra.dollars)
            return { message = localize('blh_msg_dollars') .. card.ability.extra.dollars, colour = G.C.MONEY }
        end
    end,
}

-- 嫁祸：debuff 转移给小丑
SMODS.Joker {
    key = 'jia_huo', discovered = true, atlas = 'blh_joker', pos = { x = 4, y = 3 }, rarity = 1, cost = 5,
    config = { extra = { odds = 3 } },
    loc_txt = loc('嫁祸-陆潇潇', 'Shift Blame - Lu Xiaoxiao',
        { '计分时 {C:green}#1#/#2#{} 概率', '让本盲注的限制改为失效 1 张小丑牌' },
        { '{C:green}#1# in #2#{} chance on scoring to make', 'this Blind debuff a random Joker instead of your cards' }),
    loc_vars = function(self, iq, card)
        local n, d = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'blh_jiahuo')
        return { vars = { n, d } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and G.GAME.blind and G.GAME.blind.boss then
            if SMODS.pseudorandom_probability(card, 'blh_jiahuo', 1, card.ability.extra.odds) then
                G.GAME.blind:disable()
                local pool = {}
                for _, j in ipairs(G.jokers.cards) do if j ~= card and not j.ability.eternal then pool[#pool + 1] = j end end
                local victim = pseudorandom_element(pool, pseudoseed('blh_jiahuo' .. tostring(G.GAME.round or 0)))
                if victim then victim.debuff = true end
                return { message = localize('k_nope_ex'), colour = G.C.RED }
            end
        end
    end,
}

-- 忘忧：免疫 debuff 但降分
SMODS.Joker {
    key = 'wang_you', discovered = true, atlas = 'blh_joker', pos = { x = 5, y = 3 }, rarity = 1, cost = 5,
    config = { extra = { penalty = 0.8 } },
    loc_txt = loc('忘忧-罗十一', 'Forget Sorrow - Luo Shiyi',
        { '你的牌不会被任何效果 {C:attention}失效{}，', '但所有计分 {X:mult,C:white}×#1#{}倍率' },
        { 'Your cards are never debuffed,', 'but all scoring is {X:mult,C:white}×#1#{} Mult' }),
    loc_vars = function(self, iq, card) return { vars = { card.ability.extra.penalty } } end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { xmult = card.ability.extra.penalty, message = localize('blh_msg_immune') }
        end
    end,
}

-- 不灭：每局一次免死（由 economy 的 saved 机制触发）
SMODS.Joker {
    key = 'bu_mie', discovered = true, atlas = 'blh_joker', pos = { x = 0, y = 4 }, rarity = 1, cost = 6,
    config = { extra = { used = false } },
    loc_txt = loc('不灭-姜十', 'Immortal - Jiang Shi',
        { '每局第一次分数不足时不会失败', '{C:inactive}（代价：手牌上限 -1）' },
        { 'The first time you fail to meet a Blind, you survive', '{C:inactive}(Cost: -1 hand size)' }),
    -- 主路径由 mod.calculate 统一处理（26.829.0 的免死入口）；这里是兜底。
    -- 必须仅在 mod 级入口不可用时兜底：否则同一 pass 内本牌先于 mod.calculate 触发时，
    -- 会绕过 economy 的 充能 → 不灭 → 赌命 优先级，直接扣掉手牌上限。
    calculate = function(self, card, context)
        if context.end_of_round and context.game_over and not context.blueprint
            and not (SMODS.current_mod and SMODS.current_mod.calculate)
            and not G.GAME.blh_saved_round and not card.ability.extra.used then
            card.ability.extra.used = true
            G.GAME.blh_saved_round = true
            SMODS.saved = true
            G.hand:change_size(-1)
            return { saved = true, message = localize('blh_bumie_ex'), colour = G.C.BLUE }
        end
    end,
}

-- 天行健：未弃牌加成
SMODS.Joker {
    key = 'tian_xing_jian', discovered = true, atlas = 'blh_joker', pos = { x = 1, y = 4 }, rarity = 2, cost = 7,
    config = { extra = { mult = 15, chips = 40 } },
    loc_txt = loc('天行健-张山', 'Self-Strength - Zhang Shan',
        { '回合结束未弃过牌则 {C:mult}+#1#{}倍率，', '弃过牌则 {C:chips}+#2#{}筹码' },
        { '{C:mult}+#1#{} Mult if you discarded nothing this round,', 'otherwise {C:chips}+#2#{} Chips' }),
    loc_vars = function(self, iq, card) return { vars = { card.ability.extra.mult, card.ability.extra.chips } } end,
    calculate = function(self, card, context)
        if context.discard then card.ability.extra.discarded = true end
        if context.before and not context.blueprint then card.ability.extra.discarded = false end
        if context.joker_main then
            if card.ability.extra.discarded then
                return { chips = card.ability.extra.chips }
            end
            return { mult = card.ability.extra.mult }
        end
    end,
}

--==============================================================
-- 3.6 节奏与操控
--==============================================================

-- 跃迁：用消耗品换出牌次数
SMODS.Joker {
    key = 'yue_qian', discovered = true, atlas = 'blh_joker', pos = { x = 2, y = 4 }, rarity = 1, cost = 6,
    config = { extra = { cap = 2, count = 0 } },
    loc_txt = loc('跃迁-金元勋', 'Warp - Jin Yuanxun',
        { '每使用 1 张消耗品，返还 {C:attention}1{} 次出牌次数', '{C:inactive}（每回合最多 #1# 次）' },
        { 'Each consumable used refunds {C:attention}1{} Hand', '{C:inactive}(max #1# per round)' }),
    loc_vars = function(self, iq, card) return { vars = { card.ability.extra.cap } } end,
    calculate = function(self, card, context)
        if context.using_consumeable and not context.blueprint then
            local extra = card.ability.extra
            if (extra.count or 0) < extra.cap then
                extra.count = (extra.count or 0) + 1
                ease_hands_played(1)
                return { message = localize('blh_msg_hand'), colour = G.C.BLUE }
            end
        end
        if context.before and not context.blueprint then card.ability.extra.count = 0 end
    end,
}

-- 夺心魄：强制配对
SMODS.Joker {
    key = 'duo_xin_po', discovered = true, atlas = 'blh_joker', pos = { x = 3, y = 4 }, rarity = 2, cost = 7,
    config = { extra = {} },
    loc_txt = loc('夺心魄-燕知春', 'Mind Snatch - Yan Zhichun',
        { '每回合首次出牌前，把手中点数最高的牌', '改为与另一张手牌同点数' },
        { 'Before the first hand each round, set your highest-rank', 'card to match another card in hand' }),
    calculate = function(self, card, context)
        if context.before and not context.blueprint and once(card) then
            local high, other
            for _, c in ipairs(G.hand.cards) do
                if not high or c.base.id > high.base.id then high = c end
            end
            for _, c in ipairs(G.hand.cards) do
                if c ~= high then other = c break end
            end
            if high and other then
                SMODS.change_base(high, nil, RANK_KEY[other.base.id])
                return { message = localize('k_upgrade_ex'), colour = G.C.MULT }
            end
        end
    end,
}

-- 传音：复制左邻小丑的 +Mult
SMODS.Joker {
    key = 'chuan_yin', discovered = true, atlas = 'blh_joker', pos = { x = 4, y = 4 }, rarity = 1, cost = 6,
    config = { extra = {} },
    loc_txt = loc('传音-周末', 'Voice Relay - Zhou Mo',
        { '计分时复制{C:attention}左侧相邻{}小丑牌的', '{C:mult}+倍率{}一次' },
        { 'Copies the {C:mult}+Mult{} of the Joker', 'to its immediate {C:attention}left{} once per hand' }),
    calculate = function(self, card, context)
        if context.joker_main and not context.blueprint then
            local idx
            for i, j in ipairs(G.jokers.cards) do if j == card then idx = i break end end
            if idx and idx > 1 then
                local left = G.jokers.cards[idx - 1]
                if left and left.calculate then
                    local eff = left:calculate_joker({ joker_main = true, blueprint_card = card })
                    if eff and eff.mult then
                        return { mult = eff.mult, message = localize('k_duplicated_ex'), colour = G.C.MULT }
                    end
                end
            end
        end
    end,
}

-- 挪移：弃牌回手
SMODS.Joker {
    key = 'nuo_yi', discovered = true, atlas = 'blh_joker', pos = { x = 5, y = 4 }, rarity = 1, cost = 6,
    config = { extra = { odds = 4 } },
    loc_txt = loc('挪移-马十二', 'Displace - Ma Shier',
        { '弃牌时 {C:green}#1#/#2#{} 概率该牌回到手牌', '{C:inactive}（不消耗该次弃牌）' },
        { '{C:green}#1# in #2#{} chance a discarded card returns to hand', '{C:inactive}(the discard is refunded)' }),
    loc_vars = function(self, iq, card)
        local n, d = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'blh_nuoyi')
        return { vars = { n, d } }
    end,
    calculate = function(self, card, context)
        if context.discard and not context.blueprint and not context.other_card.debuff then
            if SMODS.pseudorandom_probability(card, 'blh_nuoyi' .. tostring(context.other_card.sort_id or 0), 1, card.ability.extra.odds) then
                local target = context.other_card
                G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.15, func = function()
                    if G.hand and #G.hand.cards < G.hand.config.card_limit and target.area == G.discard then
                        G.discard:remove_card(target)
                        G.hand:emplace(target)
                        ease_discard(1)   -- 与描述一致：不消耗该次弃牌
                    end
                    return true
                end }))
                return { message = localize('k_again_ex'), colour = G.C.BLUE }
            end
        end
    end,
}
