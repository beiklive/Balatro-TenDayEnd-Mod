import os as _os
# -*- coding: utf-8 -*-
import re, os, glob
ROOT = _os.path.normpath(_os.path.join(_os.path.dirname(_os.path.abspath(__file__)), '..'))
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

def extract_fn(blk, name):
    for n, line in enumerate(blk):
        if re.match(r'\s*' + name + r'\s*=', line):
            base = indent(line)
            body = [line]
            for k in range(n + 1, len(blk)):
                body.append(blk[k])
                if re.match(r'\s*end\s*,?\s*$', blk[k]) and indent(blk[k]) == base:
                    break
            return '\n'.join(body)
    return None

NEEDS = [('hand', r'highlighted\(\)|G\.hand', r'highlighted\(\)|G\.hand', '手牌/选牌'),
         ('jokers', r'G\.jokers', r'G\.jokers', '小丑'),
         ('deck', r'G\.deck', r'G\.deck', '牌堆'),
         ('consw', r'G\.consumeables', r'G\.consumeables', '消耗品区')]

rows, issues = [], 0
for f in sorted(glob.glob(ROOT + '/content/*.lua')):
    for kind, l0, blk in objects(f):
        if kind != 'Consumable': continue
        text = '\n'.join(blk)
        key = (re.search(r"key\s*=\s*'([^']+)'", text) or [None, '?'])[1]
        setn = (re.search(r"set\s*=\s*'([^']+)'", text) or [None, '?'])[1]
        cu = extract_fn(blk, 'can_use')
        use = extract_fn(blk, 'use') or ''
        deps, checked, missing = [], [], []
        for name, dpat, cpat, label in NEEDS:
            if re.search(dpat, use):
                deps.append(label)
                (checked if (cu and re.search(cpat, cu)) else missing).append(label)
        if not cu:
            verdict = '⚠ 无 can_use'; issues += 1
        elif missing:
            verdict = '⚠ 缺检查: ' + ','.join(missing); issues += 1
        else:
            verdict = 'OK'
        rows.append((key, setn, '有' if cu else '无', ','.join(deps) or '-', ','.join(checked) or '-', verdict))

print('| 对象 | 类型 | can_use | use 依赖资源 | can_use 内已检查 | 判定 |')
print('|---|---|---|---|---|---|')
for r in rows: print('| %s | %s | %s | %s | %s | %s |' % r)
print('\n对象总数 %d，需人工确认 %d 项' % (len(rows), issues))
for r in rows:
    if r[5] != 'OK': print('  ⚠ %s (%s): %s' % (r[0], r[1], r[5]))
