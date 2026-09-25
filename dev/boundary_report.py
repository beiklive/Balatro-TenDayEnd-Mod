import os as _os
# -*- coding: utf-8 -*-
"""beiklive助手 卡片边界审计：加牌能力 × 触发阶段 × 容量/nil 保护。"""
import re, os, glob

ROOT = _os.path.normpath(_os.path.join(_os.path.dirname(_os.path.abspath(__file__)), '..'))
FILES = sorted(glob.glob(ROOT + '/content/*.lua')) + sorted(glob.glob(ROOT + '/systems/*.lua'))

def indent(s): return len(s) - len(s.lstrip(' \t'))

def objects(path):
    lines = open(path, encoding='utf-8').read().split('\n')
    out, i, pat = [], 0, re.compile(r'^(\s*)(SMODS\.(\w+))\s*\{')
    while i < len(lines):
        m = pat.match(lines[i])
        if not m: i += 1; continue
        base, kind = indent(m.group(1)), m.group(3)
        blk, j = [lines[i]], i + 1
        while j < len(lines):
            blk.append(lines[j])
            if indent(lines[j]) == base and lines[j].startswith(' ' * base + '}'): break
            j += 1
        out.append((kind, i + 1, blk)); i = j + 1
    return out

def scope_of(blk, n):
    """返回第 n 行所属的 context.X 触发器（按缩进包含关系，取最内层）"""
    best = None
    for k in range(n - 1, -1, -1):
        if 'context.' in blk[k] and not blk[k].lstrip().startswith('--'):
            if indent(blk[k]) < indent(blk[n]) or indent(blk[k]) == indent(blk[n]) and 'if ' in blk[k]:
                # 该行必须真的包含第 n 行
                base = indent(blk[k])
                for q in range(k + 1, len(blk)):
                    if blk[q].strip() and indent(blk[q]) <= base:
                        if q <= n: break
                        else: return re.findall(r'context\.(\w+)', blk[k])[0]
                    if q == n: return re.findall(r'context\.(\w+)', blk[k])[0]
    return best

ADDS = [
    (r"create_card\('(\w+)'", 'consumeable/joker 生成'),
    (r'create_playing_card', '手牌/牌堆生成'),
    (r'copy_card', '复制牌'),
    (r'SMODS\.add_card', '通用加牌'),
]
AREA = [(r'G\.consumeables', '消耗品区'), (r'G\.jokers', '小丑区'),
        (r'G\.hand', '手牌区'), (r'G\.deck', '牌堆'), (r'G\.discard', '弃牌堆')]

rows, warns = [], []
for f in FILES:
    rel = os.path.relpath(f, ROOT)
    for kind, l0, blk in objects(f):
        text = '\n'.join(blk)
        mk = re.search(r"key\s*=\s*'([^']+)'", text)
        key = mk.group(1) if mk else '?'
        for n, line in enumerate(blk):
            if line.lstrip().startswith('--'): continue
            for pat, what in ADDS:
                m = re.search(pat, line)
                if not m: continue
                sc = scope_of(blk, n) or '立即/其他'
                area = '?'
                for ap, an in AREA:
                    if re.search(ap, line): area = an; break
                if area == '?':
                    for ap, an in AREA:
                        if re.search(ap, text): area = an + '(近)'; break
                # 容量保护：本对象内是否有 card_limit 判断
                cap = 'card_limit' in text or 'card_limits' in text
                nilg = bool(re.search(r'if\s+\w+\s+then|#\w+\s*>\s*0|ipairs\(', text))
                rows.append((rel, l0 + n, key, what, sc, area, '有' if cap else '无', '有' if nilg else '无'))
                if sc == 'end_of_round' and area in ('手牌区', '牌堆', '弃牌堆'):
                    warns.append(('CRIT', rel, l0 + n, key, what, sc, area))
                if not cap and what != '复制牌' and sc != '立即/其他':
                    warns.append(('WARN', rel, l0 + n, key, what, sc, area + ' 无容量检查'))

print('| 文件:行 | 对象 | 加牌方式 | 触发阶段 | 目标区域 | 容量检查 | 空集保护 |')
print('|---|---|---|---|---|---|---|')
for r in rows:
    print('| %s:%d | %s | %s | %s | %s | %s | %s |' % r)

print('\n### end_of_round 分支清单')
for f in FILES:
    rel = os.path.relpath(f, ROOT)
    for kind, l0, blk in objects(f):
        for n, line in enumerate(blk):
            if 'context.end_of_round' in line and not line.lstrip().startswith('--'):
                txt = line.strip()
                guard = []
                if 'main_eval' in txt or 'main_eval' in blk[n+1]: guard.append('main_eval')
                if 'not context.game_over' in txt: guard.append('not game_over')
                if 'context.game_over' in txt and 'not context.game_over' not in txt: guard.append('仅失败')
                if 'blueprint' in txt: guard.append('非blueprint')
                print('- %s:%-4d %-28s %s' % (rel, l0 + n, txt[:58], '+'.join(guard) or '⚠ 无守卫'))

print('\n### 概率事件 seed 唯一性')
seeds = {}
for f in FILES:
    for m in re.finditer(r"pseudorandom_probability\(\s*card\s*,\s*'([^']+)'", open(f, encoding='utf-8').read()):
        seeds.setdefault(m.group(1), []).append(os.path.relpath(f, ROOT))
for s, fs in sorted(seeds.items()):
    flag = ' ⚠ 重名' if len(set(fs)) > 1 or len(fs) > 1 else ''
    print('- %-22s %s%s' % (s, ','.join(sorted(set(fs))), flag))

print('\n### 结论')
print('虚拟告警 %d 项（CRIT/人工复核）' % len(warns))
for w in warns:
    print('  [%s] %s:%d 对象=%s %s 阶段=%s 区域=%s' % w)
