--- 终焉之地 · 5 个封印（Seal）
--- 替换原版红/蓝/金/紫封印

SMODS.Atlas { key = 'blh_seal', path = 'blh_seal.png', px = 71, py = 95 }

local BLH = SMODS.current_mod.blh

local function loc(zh_name, en_name, zh_text, en_text)
    return { ['zh_CN'] = { label = zh_name, name = zh_name, text = zh_text },
             ['en-us'] = { label = en_name, name = en_name, text = en_text } }
end

-- 道印：打出时给道
SMODS.Seal {
    key = 'dao', atlas = 'blh_seal', pos = { x = 0, y = 0 }, badge_colour = HEX('d9b24a'),
    config = { dao = 5 },
    loc_txt = loc('道印', 'Dao Seal', { '打出时获得 {C:money}#1#{} 道' }, { 'Gain {C:money}#1#{} Dao when played' }),
    loc_vars = function(self, iq, card) return { vars = { card.ability.seal.dao } } end,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            BLH.add_dao(card.ability.seal.dao)
            return { message = '+' .. card.ability.seal.dao .. ' ' .. localize('blh_dao_name'), colour = G.C.GOLD }
        end
    end,
}

-- 玉印：打出时给钱
SMODS.Seal {
    key = 'yu', atlas = 'blh_seal', pos = { x = 1, y = 0 }, badge_colour = HEX('5fbf8a'),
    config = { dollars = 3 },
    loc_txt = loc('玉印', 'Jade Seal', { '打出时获得 {C:money}$#1#{}' }, { 'Gain {C:money}$#1#{} when played' }),
    loc_vars = function(self, iq, card) return { vars = { card.ability.seal.dollars } } end,
    calculate = function(self, card, context)
        -- 只 return：dollars 是 SMODS calculation_key，引擎会结算一次；
        -- 再手调 ease_dollars 会变成双倍给钱（UI 仍只显示一份）
        if context.main_scoring and context.cardarea == G.play then
            return { dollars = card.ability.seal.dollars }
        end
    end,
}

-- 涡印：弃掉时生成塔罗
SMODS.Seal {
    key = 'wo', atlas = 'blh_seal', pos = { x = 2, y = 0 }, badge_colour = HEX('7c6bd6'),
    config = {},
    loc_txt = loc('涡印', 'Vortex Seal', { '弃掉时生成 {C:attention}1{} 张随机塔罗牌' }, { 'Creates {C:attention}1{} random Tarot when discarded' }),
    calculate = function(self, card, context)
        -- 关键守卫：discard 上下文会对**手牌中每张牌**派发一次（other_card 才是被弃的那张），
        -- 少了这个判断 = 手牌里每张涡印牌都触发一次（原版紫印：card.lua:2618）
        if context.discard and context.other_card == card
            and #G.consumeables.cards < G.consumeables.config.card_limit then
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
                -- 事件内复查：判定到事件执行之间可能已被别的效果占满
                if #G.consumeables.cards < G.consumeables.config.card_limit then
                    local c = create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'blh_wo_seal')
                    c:add_to_deck()
                    G.consumeables:emplace(c)
                end
                return true
            end }))
            return { message = localize('blh_msg_tarot'), colour = G.C.SECONDARY_SET.Tarot }
        end
    end,
}

-- 生肖印：再触发一次
SMODS.Seal {
    key = 'zodiac', atlas = 'blh_seal', pos = { x = 3, y = 0 }, badge_colour = HEX('c94f4f'),
    config = {},
    loc_txt = loc('生肖印', 'Zodiac Seal', { '打出时额外触发 {C:attention}1{} 次' }, { 'Retriggers this card {C:attention}1{} time' }),
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play then
            return { message = localize('k_again_ex'), repetitions = 1, card = card }
        end
    end,
}

-- 神兽印：Chips 与金钱
SMODS.Seal {
    key = 'beast', atlas = 'blh_seal', pos = { x = 4, y = 0 }, badge_colour = HEX('4f8fc9'),
    config = { chips = 10, dollars = 2 },
    loc_txt = loc('神兽印', 'Beast Seal',
        { '打出时 {C:chips}+#1#{}筹码 与 {C:money}$#2#{}' },
        { '{C:chips}+#1#{} Chips and {C:money}$#2#{} when played' }),
    loc_vars = function(self, iq, card) return { vars = { card.ability.seal.chips, card.ability.seal.dollars } } end,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            -- 同玉印：钱只通过 return 结算，避免双倍
            return { chips = card.ability.seal.chips, dollars = card.ability.seal.dollars }
        end
    end,
}
