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

-- 本模组的小丑 key 列表。
-- 注意：SMODS.Jokers 在 26.829.0 并不存在（只有 SMODS.Tags/Seals/Stickers/Atlases），
-- 用它建池会得到空表 → 标签"获得后立刻消耗"却什么也没给。
local function our_joker_keys()
    local out = {}
    for _, pool in ipairs(G.P_JOKER_RARITY_POOLS or {}) do
        for _, j in ipairs(pool) do
            if j.mod == SMODS.current_mod then out[#out + 1] = j.key end
        end
    end
    if #out == 0 then
        for _, c in pairs(G.P_CENTERS or {}) do
            if c.mod == SMODS.current_mod and c.set == 'Joker' then out[#out + 1] = c.key end
        end
    end
    return out
end

local function card_init_ok()
    -- 注意：Card 是「可调用表」（engine/object.lua 的 __call），type(Card) == 'table'，
    -- 不能写成 type(Card) == 'function'（那样真机上永远为 false）
    return Card ~= nil and type(create_shop_card_ui) == 'function' and G.P_CARDS ~= nil
end

-- 商店里额外加一张**免费**优惠券。照抄原版 Voucher Tag 的加券路径（/tmp/dump/dump/tag.lua:322-340），
-- 并显式补 couponed / cost=0 —— 原版那段依赖 G.ARGS.voucher_tag 窗口，语义不明确，显式置 0 更稳。
local function add_free_voucher()
    if not (G.shop_vouchers and type(get_next_voucher_key) == 'function' and card_init_ok()) then return false end
    local key = get_next_voucher_key(true)
    if not key or key == 'UNAVAILABLE' or not G.P_CENTERS[key] then return false end
    G.ARGS = G.ARGS or {}
    G.ARGS.voucher_tag = G.ARGS.voucher_tag or {}
    G.ARGS.voucher_tag[key] = true
    G.shop_vouchers.config.card_limit = G.shop_vouchers.config.card_limit + 1
    local card = Card(G.shop_vouchers.T.x + G.shop_vouchers.T.w / 2, G.shop_vouchers.T.y,
        G.CARD_W, G.CARD_H, G.P_CARDS.empty, G.P_CENTERS[key],
        { bypass_discovery_center = true, bypass_discovery_ui = true })
    card.from_tag = true
    card.ability.couponed = true
    card.cost = 0
    create_shop_card_ui(card, 'Voucher', G.shop_vouchers)
    card:start_materialize()
    G.shop_vouchers:emplace(card)
    G.ARGS.voucher_tag = nil
    return true
end

-- 栏位满时给个提示，别让标签"获得后立刻消耗却毫无反馈"
local function nope()
    if type(attention_text) == 'function' then
        attention_text({ text = localize('k_no_space_ex'), scale = 0.8, hold = 1, align = 'cm', silent = true })
    end
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
    loc_txt = loc('牛·负力', 'Ox: Endurance', { '下一次出牌回合 {C:attention}+1{} 出牌次数' }, { 'Next played round: {C:attention}+1{} Hand' }),
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.BLUE, function()
            -- 必须写进 round_bonus：跳过盲注时 new_round() 还没执行，
            -- 直接 ease_hands_played 会被下一次 new_round 的重置抹掉（标签白消耗）
            G.GAME.round_bonus = G.GAME.round_bonus or {}
            G.GAME.round_bonus.next_hands = (G.GAME.round_bonus.next_hands or 0) + 1
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
    loc_txt = loc('虎·强势', 'Tiger: Dominance', { '重掷本{C:attention}Boss{}盲注' }, { 'Rerolls this {C:attention}Boss Blind{}' }),
    -- 必须走原版 Boss Tag 的路径：只改 blind_choices.Boss 不会重建已生成的盲选 UI，
    -- 会出现"显示 A、实际打 B"；G.from_boss_tag = true 同时豁免原版的 -$10
    -- （原版实现见 /tmp/dump/dump/tag.lua:305-321、button_callbacks.lua:2901-2965）
    apply = function(self, tag, context)
        if context.type ~= 'new_blind_choice' then return end
        local lock = tostring(tag.ID or tag.key or 'blh_tiger')
        if G.CONTROLLER and G.CONTROLLER.locks then G.CONTROLLER.locks[lock] = true end
        tag:yep('+', G.C.RED, function()
            G.from_boss_tag = true
            if type(G.FUNCS.reroll_boss) == 'function' then
                G.FUNCS.reroll_boss()
            elseif G.GAME.round_resets.blind_choices then
                G.GAME.round_resets.blind_choices.Boss = get_new_boss()
            end
            G.E_MANAGER:add_event(Event({ func = function()
                G.E_MANAGER:add_event(Event({ func = function()
                    if G.CONTROLLER and G.CONTROLLER.locks then G.CONTROLLER.locks[lock] = nil end
                    return true
                end }))
                return true
            end }))
            return true
        end)
        tag.triggered = true
        return true
    end,
}

-- 兔·脱身：+2 弃牌
SMODS.Tag {
    key = 'rabbit_escape', atlas = 'blh_tag', pos = { x = 3, y = 0 },
    config = { type = 'immediate' },
    loc_txt = loc('兔·脱身', 'Rabbit: Escape', { '下一次出牌回合 {C:attention}+2{} 弃牌次数' }, { 'Next played round: {C:attention}+2{} Discards' }),
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.BLUE, function()
            -- 同牛·负力：走 round_bonus 才能撑到下一个回合
            G.GAME.round_bonus = G.GAME.round_bonus or {}
            G.GAME.round_bonus.discards = (G.GAME.round_bonus.discards or 0) + 2
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
    loc_txt = loc('马·竞速', 'Horse: Race',
        { '本局每打出过 {C:attention}1{} 次牌型获得 {C:money}#1#{} 道' },
        { 'Gain {C:money}#1#{} Dao for each hand you have played this run' }),
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
        local pool = our_joker_keys()
        if #pool > 0 then
            if G.jokers and #G.jokers.cards < G.jokers.config.card_limit then
                add_joker(pseudorandom_element(pool, pseudoseed('blh_monkey_tag')), 'blh_mtag')
            else
                nope()
            end
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
            if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
                add_consumable('Tarot', pseudorandom_element(pool, pseudoseed('blh_rooster_tag')), 'blh_rtag')
            else
                nope()
            end
        end
        tag.triggered = true
        return true
    end,
}

-- 狗·传信：免费优惠券
SMODS.Tag {
    key = 'dog_letter', atlas = 'blh_tag', pos = { x = 2, y = 1 },
    config = { type = 'voucher_add' },
    loc_txt = loc('狗·传信', 'Dog: Letter',
        { '商店中额外出现 {C:attention}1{} 张{C:attention}免费{}优惠券' },
        { 'Adds {C:attention}1{} {C:attention}free{} Voucher to the shop' }),
    -- 原版 Voucher Tag 的加券逻辑被 `self.name == 'Voucher Tag'` 挡住（/tmp/dump/dump/tag.lua:323），
    -- 所以本模组的 voucher_add 标签必须自己实现，否则只播动画、零效果
    apply = function(self, tag, context)
        if context.type ~= 'voucher_add' then return end
        tag:yep('+', G.C.GOLD, function() return true end)
        add_free_voucher()
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
    loc_txt = loc('白虎·调停', 'Baihu: Mediation',
        { '下一个{C:attention}Boss盲注{}的限制被解除', '{C:inactive}（该盲注进场时生效）' },
        { 'Removes the restriction of the next {C:attention}Boss Blind{}', '{C:inactive}(takes effect when it starts)' }),
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end
        tag:yep('+', G.C.RED, function()
            -- 跳过盲注时"当前盲注"已经打完了：直接 disable() 会作用在旧盲注上，
            -- 而且旧盲注 chips 已满足时还会把状态推成 NEW_ROUND。
            -- 改为挂起，等下一个盲注 set_blind 之后（context.setting_blind）再解除。
            G.GAME.blh_break_blind = true
            return true
        end)
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
        -- 只有真的摧毁了才给钱（无小丑 / 抽到永恒小丑时白拿 $30 属实现漏洞）
        local victim = nil
        if G.jokers and #G.jokers.cards > 0 then
            local pick = pseudorandom_element(G.jokers.cards, pseudoseed('blh_zhuque_tag'))
            if pick and not (pick.ability and pick.ability.eternal) then victim = pick end
        end
        if victim then
            SMODS.destroy_cards(victim)
            ease_dollars(self.config.dollars)
        else
            nope()
        end
        tag.triggered = true
        return true
    end,
}

-- 青龙·之首：优惠券 + 负片小丑
SMODS.Tag {
    key = 'qinglong_head', atlas = 'blh_tag', pos = { x = 7, y = 1 },
    -- 改为 voucher_add：免费券必须在**商店创建时**加（原版 Voucher Tag 同类型）。
    -- 绝不能写 G.GAME.current_round.voucher = nil —— 26.829.0 的新商店代码会无条件读
    -- .spawn（/tmp/dump/dump/game.lua:3329），置 nil 会让进商店报错中断。
    config = { type = 'voucher_add' },
    loc_txt = loc('青龙·之首', 'Qinglong: The Head',
        { '商店中额外出现 {C:attention}1{} 张{C:attention}免费{}优惠券', '并获得 {C:dark_edition}1{} 张负片小丑牌' },
        { 'Adds {C:attention}1{} {C:attention}free{} Voucher to the shop', 'and grants {C:dark_edition}1{} Negative Joker' }),
    apply = function(self, tag, context)
        if context.type ~= 'voucher_add' then return end
        tag:yep('+', G.C.PURPLE, function() return true end)
        add_free_voucher()
        local pool = our_joker_keys()
        -- 不检查 card_limit：负片小丑自带 +1 槽位（原版同样豁免，card.lua:5021）
        if #pool > 0 and G.jokers then
            local key = pseudorandom_element(pool, pseudoseed('blh_qinglong_tag'))
            local card = create_card('Joker', G.jokers, nil, nil, nil, nil, key, 'blh_qtag')
            card:set_edition('e_negative', true)
            card:add_to_deck()
            G.jokers:emplace(card)
        end
        tag.triggered = true
        return true
    end,
}
