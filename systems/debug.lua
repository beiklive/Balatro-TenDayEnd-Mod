--- 终焉之地 · 调试工具
--- 一键临时解锁本模组全部内容
--- 入口：① 快捷键 Ctrl+U（需键盘）② 模组设置页的「解锁全部内容」按钮（移动端可用）
---
--- 注意：26.829.0 里并不存在 SMODS.Jokers / SMODS.Consumables 等汇总表，
--- 因此这里改为遍历真正承载数据的运行时表：G.P_CENTERS / G.P_TAGS / G.P_BLINDS /
--- G.P_SEALS / G.P_CENTER_POOLS，并以 key 前缀 blh_ 判归属（对任何版本都有效）。

local mod = SMODS.current_mod
local BLH = mod.blh

local STICKER_FLAGS = {
    'enable_blh_memory', 'enable_blh_deep_echo', 'enable_blh_native',
    'enable_blh_ant', 'enable_blh_mask',
}

-- 深度遍历任意嵌套表，取出所有带 key 的对象（去重、限深）
local function each_object(fn)
    local seen_obj, seen_tbl = {}, {}
    local function scan(t, depth)
        if type(t) ~= 'table' or depth > 4 or seen_tbl[t] then return end
        seen_tbl[t] = true
        for _, v in pairs(t) do
            if type(v) == 'table' then
                if v.key then
                    if not seen_obj[v] then
                        seen_obj[v] = true
                        fn(v)
                    end
                else
                    scan(v, depth + 1)
                end
            end
        end
    end

    scan(G.P_CENTERS, 0)
    scan(G.P_TAGS, 0)
    scan(G.P_BLINDS, 0)
    scan(G.P_SEALS, 0)
    scan(G.P_CENTER_POOLS, 0)
    -- 某些版本的 SMODS 汇总表（存在才扫，不存在跳过）
    scan(SMODS.Jokers, 0)
    scan(SMODS.Consumables, 0)
    scan(SMODS.Vouchers, 0)
    scan(SMODS.Tags, 0)
    scan(SMODS.Blinds, 0)
    scan(SMODS.Editions, 0)
    scan(SMODS.Seals, 0)
    scan(SMODS.Stickers, 0)
end

function BLH.unlock_all()
    local count = 0
    each_object(function(obj)
        -- 双判据：对象记录的本模组引用，或 key 带模组前缀（后者对任何版本都成立）
        local mine = (obj.mod == mod) or (obj.key and string.find(obj.key, 'blh_', 1, true))
        if mine then
            obj.discovered = true
            obj.unlocked = true
            obj.disabled = false
            count = count + 1
        end
    end)

    -- 贴纸需要 enable_* 标记才能被附加
    if G.GAME then
        G.GAME.modifiers = G.GAME.modifiers or {}
        for _, k in ipairs(STICKER_FLAGS) do G.GAME.modifiers[k] = true end
    end
    -- 图鉴计数缓存（原版函数，存在才刷新）
    if type(set_discover_tallies) == 'function' then pcall(set_discover_tallies) end
    if G.GAME and G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind then
        G.GAME.blind.config.blind.discovered = true
    end

    return count
end

function BLH.announce_unlock(count)
    local text = localize('blh_unlock_done') .. ' (' .. tostring(count) .. ')'
    if type(sendInfoMessage) == 'function' then
        pcall(sendInfoMessage, text, mod.name)
    end
    if type(attention_text) == 'function' then
        attention_text({
            text = text,
            scale = 1.2,
            hold = 1.8,
            backdrop_colour = G.C.GOLD,
            align = 'cm',
            silent = true,
        })
    end
end

function G.FUNCS.blh_unlock_all(e)
    local count = BLH.unlock_all()
    BLH.announce_unlock(count)
    if e and e.config then e.config.button = 'blh_unlock_all' end
end

-- 快捷键：Ctrl + U
SMODS.Keybind {
    key = 'blh_unlock_all',
    key_pressed = 'u',
    held_keys = { 'lctrl' },
    action = function(self)
        G.FUNCS.blh_unlock_all()
    end,
}
