--- 终焉之地 · 5 个版本（Edition）
--- 保留原版负片；替换原版 Foil / Holo / Polychrome

local function loc(zh_name, en_name, zh_text, en_text)
    return { ['zh_CN'] = { name = zh_name, label = zh_name, text = zh_text },
             ['en-us'] = { name = en_name, label = en_name, text = en_text } }
end

-- 回响：打出计分牌后永久成长
SMODS.Edition {
    key = 'echo', discovered = true, atlas = 'blh_joker', pos = { x = 0, y = 5 }, prefix_config = { shader = false }, shader = 'foil', unlocked = true, in_shop = true, weight = 8, extra_cost = 4,
    config = { gain = 2 },
    loc_txt = loc('回响', 'Echo',
        { '每打出 1 张计分牌，本牌永久 {C:mult}+#1#{}倍率', '{C:inactive}（当前为{C:mult}+#2#{C:inactive}倍率）' },
        { 'Gains {C:mult}+#1#{} Mult permanently for each scored card', '{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)' }),
    loc_vars = function(self, iq, card)
        return { vars = { self.config.gain, card and card.ability.echo_mult or 0 } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            card.ability.echo_mult = (card.ability.echo_mult or 0) + self.config.gain
        end
        if context.joker_main and (card.ability.echo_mult or 0) > 0 then
            return { mult = card.ability.echo_mult }
        end
    end,
}

-- 清香：计分给钱
SMODS.Edition {
    key = 'fragrance', discovered = true, atlas = 'blh_joker', pos = { x = 1, y = 5 }, prefix_config = { shader = false }, shader = 'holo', unlocked = true, in_shop = true, weight = 8, extra_cost = 3,
    config = { dollars = 1 },
    loc_txt = loc('清香', 'Fragrance',
        { '每张计分牌获得 {C:money}$#1#{}' }, { 'Earn {C:money}$#1#{} for each scored card' }),
    loc_vars = function(self) return { vars = { self.config.dollars } } end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            ease_dollars(self.config.dollars)
        end
    end,
}

-- 波纹：倍率
SMODS.Edition {
    key = 'ripple', discovered = true, atlas = 'blh_joker', pos = { x = 2, y = 5 }, prefix_config = { shader = false }, shader = 'polychrome', unlocked = true, in_shop = true, weight = 5, extra_cost = 5,
    config = { xmult = 1.2 },
    loc_txt = loc('波纹', 'Ripple', { '计分时 {X:mult,C:white}×#1#{}倍率' }, { '{X:mult,C:white}×#1#{} Mult when scoring' }),
    loc_vars = function(self) return { vars = { self.config.xmult } } end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { xmult = self.config.xmult }
        end
    end,
}

-- 生肖：Chips
SMODS.Edition {
    key = 'zodiac', discovered = true, atlas = 'blh_joker', pos = { x = 3, y = 5 }, prefix_config = { shader = false }, shader = 'hologram', unlocked = true, in_shop = true, weight = 8, extra_cost = 3,
    config = { chips = 30 },
    loc_txt = loc('生肖', 'Zodiac', { '计分时 {C:chips}+#1#{}筹码' }, { '{C:chips}+#1#{} Chips when scoring' }),
    loc_vars = function(self) return { vars = { self.config.chips } } end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { chips = self.config.chips }
        end
    end,
}

-- 神兽：倍率 + 钱
SMODS.Edition {
    key = 'beast', discovered = true, atlas = 'blh_joker', pos = { x = 4, y = 5 }, prefix_config = { shader = false }, shader = 'foil', unlocked = true, in_shop = true, weight = 4, extra_cost = 6,
    config = { xmult = 1.1, dollars = 2 },
    loc_txt = loc('神兽', 'Divine Beast',
        { '计分时 {X:mult,C:white}×#1#{}倍率', '每张计分牌 +${#2#}' },
        { '{X:mult,C:white}×#1#{} Mult when scoring', '+${#2#} per scored card' }),
    loc_vars = function(self) return { vars = { self.config.xmult, self.config.dollars } } end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            ease_dollars(self.config.dollars)
        end
        if context.joker_main then
            return { xmult = self.config.xmult }
        end
    end,
}
