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

-- set_blind 施加、disable/defeat 各自幂等还原（文档：disable = 被禁用时还原，defeat = 被击败时还原）
local function penalty(apply, revert)
    local p = {
        _applied = false,
        set_blind = function(self)
            if self._applied then return end
            self._applied = true
            apply(self)
        end,
        revert = function(self)
            if not self._applied then return end
            self._applied = false
            revert(self)
        end,
    }
    p.disable = p.revert
    p.defeat = p.revert
    return p
end

local function hand_size_penalty(amount)
    return penalty(
        function(self) G.hand:change_size(-amount) end,
        function(self) G.hand:change_size(amount) end
    )
end

local function discard_penalty()
    return penalty(
        function(self)
            self.discards_sub = G.GAME.current_round.discards_left
            ease_discard(-self.discards_sub)
        end,
        function(self)
            if self.discards_sub then
                ease_discard(self.discards_sub)
                self.discards_sub = nil
            end
        end
    )
end

local function hand_penalty()
    return penalty(
        function(self)
            self.hands_sub = G.GAME.round_resets.hands - 1
            ease_hands_played(-self.hands_sub)
        end,
        function(self)
            if self.hands_sub then
                ease_hands_played(self.hands_sub)
                self.hands_sub = nil
            end
        end
    )
end

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
    set_blind = hand_penalty().set_blind,
    disable = hand_penalty().disable,
    defeat = hand_penalty().defeat,
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
    set_blind = discard_penalty().set_blind,
    disable = discard_penalty().disable,
    defeat = discard_penalty().defeat,
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
        { '手牌上限 {C:red}-1{}', '每次出牌后随机弃掉 1 张手牌' },
        { 'Hand size {C:red}-1{}', 'Randomly discards a card after each hand' }),
    set_blind = hand_size_penalty(1).set_blind,
    disable = hand_size_penalty(1).disable,
    defeat = hand_size_penalty(1).defeat,
    calculate = function(self, blind, context)
        if context.after and context.cardarea == G.play and G.hand and #G.hand.cards > 0 then
            local target = pseudorandom_element(G.hand.cards, pseudoseed('blh_monkey_blind' .. tostring(G.GAME.round or 0)))
            if target then SMODS.destroy_cards(target) end
        end
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
    set_blind = hand_size_penalty(2).set_blind,
    disable = hand_size_penalty(2).disable,
    defeat = hand_size_penalty(2).defeat,
}

SMODS.Blind {
    key = 'pig', atlas = 'blh_blind', pos = { x = 0, y = 10 }, boss = { min = 8, max = 9 },
    boss_colour = HEX('8A6BA8'),
    mult = 2, dollars = 8,
    loc_txt = loc('天猪·黑白棋子', 'Pig: Black and White',
        { '盲注需求分数随机浮动 {C:attention}×0.8 ~ ×1.4{}', '（概率博弈）' },
        { 'This Blind demands a random {C:attention}×0.8 to ×1.4{} score', '(a gamble on probability)' }),
    set_blind = function(self)
        G.E_MANAGER:add_event(Event({ func = function()
            -- 一次性：set_blind 可能因读档/重进被再次调用，不能重复乘算
            if G.GAME.blind and G.GAME.blind.chips and not G.GAME.blind.blh_scaled then
                G.GAME.blind.blh_scaled = true
                local mult = 0.8 + pseudorandom('blh_pig_blind' .. tostring(G.GAME.round_resets.ante)) * 0.6
                G.GAME.blind.chips = G.GAME.blind.chips * mult
                G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
            end
            return true
        end }))
    end,
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
    set_blind = function(self)
        -- 反刷：每 500 道，天龙强度 +10%
        G.E_MANAGER:add_event(Event({ func = function()
            -- 一次性：防止 set_blind 重入导致天龙强度被反复乘算
            if G.GAME.blind and G.GAME.blind.chips and not G.GAME.blind.blh_scaled then
                G.GAME.blind.blh_scaled = true
                G.GAME.blind.chips = G.GAME.blind.chips * BLH.dragon_mult()
                G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
            end
            return true
        end }))
    end,
    calculate = function(self, blind, context)
        if context.cardarea == G.play and context.main_scoring then
            -- 天秤：一手牌里黑桃/梅花占比极端（0 或全）视为失衡
            local balance = 0
            for _, c in ipairs(G.play.cards) do
                if c:is_suit('Spades') or c:is_suit('Clubs') then balance = balance + 1 end
            end
            if balance == 0 or balance == #G.play.cards then
                return { x_mult = 0.5, message = localize('blh_dragon_tip'), colour = G.C.RED }
            end
        end
    end,
}
