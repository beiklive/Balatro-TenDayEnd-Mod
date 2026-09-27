--- 终焉之地 · 5 个版本（Edition）
--- 保留原版负片；替换原版 Foil / Holo / Polychrome

local function loc(zh_name, en_name, zh_text, en_text)
    return { ['zh_CN'] = { name = zh_name, label = zh_name, text = zh_text },
             ['en-us'] = { name = en_name, label = en_name, text = en_text } }
end

-- 版本效果只有两个结算入口（device 证据）：
--   ① 小丑：functions/state_events.lua:682 传 {edition=true, pre_joker=true}、
--           :772 传 {edition=true, post_joker=true}；:689 会把 joker_main 里的 edition 显式置空。
--   ② 扑克牌：functions/common_events.lua:744-749 对任何带版本的卡调用 card:calculate_edition(context)，
--           计分主循环（SMODS.calculate_main_scoring）传的是 {main_scoring=true, cardarea=G.play}。
-- 原版三个版本的写法相同：SMODS/_/src/game_object.lua:3685/3718（foil/holo，pre_joker 或 main_scoring）、
-- :3751（polychrome，post_joker 或 main_scoring）。标准补充包会给扑克牌 roll 版本（card.lua:2103-2105），
-- 而版本池 cull 只看 in_shop（functions/common_events.lua:2271-2272）→ 本模组的版本也会落在扑克牌上，
-- 只认 pre/post_joker 会完全失效。
local function before_score(context)
    return context.pre_joker or (context.main_scoring and context.cardarea == G.play)
end
local function after_score(context)
    return context.post_joker or (context.main_scoring and context.cardarea == G.play)
end

-- 回响：打出计分牌后永久成长
SMODS.Edition {
    key = 'echo', discovered = true, atlas = 'blh_joker', pos = { x = 0, y = 5 }, prefix_config = { shader = false }, shader = 'foil', unlocked = true, in_shop = true, weight = 8, extra_cost = 4,
    config = { gain = 2 },
    loc_txt = loc('回响', 'Echo',
        { '每次出牌本牌永久 {C:mult}+#1#{}倍率', '{C:inactive}（当前为{C:mult}+#2#{C:inactive}倍率）' },
        { 'Gains {C:mult}+#1#{} Mult permanently each hand played', '{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)' }),
    -- 关键：版本效果只在 pre_joker / post_joker 两个上下文被结算
    -- （device: functions/state_events.lua:682 与 :772；
    --  同一文件 :689 会把 joker_main 里的 edition 显式置空 → 在 joker_main 返回一律无效）
    loc_vars = function(self, iq, card)
        local cur = (card and card.ability and card.ability.echo_mult) or 0
        return { vars = { self.config.gain, cur } }
    end,
    calculate = function(self, card, context)
        local ability = card and card.ability
        if not ability then return end
        if before_score(context) and not context.blueprint then
            ability.echo_mult = (ability.echo_mult or 0) + self.config.gain
            return { mult = ability.echo_mult }
        end
    end,
}

-- 清香：计分给钱
SMODS.Edition {
    key = 'fragrance', discovered = true, atlas = 'blh_joker', pos = { x = 1, y = 5 }, prefix_config = { shader = false }, shader = 'holo', unlocked = true, in_shop = true, weight = 8, extra_cost = 3,
    config = { dollars = 1 },
    loc_txt = loc('清香', 'Fragrance',
        { '每次出牌获得 {C:money}$#1#{}' }, { 'Earn {C:money}$#1#{} each hand played' }),
    loc_vars = function(self) return { vars = { self.config.dollars } } end,
    calculate = function(self, card, context)
        if before_score(context) then
            return { dollars = self.config.dollars }
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
        if after_score(context) then
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
        if before_score(context) then
            return { chips = self.config.chips }
        end
    end,
}

-- 神兽：倍率 + 钱
SMODS.Edition {
    key = 'beast', discovered = true, atlas = 'blh_joker', pos = { x = 4, y = 5 }, prefix_config = { shader = false }, shader = 'foil', unlocked = true, in_shop = true, weight = 4, extra_cost = 6,
    config = { xmult = 1.1, dollars = 2 },
    loc_txt = loc('神兽', 'Divine Beast',
        { '本牌计分时 {X:mult,C:white}×#1#{}倍率', '且每次出牌 +${#2#}' },
        { '{X:mult,C:white}×#1#{} Mult when scoring', 'and +${#2#} each hand played' }),
    loc_vars = function(self) return { vars = { self.config.xmult, self.config.dollars } } end,
    calculate = function(self, card, context)
        if after_score(context) then
            local ret = { xmult = self.config.xmult }
            -- 扑克牌上 main_scoring 同时满足两个条件，分开 return 会丢掉给钱那一段
            if before_score(context) then ret.dollars = self.config.dollars end
            return ret
        end
        if before_score(context) then
            return { dollars = self.config.dollars }
        end
    end,
}
