--- 终焉之地 · 5 个贴纸（Sticker）
--- 替换原版永恒 / 易腐 / 租赁；只作用于小丑牌
--- 图集：5 列 × 1 行（71×95）

SMODS.Atlas { key = 'blh_sticker', path = 'blh_sticker.png', px = 71, py = 95 }

local function loc(zh_name, en_name, zh_text, en_text)
    return { ['zh_CN'] = { label = zh_name, name = zh_name, text = zh_text },
             ['en-us'] = { label = en_name, name = en_name, text = en_text } }
end

-- 记忆保留：Chips
SMODS.Sticker {
    key = 'memory', atlas = 'blh_sticker', pos = { x = 0, y = 0 }, rate = 0.15,
    badge_colour = HEX('d9b24a'), sets = { Joker = true }, needs_enable_flag = true,
    config = { chips = 10 },
    loc_txt = loc('记忆保留', 'Memory Keeper', { '计分时 {C:chips}+#1#{}筹码' }, { '{C:chips}+#1#{} Chips when scoring' }),
    loc_vars = function(self) return { vars = { 10 } } end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { chips = 10 }
        end
    end,
}

-- 深度回响化：Mult（带成长上限 5 次）
SMODS.Sticker {
    key = 'deep_echo', atlas = 'blh_sticker', pos = { x = 1, y = 0 }, rate = 0.15,
    badge_colour = HEX('7c6bd6'), sets = { Joker = true }, needs_enable_flag = true,
    config = { mult = 3, cap = 5 },
    loc_txt = loc('深度回响化', 'Deep Echo',
        { '计分时 {C:mult}+#1#{}倍率', '{C:inactive}（最多叠加 #2# 次）' },
        { '{C:mult}+#1#{} Mult when scoring', '{C:inactive}(stacks up to #2# times)' }),
    loc_vars = function(self, iq, card) return { vars = { 3, 5 } } end,
    calculate = function(self, card, context)
        if context.joker_main then
            -- 文案写「最多叠加 #2# 次」：每次计分 +3，累计到 5 次（最高 +15）。
            -- 原实现只计数不参与计算，永远是 +3，计数器等于死状态。
            local hits = math.min((card.ability.blh_deep_echo_hits or 0) + 1, 5)
            card.ability.blh_deep_echo_hits = hits
            return { mult = 3 * hits }
        end
    end,
}

-- 原住民：Mult
SMODS.Sticker {
    key = 'native', atlas = 'blh_sticker', pos = { x = 2, y = 0 }, rate = 0.15,
    badge_colour = HEX('8a7f6a'), sets = { Joker = true }, needs_enable_flag = true,
    config = { mult = 12 },
    loc_txt = loc('原住民', 'Native', { '计分时 {C:mult}+#1#{}倍率' }, { '{C:mult}+#1#{} Mult when scoring' }),
    loc_vars = function(self) return { vars = { 12 } } end,
    calculate = function(self, card, context)
        if context.joker_main then return { mult = 12 } end
    end,
}

-- 蝼蚁：每张计分牌给钱
SMODS.Sticker {
    key = 'ant', atlas = 'blh_sticker', pos = { x = 3, y = 0 }, rate = 0.15,
    badge_colour = HEX('5fbf8a'), sets = { Joker = true }, needs_enable_flag = true,
    config = { dollars = 1 },
    loc_txt = loc('蝼蚁', 'Ant', { '每张计分牌获得 {C:money}$#1#{}' }, { 'Earn {C:money}$#1#{} for each scored card' }),
    loc_vars = function(self) return { vars = { 1 } } end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            ease_dollars(1)
        end
    end,
}

-- 面具：Mult
SMODS.Sticker {
    key = 'mask', atlas = 'blh_sticker', pos = { x = 4, y = 0 }, rate = 0.15,
    badge_colour = HEX('c94f4f'), sets = { Joker = true }, needs_enable_flag = true,
    config = { mult = 8 },
    loc_txt = loc('面具', 'Mask', { '计分时 {C:mult}+#1#{}倍率' }, { '{C:mult}+#1#{} Mult when scoring' }),
    loc_vars = function(self) return { vars = { 8 } } end,
    calculate = function(self, card, context)
        if context.joker_main then return { mult = 8 } end
    end,
}
