--- 终焉之地 · 十二生肖 Boss（12 张盲注）
--- 图集：34×34 动画图集，frames = 21
--- 按官方文档：y 决定用哪一行动画，x 被忽略并循环播放各帧
--- 因此摆图为 21 列（帧）× 12 行（盲注），pos = { x = 0, y = 索引 }

SMODS.Atlas {
    key = 'blh_blind', path = 'blh_blind.png', px = 34, py = 34,
    atlas_table = 'ANIMATION_ATLAS', frames = 21,
}

local BLH = SMODS.current_mod.blh

local function loc(zh_name, en_name, zh_text, en_text)
    return { ['zh_CN'] = { name = zh_name, text = zh_text }, ['en-us'] = { name = en_name, text = en_text } }
end

------------------------------------------------------------------
-- 施加 / 还原的统一约定（对齐设备版 blind.lua 的原版实现）
--
-- ① 效果只能挂在 vanilla 明确分派的钩子上。设备版 blind.lua 的分派点：
--    set_blind(191) / defeat(377) / disable(404) / press_play(507) /
--    modify_hand(553) / debuff_hand(565) / drawn_to_hand(620) /
--    recalc_debuff(689) / debuff_card(697)。
--    **没有 blind.calculate 的分派点**，所以计分修正要用 modify_hand、出牌时机用 press_play。
-- ② 会改动牌局状态的惩罚必须能被 disable 还原：本模组的「破万法」就是调用
--    G.GAME.blind:disable()，只施加不还原就会把惩罚永久留在牌局里。
-- ③ 还原必须扛得住读档：读档走 Blind:load，不会重新调用 set_blind，而自定义标记不进存档。
--    所以次数类惩罚借用原版会进存档的字段（hands_sub / discards_sub，见 blind.lua:774 Blind:save），
--    手牌上限则因为减少量写在存档的手牌上限里，需要在「当前盲注确实是本盲注」时无条件还原。
------------------------------------------------------------------
local function blind_ref()
    return G.GAME and G.GAME.blind
end

-- 出牌次数：与原版 The Needle 同款（hands_sub 会进存档）
local function hands_penalty(amount)
    return {
        set_blind = function(self)
            local b = blind_ref()
            if not b or b.hands_sub then return end
            -- 至少保留 1 次出牌：hands_left 归零会导致本盲注无法出牌（soft-lock）
            local left = (G.GAME.current_round and G.GAME.current_round.hands_left) or amount + 1
            b.hands_sub = math.min(amount, math.max(0, left - 1))
            ease_hands_played(-(b.hands_sub or 0))
        end,
        disable = function(self)
            local b = blind_ref()
            if not b or not b.hands_sub then return end
            ease_hands_played(b.hands_sub)
            b.hands_sub = nil
        end,
    }
end

-- 弃牌次数：与原版 The Water 同款（discards_sub 会进存档）
local function discards_penalty()
    return {
        set_blind = function(self)
            local b = blind_ref()
            if not b or b.discards_sub then return end
            b.discards_sub = G.GAME.current_round.discards_left
            ease_discard(-b.discards_sub)
        end,
        disable = function(self)
            local b = blind_ref()
            if not b or not b.discards_sub then return end
            ease_discard(b.discards_sub)
            b.discards_sub = nil
        end,
    }
end

-- 手牌上限：与原版 The Manacle 同款（change_size 会写进存档的 card_limits）
local function hand_size_penalty(amount)
    local flag = 'blh_hsize'
    local function restore(self)
        local b = blind_ref()
        if not b then return end
        if b[flag] == false then return end                          -- 本次会话已还原过
        local mine = b.config and b.config.blind == self
        if b[flag] == nil and not mine then return end               -- 读档后标记会丢：确认是自己的盲注才还原
        local cut = b[flag .. '_amount'] or amount
        b[flag] = false
        b[flag .. '_amount'] = nil
        G.hand:change_size(cut)
    end
    return {
        set_blind = function(self)
            local b = blind_ref()
            if not b or b[flag] then return end
            -- 至少保留 1 张手牌上限：归零后无法抽牌/出牌（soft-lock）
            local limit = (G.hand and G.hand.config and G.hand.config.card_limit) or amount + 1
            local cut = math.min(amount, math.max(0, limit - 1))
            b[flag] = true
            b[flag .. '_amount'] = cut
            G.hand:change_size(-cut)
        end,
        disable = restore,
        -- 与原版 The Manacle 一致：被 disable 过的盲注不再在 defeat 时二次还原，
        -- 否则手牌上限会被还原两次（net +amount）
        defeat = function(self)
            local b = blind_ref()
            if b and b.disabled then
                b[flag] = false
                return
            end
            restore(self)
        end,
    }
end

-- 只在盲注本次登场生效一次的效果（天猪 / 天龙的筹码缩放）。
-- 缩放结果随 G.GAME.blind.chips 进存档，读档不会重算；标记只防同一次登场被重复调用。
local function once_effect(key, apply)
    local flag = 'blh_once_' .. key
    return {
        set_blind = function(self)
            if self[flag] then return end
            self[flag] = true
            apply(self)
        end,
        disable = function(self) self[flag] = nil end,
        defeat = function(self) self[flag] = nil end,
    }
end

-- 天猪：需求分数随机 ×0.8~×1.4
local pig_scale = once_effect('pig', function(self)
    local b = blind_ref()
    if not b or not b.chips then return end
    local mult = 0.8 + pseudorandom('blh_pig_blind' .. tostring(G.GAME.round_resets.ante)) * 0.6
    b.chips = b.chips * mult
    b.chip_text = number_format(b.chips)
end)

-- 天龙：每 500 道，强度 +10%
local dragon_scale = once_effect('dragon', function(self)
    local b = blind_ref()
    if not b or not b.chips then return end
    b.chips = b.chips * BLH.dragon_mult()
    b.chip_text = number_format(b.chips)
end)

-- 人牛：出牌次数 -1
local ox_hands = hands_penalty(1)
-- 人兔：弃牌次数清零
local rabbit_discards = discards_penalty()
-- 地猴 / 天狗：手牌上限 -1 / -2
local monkey_hsize = hand_size_penalty(1)
local dog_hsize = hand_size_penalty(2)

--==============================================================
-- 人级（天 1–3）
--==============================================================

SMODS.Blind {
    key = 'rat', atlas = 'blh_blind', pos = { x = 0, y = 0 }, boss = { min = 1, max = 3 },
    boss_colour = HEX('56789A'),
    mult = 2, dollars = 3,
    loc_txt = loc('人鼠·仓库寻道', 'Rat: Warehouse Search',
        { '{C:attention}方片{}被藏了起来', '（此花色不计分）' },
        { '{C:attention}Diamonds{} are hidden away', '(this suit scores nothing)' }),
    debuff = { suit = 'Diamonds' },
}

SMODS.Blind {
    key = 'ox', atlas = 'blh_blind', pos = { x = 0, y = 1 }, boss = { min = 1, max = 3 },
    boss_colour = HEX('8C6A3F'),
    mult = 1, dollars = 4,
    loc_txt = loc('人牛·障碍赛跑', 'Ox: Obstacle Race',
        { '出牌次数 {C:red}-1{}', '（体能被消耗）' },
        { 'Hands {C:red}-1{}', '(your stamina is drained)' }),
    -- 只减 1 次（先前误用了「The Needle 式只留 1 次」，与描述不符）
    set_blind = ox_hands.set_blind,
    disable = ox_hands.disable,
}

SMODS.Blind {
    key = 'tiger', atlas = 'blh_blind', pos = { x = 0, y = 2 }, boss = { min = 1, max = 3 },
    boss_colour = HEX('A8402F'),
    mult = 1.5, dollars = 4,
    loc_txt = loc('人虎·狭路相逢', 'Tiger: Narrow Path',
        { '{C:attention}人头牌{}全部失效', '（正面对抗）' },
        { '{C:attention}Face cards{} are debuffed', '(a head-on clash)' }),
    debuff = { is_face = 'face' },
}

SMODS.Blind {
    key = 'rabbit', atlas = 'blh_blind', pos = { x = 0, y = 3 }, boss = { min = 1, max = 3 },
    boss_colour = HEX('7A5C93'),
    mult = 1.5, dollars = 5,
    loc_txt = loc('人兔·蓬莱', 'Rabbit: Penglai',
        { '没有{C:red}弃牌次数{}', '（无处可逃，只能向前）' },
        { 'No {C:red}Discards{}', '(nowhere left to run)' }),
    set_blind = rabbit_discards.set_blind,
    disable = rabbit_discards.disable,
}

--==============================================================
-- 地级（天 4–7）
--==============================================================

SMODS.Blind {
    key = 'snake', atlas = 'blh_blind', pos = { x = 0, y = 4 }, boss = { min = 4, max = 7 },
    boss_colour = HEX('3F7F6A'),
    mult = 2, dollars = 5,
    loc_txt = loc('地蛇·少数与多数', 'Snake: Minority Rule',
        { '{C:attention}梅花{}被投票排除', '（少数服从多数）' },
        { '{C:attention}Clubs{} are voted out', '(the minority obeys)' }),
    debuff = { suit = 'Clubs' },
}

SMODS.Blind {
    key = 'horse', atlas = 'blh_blind', pos = { x = 0, y = 5 }, boss = { min = 4, max = 7 },
    boss_colour = HEX('B08A3C'),
    mult = 2.2, dollars = 5,
    loc_txt = loc('地马·木牛流马', 'Horse: Wooden Ox',
        { '盲注需求分数 {C:red}大幅提升{}', '（一场长途竞速）' },
        { 'This Blind demands {C:red}far more score{}', '(a long race)' }),
}

SMODS.Blind {
    key = 'goat', atlas = 'blh_blind', pos = { x = 0, y = 6 }, boss = { min = 4, max = 7 },
    boss_colour = HEX('9C5B7A'),
    mult = 1.5, dollars = 6,
    loc_txt = loc('地羊·四情扇', 'Goat: Four Fans',
        { '{C:attention}红桃{}被欺骗藏起', '（喜/怒/哀/乐 只余三情）' },
        { '{C:attention}Hearts{} are hidden by deceit', '(three moods remain)' }),
    debuff = { suit = 'Hearts' },
}

SMODS.Blind {
    key = 'monkey', atlas = 'blh_blind', pos = { x = 0, y = 7 }, boss = { min = 4, max = 7 },
    boss_colour = HEX('4A6FA5'),
    mult = 2, dollars = 6,
    loc_txt = loc('地猴·箱中道', 'Monkey: Box of Dao',
        { '手牌上限 {C:red}-1{}', '每次出牌时随机弃掉 1 张手牌' },
        { 'Hand size {C:red}-1{}', 'Randomly discards a card each time you play' }),
    set_blind = monkey_hsize.set_blind,
    disable = monkey_hsize.disable,
    defeat = monkey_hsize.defeat,
    -- 出牌时机用 press_play（blind.lua:507 明确分派），与原版 The Hook 同款：
    -- 此时打出的牌已移入 G.play，随机挑一张手牌弃掉，hook = true 表示不消耗弃牌次数
    press_play = function(self)
        local b = blind_ref()
        if not b or b.disabled then return end
        G.E_MANAGER:add_event(Event({ func = function()
            if G.hand and #G.hand.cards > 0 then
                local target = pseudorandom_element(G.hand.cards, pseudoseed('blh_monkey_blind' .. tostring(G.GAME.round or 0)))
                if target then
                    G.hand:add_to_highlighted(target, true)
                    G.FUNCS.discard_cards_from_highlighted(nil, true)
                end
            end
            return true
        end }))
        return true
    end,
}

--==============================================================
-- 天级（天 8–9）
--==============================================================

SMODS.Blind {
    key = 'rooster', atlas = 'blh_blind', pos = { x = 0, y = 8 }, boss = { min = 8, max = 9 },
    boss_colour = HEX('A05C4A'),
    mult = 2.5, dollars = 7,
    loc_txt = loc('天鸡·兵器牌', 'Rooster: Weapon Cards',
        { '{C:attention}人头牌{}全部失效', '（兵器相争，刀刀见血）' },
        { '{C:attention}Face cards{} are debuffed', '(a clash of weapons)' }),
    debuff = { is_face = 'face' },
}

SMODS.Blind {
    key = 'dog', atlas = 'blh_blind', pos = { x = 0, y = 9 }, boss = { min = 8, max = 9 },
    boss_colour = HEX('6B8E4E'),
    mult = 2.5, dollars = 7,
    loc_txt = loc('天狗·送信人', 'Dog: Messenger',
        { '手牌上限 {C:red}-2{}', '（信必须送到，代价自负）' },
        { 'Hand size {C:red}-2{}', '(the message must be delivered)' }),
    set_blind = dog_hsize.set_blind,
    disable = dog_hsize.disable,
    defeat = dog_hsize.defeat,
}

SMODS.Blind {
    key = 'pig', atlas = 'blh_blind', pos = { x = 0, y = 10 }, boss = { min = 8, max = 9 },
    boss_colour = HEX('8A6BA8'),
    mult = 2, dollars = 8,
    loc_txt = loc('天猪·黑白棋子', 'Pig: Black and White',
        { '盲注需求分数随机浮动 {C:attention}×0.8 ~ ×1.4{}', '（概率博弈）' },
        { 'This Blind demands a random {C:attention}×0.8 to ×1.4{} score', '(a gamble on probability)' }),
    -- chips 在 Blind:set_blind 里先于 obj:set_blind() 算好（blind.lua:135 → 191），可直接改
    set_blind = pig_scale.set_blind,
    disable = pig_scale.disable,
    defeat = pig_scale.defeat,
}

--==============================================================
-- 天龙（第 10 天 / 提前降临）
--==============================================================

SMODS.Blind {
    key = 'dragon', atlas = 'blh_blind', pos = { x = 0, y = 11 },
    boss = { min = 10, max = 10, showdown = true },
    boss_colour = HEX('B03A3A'),
    mult = 2.5, dollars = 12,
    loc_txt = loc('天龙·天秤游戏', 'Dragon: The Scale',
        { '天秤两端失衡时，你的计分 {C:red}×0.5{}', '你持有的{C:attention}道{}越多，天龙越强' },
        { 'When the scales tip, your scoring is {C:red}×0.5{}', 'The more {C:attention}Dao{} you hold, the stronger it gets' }),
    -- 反刷：每 500 道，天龙强度 +10%（dragon_scale）
    set_blind = dragon_scale.set_blind,
    disable = dragon_scale.disable,
    defeat = dragon_scale.defeat,
    -- 天秤：一手牌里黑桃/梅花占比极端（0 张或全部）视为失衡 → 计分 ×0.5。
    -- 用 modify_hand（blind.lua:553 明确分派，参数为 G.play.cards）而不是 calculate。
    modify_hand = function(self, cards, poker_hands, text, mult, hand_chips)
        local n, spade_club = 0, 0
        for _, c in ipairs(cards or {}) do
            n = n + 1
            if c:is_suit('Spades') or c:is_suit('Clubs') then spade_club = spade_club + 1 end
        end
        if n > 0 and (spade_club == 0 or spade_club == n) then
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.1, func = function()
                attention_text({
                    text = localize('blh_dragon_tip'), scale = 0.8, hold = 1,
                    backdrop_colour = G.C.RED, align = 'cm', silent = true,
                })
                return true
            end }))
            return math.max(math.floor(mult * 0.5 + 0.5), 1), hand_chips, true
        end
        return mult, hand_chips, false
    end,
}
