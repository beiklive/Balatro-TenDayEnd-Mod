--- 终焉之地 · 16 张优惠券（8 组，含升级链）
--- 图集：8 列 × 2 行

SMODS.Atlas { key = 'blh_voucher', path = 'blh_voucher.png', px = 71, py = 95 }

local function loc(zh_name, en_name, zh_text, en_text)
    return { ['zh_CN'] = { name = zh_name, text = zh_text }, ['en-us'] = { name = en_name, text = en_text } }
end

local function voucher(cfg)
    SMODS.Voucher(cfg)
end

------------------------------------------------------------------
-- 1. 面试房间协作合同
------------------------------------------------------------------
voucher {
    key = 'interview_contract', atlas = 'blh_voucher', pos = { x = 0, y = 0 }, cost = 10, discovered = true,
    config = { extra = 1 },
    loc_txt = loc('面试房间协作合同', 'Interview Room Contract',
        { '每回合 {C:red}+#1#{} 出牌次数' }, { '{C:red}+#1#{} Hand per round' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card) G.GAME.round_resets.hands = G.GAME.round_resets.hands + self.config.extra end,
}
voucher {
    key = 'interview_contract_plus', atlas = 'blh_voucher', pos = { x = 0, y = 1 }, cost = 10, discovered = true,
    config = { extra = 1 }, requires = { 'v_blh_interview_contract' },
    loc_txt = loc('深度协作', 'Deep Collaboration',
        { '每回合再 {C:red}+#1#{} 出牌次数' }, { '{C:red}+#1#{} more Hand per round' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card) G.GAME.round_resets.hands = G.GAME.round_resets.hands + self.config.extra end,
}

------------------------------------------------------------------
-- 2. 良人守则
------------------------------------------------------------------
voucher {
    key = 'goodman_rules', atlas = 'blh_voucher', pos = { x = 1, y = 0 }, cost = 10, discovered = true,
    config = { extra = 1 },
    loc_txt = loc('良人守则', 'Rules of the Good',
        { '每回合 {C:red}+#1#{} 弃牌次数' }, { '{C:red}+#1#{} Discard per round' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card) G.GAME.round_resets.discards = G.GAME.round_resets.discards + self.config.extra end,
}
voucher {
    key = 'goodman_rules_plus', atlas = 'blh_voucher', pos = { x = 1, y = 1 }, cost = 10, discovered = true,
    config = { extra = 1 }, requires = { 'v_blh_goodman_rules' },
    loc_txt = loc('良人守则·补', 'Rules of the Good+',
        { '每回合再 {C:red}+#1#{} 弃牌次数' }, { '{C:red}+#1#{} more Discard per round' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card) G.GAME.round_resets.discards = G.GAME.round_resets.discards + self.config.extra end,
}

------------------------------------------------------------------
-- 3. 生肖守则
------------------------------------------------------------------
voucher {
    key = 'zodiac_rules', atlas = 'blh_voucher', pos = { x = 2, y = 0 }, cost = 10, discovered = true,
    config = { extra = 1 },
    loc_txt = loc('生肖守则', 'Zodiac Code', { '手牌上限 {C:attention}+#1#{}' }, { 'Hand size {C:attention}+#1#{}' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card) G.hand:change_size(self.config.extra) end,
}
voucher {
    key = 'zodiac_rules_plus', atlas = 'blh_voucher', pos = { x = 2, y = 1 }, cost = 10, discovered = true,
    config = { extra = 1 }, requires = { 'v_blh_zodiac_rules' },
    loc_txt = loc('生肖守则·飞升', 'Zodiac Code+', { '手牌上限再 {C:attention}+#1#{}' }, { 'Hand size {C:attention}+#1#{} more' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card) G.hand:change_size(self.config.extra) end,
}

------------------------------------------------------------------
-- 4. 生肖飞升对赌合同
------------------------------------------------------------------
voucher {
    key = 'ascension_pact', atlas = 'blh_voucher', pos = { x = 3, y = 0 }, cost = 10, discovered = true,
    config = { extra = 1 },
    loc_txt = loc('生肖飞升对赌合同', 'Ascension Pact', { '小丑牌槽位 {C:attention}+#1#{}' }, { '{C:attention}+#1#{} Joker slot' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card) G.jokers.config.card_limit = G.jokers.config.card_limit + self.config.extra end,
}
voucher {
    key = 'ascension_pact_plus', atlas = 'blh_voucher', pos = { x = 3, y = 1 }, cost = 10, discovered = true,
    config = { extra = 1 }, requires = { 'v_blh_ascension_pact' },
    loc_txt = loc('对赌合同·终', 'Final Pact', { '小丑牌槽位再 {C:attention}+#1#{}' }, { '{C:attention}+#1#{} more Joker slot' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card) G.jokers.config.card_limit = G.jokers.config.card_limit + self.config.extra end,
}

------------------------------------------------------------------
-- 5. 眼球移植
------------------------------------------------------------------
voucher {
    key = 'eye_transplant', atlas = 'blh_voucher', pos = { x = 4, y = 0 }, cost = 10, discovered = true,
    config = { extra = 1 },
    loc_txt = loc('眼球移植', 'Eye Transplant', { '消耗品槽位 {C:attention}+#1#{}' }, { '{C:attention}+#1#{} Consumable slot' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card) G.consumeables.config.card_limit = G.consumeables.config.card_limit + self.config.extra end,
}
voucher {
    key = 'eye_transplant_plus', atlas = 'blh_voucher', pos = { x = 4, y = 1 }, cost = 10, discovered = true,
    config = { extra = 1 }, requires = { 'v_blh_eye_transplant' },
    loc_txt = loc('双眼移植', 'Dual Transplant', { '消耗品槽位再 {C:attention}+#1#{}' }, { '{C:attention}+#1#{} more Consumable slot' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card) G.consumeables.config.card_limit = G.consumeables.config.card_limit + self.config.extra end,
}

------------------------------------------------------------------
-- 6. 面具
------------------------------------------------------------------
voucher {
    key = 'mask', atlas = 'blh_voucher', pos = { x = 5, y = 0 }, cost = 10, discovered = true,
    config = { extra = 1 },
    loc_txt = loc('面具', 'The Mask', { '商店刷新费用 {C:money}-$#1#{}' }, { 'Reroll cost {C:money}-$#1#{}' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card)
        -- 原版 v_reroll_surplus 同时改 round_resets 与 current_round 并立即重算：
        -- 只改 round_resets 的话当前商店仍显示原价（要等下回合 new_round 才降）。
        -- base_reroll_cost 在 26.829.0 全源码只有写没有读 → 死写，已删除。
        G.GAME.round_resets.reroll_cost = math.max(0, G.GAME.round_resets.reroll_cost - self.config.extra)
        if G.GAME.current_round then
            G.GAME.current_round.reroll_cost = math.max(0,
                (G.GAME.current_round.reroll_cost or G.GAME.round_resets.reroll_cost) - self.config.extra)
        end
        if type(calculate_reroll_cost) == 'function' then calculate_reroll_cost(true) end
    end,
}
voucher {
    key = 'mask_plus', atlas = 'blh_voucher', pos = { x = 5, y = 1 }, cost = 10, discovered = true,
    config = { extra = 1 }, requires = { 'v_blh_mask' },
    loc_txt = loc('永久回响者', 'Eternal Echoer', { '商店刷新费用再 {C:money}-$#1#{}' }, { 'Reroll cost {C:money}-$#1#{} more' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card)
        -- 原版 v_reroll_surplus 同时改 round_resets 与 current_round 并立即重算：
        -- 只改 round_resets 的话当前商店仍显示原价（要等下回合 new_round 才降）。
        -- base_reroll_cost 在 26.829.0 全源码只有写没有读 → 死写，已删除。
        G.GAME.round_resets.reroll_cost = math.max(0, G.GAME.round_resets.reroll_cost - self.config.extra)
        if G.GAME.current_round then
            G.GAME.current_round.reroll_cost = math.max(0,
                (G.GAME.current_round.reroll_cost or G.GAME.round_resets.reroll_cost) - self.config.extra)
        end
        if type(calculate_reroll_cost) == 'function' then calculate_reroll_cost(true) end
    end,
}

------------------------------------------------------------------
-- 7. 巨钟
------------------------------------------------------------------
voucher {
    key = 'bell_tower', atlas = 'blh_voucher', pos = { x = 6, y = 0 }, cost = 10, discovered = true,
    config = { extra = 1 },
    loc_txt = loc('巨钟', 'The Great Bell', { '商店商品位 {C:attention}+#1#{}' }, { '{C:attention}+#1#{} Shop slot' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    -- 原版 v_overstock 走 change_shop_size：它同时更新 shop.joker_max 与当前商店区域的
    -- card_limit；只改 joker_max 会让本商店不加位、商店内刷新还溢出 card_limit
    redeem = function(self, card)
        if type(change_shop_size) == 'function' then
            change_shop_size(self.config.extra)
        else
            G.GAME.shop.joker_max = G.GAME.shop.joker_max + self.config.extra
        end
    end,
}
voucher {
    key = 'bell_tower_plus', atlas = 'blh_voucher', pos = { x = 6, y = 1 }, cost = 10, discovered = true,
    config = { extra = 1 }, requires = { 'v_blh_bell_tower' },
    loc_txt = loc('钟鸣不止', 'Endless Chime', { '商店商品位再 {C:attention}+#1#{}' }, { '{C:attention}+#1#{} more Shop slot' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    -- 原版 v_overstock 走 change_shop_size：它同时更新 shop.joker_max 与当前商店区域的
    -- card_limit；只改 joker_max 会让本商店不加位、商店内刷新还溢出 card_limit
    redeem = function(self, card)
        if type(change_shop_size) == 'function' then
            change_shop_size(self.config.extra)
        else
            G.GAME.shop.joker_max = G.GAME.shop.joker_max + self.config.extra
        end
    end,
}

------------------------------------------------------------------
-- 8. 空间列车
------------------------------------------------------------------
voucher {
    key = 'space_train', atlas = 'blh_voucher', pos = { x = 7, y = 0 }, cost = 10, discovered = true,
    config = { extra = 20 },
    loc_txt = loc('空间列车', 'Void Train', { '立即获得 {C:money}$#1#{}' }, { 'Immediately gain {C:money}$#1#{}' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card) ease_dollars(self.config.extra) end,
}
voucher {
    key = 'space_train_plus', atlas = 'blh_voucher', pos = { x = 7, y = 1 }, cost = 10, discovered = true,
    config = { extra = 40 }, requires = { 'v_blh_space_train' },
    loc_txt = loc('永恒列车', 'Eternal Train', { '立即获得 {C:money}$#1#{}' }, { 'Immediately gain {C:money}$#1#{}' }),
    loc_vars = function(self) return { vars = { self.config.extra } } end,
    redeem = function(self, card) ease_dollars(self.config.extra) end,
}
