#!/usr/bin/env python3
"""beiklive助手 v3 · 按游戏原始素材形制重绘全部图集
参考 game_original_files/resources/textures/1x 的尺寸与形状：
  Jokers 71x95 整卡(圆角+描边+内框+满幅插画+左侧竖排 JOKER)
  Tarots 71x95 羊皮纸+双线花框+底名牌；Spectral 深蓝+双线框+底名牌
  Vouchers 71x95 高饱和底+白内描边+顶部 VOUCHER 牌+中央图标
  BlindChips 34x34 圆形筹码(外环+内盘+符号+顶部小字)，角透明，21 帧沿 x
  tags 34x34 圆角小牌(浅框+倒角)，角透明
  stickers/Enhancers 里的封印：71x95 左上角小徽章，其余透明
"""
import math
import os
import struct
import zlib

import os as _os
ROOT = _os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "..", "assets")
SS = 6
CW, CH = 71, 95

# ------------------------------------------------------------------ 画布
class Canvas:
    """绘制用 1x 坐标，内部按 k 倍超采样写入"""
    def __init__(self, w, h, k=1):
        self.w, self.h, self.k = w, h, k
        self.buf = bytearray(w * h * 4)

    def sx(self, v):
        return v * self.k

    def sbox(self, v0, v1):
        return self.sx(v0), self.sx(v1 + 1) - 1

    def put(self, x, y, c):
        assert len(c) == 4, c
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            i = (y * self.w + x) * 4
            self.buf[i:i + 4] = bytes(c)   # alpha=0 也写入 => 可擦除（rrect_outline 需要）

    def blend(self, x, y, c):
        x, y = int(self.sx(x)), int(self.sx(y))
        if not (0 <= x < self.w and 0 <= y < self.h):
            return
        i = (y * self.w + x) * 4
        a = c[3] / 255.0
        self.buf[i] = int(self.buf[i] * (1 - a) + c[0] * a)
        self.buf[i + 1] = int(self.buf[i + 1] * (1 - a) + c[1] * a)
        self.buf[i + 2] = int(self.buf[i + 2] * (1 - a) + c[2] * a)
        self.buf[i + 3] = min(255, int(self.buf[i + 3] * (1 - a) + 255 * a))

    def rrect(self, x0, y0, x1, y1, r, c):
        x0, x1 = self.sbox(x0, x1)
        y0, y1 = self.sbox(y0, y1)
        r = self.sx(r)
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                cx = min(max(x, x0 + r), x1 - r)
                cy = min(max(y, y0 + r), y1 - r)
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.put(x, y, c)

    def rrect_outline(self, x0, y0, x1, y1, r, t, c):
        self.rrect(x0, y0, x1, y1, r, c)
        self.rrect(x0 + t, y0 + t, x1 - t, y1 - t, max(0, r - t), (0, 0, 0, 0))

    def disc(self, cx, cy, r, c):
        cx, cy, r = self.sx(cx), self.sx(cy), self.sx(r)
        for y in range(int(cy - r), int(cy + r) + 1):
            for x in range(int(cx - r), int(cx + r) + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.put(x, y, c)

    def ring(self, cx, cy, r, t, c, a0=None, a1=None):
        cx, cy, r, t = self.sx(cx), self.sx(cy), self.sx(r), self.sx(t)
        lo, hi = max(0, r - t / 2.0) ** 2, (r + t / 2.0) ** 2
        for y in range(int(cy - r - t), int(cy + r + t) + 1):
            for x in range(int(cx - r - t), int(cx + r + t) + 1):
                d = (x - cx) ** 2 + (y - cy) ** 2
                if lo <= d <= hi * 1.02:
                    if a0 is not None:
                        ang = math.degrees(math.atan2(y - cy, x - cx))
                        if not (a0 <= ang <= a1):
                            continue
                    self.put(x, y, c)

    def bar(self, cx, cy, hw, hh, c):
        self.rrect(cx - hw, cy - hh, cx + hw, cy + hh, min(hw, hh) * 0.5, c)


    def poly(self, pts, c):
        pts = [(self.sx(p[0]), self.sx(p[1])) for p in pts]
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            for x in range(int(min(xs)), int(max(xs)) + 1):
                inside = False
                n = len(pts)
                for i in range(n):
                    x1, y1 = pts[i]
                    x2, y2 = pts[(i + 1) % n]
                    if (y1 > y) != (y2 > y):
                        xin = x1 + (y - y1) * (x2 - x1) / (y2 - y1)
                        if x < xin:
                            inside = not inside
                if inside:
                    self.put(x, y, c)

    def line(self, p1, p2, t, c):
        # 用 1x 坐标构造四边形，交给 poly 统一缩放（不能在这里再 sx 一次）
        dx, dy = p2[0] - p1[0], p2[1] - p1[1]
        L = math.hypot(dx, dy) or 1
        nx, ny = -dy / L * t / 2, dx / L * t / 2
        self.poly([(p1[0] + nx, p1[1] + ny), (p2[0] + nx, p2[1] + ny),
                   (p2[0] - nx, p2[1] - ny), (p1[0] - nx, p1[1] - ny)], c)

    def vgrad(self, x0, y0, x1, y1, c0, c1):
        x0, x1 = self.sbox(x0, x1)
        y0, y1 = self.sbox(y0, y1)
        h = max(1, y1 - y0)
        for y in range(int(y0), int(y1) + 1):
            t = (y - y0) / h
            c = (int(c0[0] + (c1[0] - c0[0]) * t), int(c0[1] + (c1[1] - c0[1]) * t),
                 int(c0[2] + (c1[2] - c0[2]) * t), 255)
            for x in range(int(x0), int(x1) + 1):
                self.put(x, y, c)


def hsv(h, s, v, a=255):
    h = h % 360
    c = v * s
    x = c * (1 - abs((h / 60) % 2 - 1))
    m = v - c
    r, g, b = [(c, x, 0), (x, c, 0), (0, c, x), (0, x, c), (x, 0, c), (c, 0, x)][int(h // 60) % 6]
    return (int((r + m) * 255), int((g + m) * 255), int((b + m) * 255), a)


def shade(c, f):
    return (max(0, min(255, int(c[0] * f))), max(0, min(255, int(c[1] * f))),
            max(0, min(255, int(c[2] * f))), c[3])


# ------------------------------------------------------------------ 3x5 位图字体
FONT = {
 'A': '.#./#.#/###/#.#/#.#', 'B': '##./#.#/##./#.#/##.', 'C': '.##/#../#../#../.##',
 'D': '##./#.#/#.#/#.#/##.', 'E': '###/#../##./#../###', 'F': '###/#../##./#../#..',
 'G': '.##/#../#.#/#.#/.##', 'H': '#.#/#.#/###/#.#/#.#', 'I': '###/.#./.#./.#./###',
 'J': '..#/..#/..#/#.#/.#.', 'K': '#.#/#.#/##./#.#/#.#', 'L': '#../#../#../#../###',
 'M': '#.#/###/###/#.#/#.#', 'N': '#.#/###/###/###/#.#', 'O': '.#./#.#/#.#/#.#/.#.',
 'P': '##./#.#/##./#../#..', 'Q': '.#./#.#/#.#/##./.##', 'R': '##./#.#/##./#.#/#.#',
 'S': '.##/#../.#./..#/##.', 'T': '###/.#./.#./.#./.#.', 'U': '#.#/#.#/#.#/#.#/###',
 'V': '#.#/#.#/#.#/#.#/.#.', 'W': '#.#/#.#/###/###/#.#', 'X': '#.#/#.#/.#./#.#/#.#',
 'Y': '#.#/#.#/.#./.#./.#.', 'Z': '###/..#/.#./#../###', '0': '###/#.#/#.#/#.#/###',
 '1': '.#./##./.#./.#./###', '2': '##./..#/.#./#../###', '3': '##./..#/.##/..#/##.',
 '4': '#.#/#.#/###/..#/..#', '5': '###/#../##./..#/##.', '6': '.##/#../###/#.#/###',
 '7': '###/..#/.#./.#./.#.', '8': '###/#.#/###/#.#/###', '9': '###/#.#/###/..#/##.',
 ' ': '.../.../.../.../...', '-': '.../.../###/.../...', '.': '.../.../.../.../.#.',
 '?': '##./..#/.#./.../.#.', '!': '.#./.#./.#./.../.#.', "'": '.#./.#./.../.../...',
}


def text(cv, s, x, y, scale, colour, spacing=1):
    k = cv.k
    scale = scale * k
    x, y = cv.sx(x), cv.sx(y)
    cx = x
    for ch in s.upper():
        glyph = FONT.get(ch, FONT[' '])
        for gy in range(5):
            for gx in range(3):
                if glyph[gy * 4 + gx] == '#':
                    for sy in range(scale):
                        for sx in range(scale):
                            cv.put(cx + gx * scale + sx, y + gy * scale + sy, colour)
        cx += (3 + spacing) * scale
    return cx


def text_v(cv, s, x, y, scale, colour, spacing=1):
    """竖排标签：整段文字渲染后旋转 90°（自下而上阅读，与原版一致）"""
    w = text_w(s, scale, spacing)
    h = 5 * scale
    tmp = Canvas(w, h, 1)
    text(tmp, s, 0, 0, scale, colour, spacing)
    k = cv.k
    for ty in range(h):
        for tx in range(w):
            i = (ty * w + tx) * 4
            c = tuple(tmp.buf[i:i + 4])
            if c[3] > 8:
                # put() 写的是画布像素，需按超采样倍率铺成 k×k 方块
                dx, dy = (x + ty) * k, (y + (w - 1 - tx)) * k
                for oy in range(k):
                    for ox in range(k):
                        cv.put(dx + ox, dy + oy, c)


def text_w(s, scale=1, spacing=1):
    return len(s) * (3 + spacing) * scale


# ------------------------------------------------------------------ 通用装饰
def scatter(cv, box, n, colour, r=1, seed=1):
    x0, y0, x1, y1 = box
    st = seed * 2654435761 % 4294967296
    for _ in range(n):
        st = (1103515245 * st + 12345) % 2147483648
        x = x0 + (st % max(1, int(x1 - x0)))
        st = (1103515245 * st + 12345) % 2147483648
        y = y0 + (st % max(1, int(y1 - y0)))
        cv.disc(x, y, r, colour)


def rays(cv, cx, cy, r, n, colour, t=1.5, phase=0.0):
    for i in range(n):
        a = math.radians(phase + i * 360.0 / n)
        cv.line((cx + math.cos(a) * r * 0.28, cy + math.sin(a) * r * 0.28),
                (cx + math.cos(a) * r, cy + math.sin(a) * r), t, colour)


def star(cv, cx, cy, r, n, colour, rot=0.0):
    pts = []
    for i in range(n * 2):
        rr = r if i % 2 == 0 else r * 0.45
        a = math.radians(rot + i * 180.0 / n)
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    cv.poly(pts, colour)


def wave_rows(cv, x0, x1, y0, y1, colour, t=1.5, n=4, amp=3):
    for k in range(n):
        yy = y0 + (y1 - y0) * k / max(1, n - 1)
        pts = [(x, yy + math.sin(x / 4.0 + k) * amp) for x in range(int(x0), int(x1) + 1)]
        for i in range(len(pts) - 1):
            cv.line(pts[i], pts[i + 1], t, colour)


# ------------------------------------------------------------------ 背景纹理（8 种，避免"纯色底"雷同）
def bg_rays(cv, box, bg, acc):
    x0, y0, x1, y1 = box
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    rays(cv, cx, cy, max(x1 - x0, y1 - y0) * 0.62, 16, shade(bg, 1.22), 2.4, 11)


def bg_arcs(cv, box, bg, acc):
    x0, y0, x1, y1 = box
    cx, cy = (x0 + x1) / 2, y1
    for i in range(5):
        cv.ring(cx, cy, (i + 1) * (x1 - x0) * 0.13, 2.0, shade(bg, 1.18 + 0.06 * i), 180, 360)


def bg_split(cv, box, bg, acc):
    x0, y0, x1, y1 = box
    cv.poly([(x0, y1), (x1, y0), (x1, y1)], shade(bg, 1.28))
    cv.line((x0, y1), (x1, y0), 2.0, shade(acc, 0.9))


def bg_stripes(cv, box, bg, acc):
    x0, y0, x1, y1 = box
    for y in range(int(y0), int(y1) + 1, 7):
        cv.bar((x0 + x1) / 2, y, (x1 - x0) / 2, 1.6, shade(bg, 1.22))


def bg_dots(cv, box, bg, acc):
    scatter(cv, box, 42, shade(bg, 1.3), 1.4, seed=int(box[0]) + 3)


def bg_grid(cv, box, bg, acc):
    x0, y0, x1, y1 = box
    for x in range(int(x0), int(x1) + 1, 9):
        cv.bar(x, (y0 + y1) / 2, 0.8, (y1 - y0) / 2, shade(bg, 1.2))
    for y in range(int(y0), int(y1) + 1, 9):
        cv.bar((x0 + x1) / 2, y, (x1 - x0) / 2, 0.8, shade(bg, 1.2))


def bg_vignette(cv, box, bg, acc):
    x0, y0, x1, y1 = box
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    for i in range(7):
        r = max(x1 - x0, y1 - y0) * (0.72 - i * 0.09)
        cv.ring(cx, cy, r, 3.0, shade(bg, 1.10 + 0.05 * i))


def bg_chevron(cv, box, bg, acc):
    x0, y0, x1, y1 = box
    for k in range(5):
        yy = y0 + k * (y1 - y0) / 5.0
        cv.poly([(x0, yy), (x0 + (x1 - x0) * 0.5, yy + 7), (x1, yy), (x1, yy + 2.2),
                 (x0 + (x1 - x0) * 0.5, yy + 9.2), (x0, yy + 2.2)], shade(bg, 1.22))


BACKGROUNDS = [bg_rays, bg_arcs, bg_split, bg_stripes, bg_dots, bg_grid, bg_vignette, bg_chevron]


# ------------------------------------------------------------------ 构图模板（6 种，改变主体位置与数量）
def tpl_center(cv, box, motif, ink, acc, bg):
    x0, y0, x1, y1 = box
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    motif(cv, cx, cy, (x1 - x0) * 0.40, ink, acc, bg)


def tpl_horizon(cv, box, motif, ink, acc, bg):
    x0, y0, x1, y1 = box
    hy = y0 + (y1 - y0) * 0.68
    cv.bar((x0 + x1) / 2, hy, (x1 - x0) / 2, 1.6, shade(ink, 0.8))
    motif(cv, (x0 + x1) / 2, hy - (y1 - y0) * 0.30, (x1 - x0) * 0.34, ink, acc, bg)


def tpl_corner(cv, box, motif, ink, acc, bg):
    x0, y0, x1, y1 = box
    motif(cv, x1 - (x1 - x0) * 0.34, y0 + (y1 - y0) * 0.36, (x1 - x0) * 0.34, ink, acc, bg)
    cv.ring(x0 + (x1 - x0) * 0.28, y1 - (y1 - y0) * 0.24, (x1 - x0) * 0.20, 2.0, shade(acc, 0.95))


def tpl_duo(cv, box, motif, ink, acc, bg):
    x0, y0, x1, y1 = box
    r = (x1 - x0) * 0.24
    motif(cv, x0 + (x1 - x0) * 0.34, y0 + (y1 - y0) * 0.46, r * 1.25, ink, acc, bg)
    motif(cv, x0 + (x1 - x0) * 0.72, y0 + (y1 - y0) * 0.62, r * 0.95, shade(acc, 1.05), ink, bg)


def tpl_medallion(cv, box, motif, ink, acc, bg):
    x0, y0, x1, y1 = box
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    r = (x1 - x0) * 0.42
    cv.disc(cx, cy, r, shade(bg, 1.18))
    cv.ring(cx, cy, r, 2.2, acc)
    motif(cv, cx, cy, r * 0.66, ink, acc, shade(bg, 1.18))


def tpl_strip(cv, box, motif, ink, acc, bg):
    x0, y0, x1, y1 = box
    cv.rrect(x0, y0 + (y1 - y0) * 0.30, x1, y0 + (y1 - y0) * 0.70, 3, shade(bg, 1.25))
    motif(cv, (x0 + x1) / 2, (y0 + y1) / 2, (y1 - y0) * 0.20, ink, acc, shade(bg, 1.25))


TEMPLATES = [tpl_center, tpl_horizon, tpl_corner, tpl_duo, tpl_medallion, tpl_strip]


# ------------------------------------------------------------------ 粗符号（盲注/标签用，剪影清晰）
def sym_club(cv, cx, cy, r, ink, acc, bg):
    for a in (90, 210, 330):
        rad = math.radians(a)
        cv.disc(cx + math.cos(rad) * r * 0.42, cy + math.sin(rad) * r * 0.42, r * 0.42, ink)
    cv.bar(cx, cy + r * 0.62, r * 0.12, r * 0.42, ink)


def sym_heart(cv, cx, cy, r, ink, acc, bg):
    cv.disc(cx - r * 0.32, cy - r * 0.2, r * 0.4, ink)
    cv.disc(cx + r * 0.32, cy - r * 0.2, r * 0.4, ink)
    cv.poly([(cx - r * 0.68, cy - r * 0.08), (cx + r * 0.68, cy - r * 0.08), (cx, cy + r * 0.8)], ink)


def sym_spade(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx, cy - r * 0.85), (cx + r * 0.72, cy + r * 0.16), (cx - r * 0.72, cy + r * 0.16)], ink)
    cv.disc(cx - r * 0.3, cy + r * 0.1, r * 0.34, ink)
    cv.disc(cx + r * 0.3, cy + r * 0.1, r * 0.34, ink)
    cv.bar(cx, cy + r * 0.62, r * 0.11, r * 0.4, ink)


def sym_diamond(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx, cy - r * 0.9), (cx + r * 0.6, cy), (cx, cy + r * 0.9), (cx - r * 0.6, cy)], ink)
    cv.poly([(cx, cy - r * 0.4), (cx + r * 0.26, cy), (cx, cy + r * 0.4), (cx - r * 0.26, cy)], acc)


def sym_skull(cv, cx, cy, r, ink, acc, bg):
    cv.disc(cx, cy - r * 0.14, r * 0.72, ink)
    cv.rrect(cx - r * 0.42, cy + r * 0.3, cx + r * 0.42, cy + r * 0.8, r * 0.14, ink)
    for dx in (-0.28, 0.28):
        cv.disc(cx + dx * r, cy - r * 0.2, r * 0.19, bg)
    cv.bar(cx, cy + r * 0.3, r * 0.06, r * 0.14, bg)


def sym_eye(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx - r, cy), (cx, cy - r * 0.66), (cx + r, cy), (cx, cy + r * 0.66)], ink)
    cv.disc(cx, cy, r * 0.34, bg)
    cv.disc(cx, cy, r * 0.16, acc)


def sym_crescent(cv, cx, cy, r, ink, acc, bg):
    cv.disc(cx, cy, r * 0.85, ink)
    cv.disc(cx + r * 0.4, cy - r * 0.24, r * 0.72, bg)
    star(cv, cx + r * 0.6, cy + r * 0.55, r * 0.2, 4, acc)


def sym_star(cv, cx, cy, r, ink, acc, bg):
    star(cv, cx, cy, r * 0.95, 5, ink)
    cv.disc(cx, cy, r * 0.2, acc)


def sym_bolt(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx + r * 0.16, cy - r * 0.9), (cx - r * 0.6, cy + r * 0.16), (cx - r * 0.08, cy + r * 0.16),
             (cx - r * 0.34, cy + r * 0.9), (cx + r * 0.66, cy - r * 0.22), (cx + r * 0.08, cy - r * 0.22)], ink)


def sym_wave(cv, cx, cy, r, ink, acc, bg):
    for k in (-r * 0.4, 0, r * 0.4):
        pts = [(cx - r + i * r / 8.0, cy + k + math.sin(i * 0.8) * r * 0.22) for i in range(17)]
        for i in range(len(pts) - 1):
            cv.line(pts[i], pts[i + 1], 2.6, ink)
    cv.disc(cx + r * 0.85, cy - r * 0.5, r * 0.16, acc)


def sym_arrow(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx, cy - r * 0.9), (cx + r * 0.66, cy - r * 0.05), (cx + r * 0.24, cy - r * 0.05),
             (cx + r * 0.24, cy + r * 0.9), (cx - r * 0.24, cy + r * 0.9), (cx - r * 0.24, cy - r * 0.05),
             (cx - r * 0.66, cy - r * 0.05)], ink)


def sym_mask(cv, cx, cy, r, ink, acc, bg):
    cv.rrect(cx - r * 0.85, cy - r * 0.6, cx + r * 0.85, cy + r * 0.6, r * 0.3, ink)
    cv.disc(cx - r * 0.34, cy - r * 0.06, r * 0.2, bg)
    cv.disc(cx + r * 0.34, cy - r * 0.06, r * 0.2, bg)
    cv.bar(cx, cy + r * 0.36, r * 0.3, r * 0.06, bg)


def sym_key(cv, cx, cy, r, ink, acc, bg):
    cv.ring(cx, cy - r * 0.42, r * 0.32, r * 0.16, ink)
    cv.bar(cx, cy + r * 0.22, r * 0.1, r * 0.6, ink)
    cv.bar(cx + r * 0.26, cy + r * 0.62, r * 0.22, r * 0.08, ink)
    cv.bar(cx + r * 0.26, cy + r * 0.36, r * 0.16, r * 0.07, ink)


def sym_coin(cv, cx, cy, r, ink, acc, bg):
    cv.disc(cx, cy, r * 0.8, ink)
    cv.ring(cx, cy, r * 0.52, 1.8, bg)
    cv.bar(cx, cy, r * 0.1, r * 0.42, bg)


def sym_spiral(cv, cx, cy, r, ink, acc, bg):
    pts = []
    for i in range(120):
        t = i / 119.0
        a = t * math.pi * 3.0
        rr = r * (0.1 + 0.85 * t)
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    for i in range(len(pts) - 1):
        cv.line(pts[i], pts[i + 1], 2.6, ink)


BOLD = [sym_club, sym_heart, sym_spade, sym_diamond, sym_skull, sym_eye, sym_crescent, sym_star,
        sym_bolt, sym_wave, sym_arrow, sym_mask, sym_key, sym_coin, sym_spiral]


# ------------------------------------------------------------------ 主体图形库（场景，不是单图标）
def art_crown(cv, cx, cy, r, ink, acc, bg):
    rays(cv, cx, cy - r * 0.2, r * 0.95, 12, shade(bg, 1.25), 2)
    cv.poly([(cx - r * 0.84, cy + r * 0.5), (cx + r * 0.84, cy + r * 0.5), (cx + r * 0.84, cy - r * 0.1),
             (cx + r * 0.42, cy + r * 0.22), (cx, cy - r * 0.62), (cx - r * 0.42, cy + r * 0.22),
             (cx - r * 0.84, cy - r * 0.1)], ink)
    for dx in (-0.62, 0, 0.62):
        cv.disc(cx + dx * r, cy - r * 0.34, r * 0.12, acc)
    cv.bar(cx, cy + r * 0.68, r * 0.86, r * 0.14, ink)


def art_mask(cv, cx, cy, r, ink, acc, bg):
    cv.disc(cx, cy, r * 0.9, ink)
    cv.disc(cx - r * 0.34, cy - r * 0.12, r * 0.2, bg)
    cv.disc(cx + r * 0.34, cy - r * 0.12, r * 0.2, bg)
    cv.disc(cx - r * 0.34, cy - r * 0.12, r * 0.09, acc)
    cv.disc(cx + r * 0.34, cy - r * 0.12, r * 0.09, acc)
    cv.poly([(cx - r * 0.3, cy + r * 0.42), (cx + r * 0.3, cy + r * 0.42),
             (cx + r * 0.2, cy + r * 0.62), (cx - r * 0.2, cy + r * 0.62)], acc)


def art_eye(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx - r * 0.95, cy), (cx, cy - r * 0.6), (cx + r * 0.95, cy), (cx, cy + r * 0.6)], ink)
    cv.disc(cx, cy, r * 0.3, bg)
    cv.disc(cx, cy, r * 0.15, acc)
    rays(cv, cx, cy, r * 0.9, 8, shade(ink, 0.8), 1.5)


def art_moon(cv, cx, cy, r, ink, acc, bg):
    cv.disc(cx, cy, r * 0.8, ink)
    cv.disc(cx + r * 0.36, cy - r * 0.22, r * 0.68, bg)
    for i, (dx, dy, s) in enumerate(((-0.6, -0.5, 0.14), (0.55, 0.5, 0.1), (-0.2, 0.65, 0.08))):
        star(cv, cx + dx * r, cy + dy * r, r * s, 4, acc)


def art_serpent(cv, cx, cy, r, ink, acc, bg):
    for i, rr in enumerate((0.85, 0.62, 0.4)):
        cv.ring(cx, cy, rr * r, r * 0.16, ink, -40 + i * 25, 210 - i * 40)
    cv.disc(cx + r * 0.66, cy - r * 0.5, r * 0.16, acc)
    cv.disc(cx + r * 0.72, cy - r * 0.5, r * 0.05, bg)


def art_gate(cv, cx, cy, r, ink, acc, bg):
    cv.rrect(cx - r * 0.66, cy - r * 0.8, cx + r * 0.66, cy + r * 0.85, r * 0.12, ink)
    cv.rrect(cx - r * 0.42, cy - r * 0.55, cx + r * 0.42, cy + r * 0.85, r * 0.08, bg)
    cv.bar(cx, cy - r * 0.66, r * 0.8, r * 0.1, acc)
    cv.bar(cx, cy - r * 0.44, r * 0.62, r * 0.06, acc)
    cv.bar(cx, cy + r * 0.2, r * 0.05, r * 0.3, acc)


def art_chest(cv, cx, cy, r, ink, acc, bg):
    cv.rrect(cx - r * 0.8, cy - r * 0.05, cx + r * 0.8, cy + r * 0.72, r * 0.1, ink)
    cv.rrect(cx - r * 0.8, cy - r * 0.62, cx + r * 0.8, cy - r * 0.12, r * 0.1, shade(ink, 1.15))
    cv.bar(cx, cy - r * 0.08, r * 0.8, r * 0.09, acc)
    cv.disc(cx, cy + r * 0.1, r * 0.13, bg)
    cv.bar(cx, cy + r * 0.3, r * 0.05, r * 0.14, bg)


def art_dice(cv, cx, cy, r, ink, acc, bg):
    for (dx, dy, pips) in ((-0.32, -0.28, ((-0.26, -0.26), (0.26, 0.26), (0.26, -0.26))),
                           (0.34, 0.3, ((0, 0),))):
        x0, y0 = cx + dx * r, cy + dy * r
        s = r * 0.42
        cv.rrect(x0 - s, y0 - s, x0 + s, y0 + s, s * 0.22, ink)
        for px, py in pips:
            cv.disc(x0 + px * s, y0 + py * s, s * 0.16, acc)


def art_bolt(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx + r * 0.12, cy - r * 0.9), (cx - r * 0.55, cy + r * 0.12), (cx - r * 0.08, cy + r * 0.12),
             (cx - r * 0.3, cy + r * 0.9), (cx + r * 0.6, cy - r * 0.2), (cx + r * 0.08, cy - r * 0.2)], ink)
    rays(cv, cx, cy, r * 0.95, 6, acc, 1.5, 30)


def art_flame(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx, cy - r * 0.9), (cx + r * 0.5, cy + r * 0.05), (cx + r * 0.3, cy + r * 0.72),
             (cx - r * 0.3, cy + r * 0.72), (cx - r * 0.5, cy + r * 0.05)], ink)
    cv.poly([(cx, cy - r * 0.35), (cx + r * 0.24, cy + r * 0.28), (cx - r * 0.24, cy + r * 0.28)], acc)


def art_ripple(cv, cx, cy, r, ink, acc, bg):
    for i, rr in enumerate((0.34, 0.58, 0.82)):
        cv.ring(cx, cy, rr * r, r * 0.11, ink if i % 2 == 0 else acc)
    cv.disc(cx, cy, r * 0.14, ink)


def art_spiral(cv, cx, cy, r, ink, acc, bg):
    pts = []
    for i in range(160):
        t = i / 159.0
        a = t * math.pi * 3.2
        rr = r * (0.12 + 0.85 * t)
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    for i in range(len(pts) - 1):
        cv.line(pts[i], pts[i + 1], 2.4, ink if i % 3 else acc)


def art_coins(cv, cx, cy, r, ink, acc, bg):
    for dx, dy in ((-0.36, 0.34), (0.36, 0.34), (0, -0.34)):
        cv.disc(cx + dx * r, cy + dy * r, r * 0.4, ink)
        cv.ring(cx + dx * r, cy + dy * r, r * 0.22, r * 0.07, acc)


def art_key(cv, cx, cy, r, ink, acc, bg):
    cv.ring(cx - r * 0.18, cy - r * 0.38, r * 0.34, r * 0.14, ink)
    cv.bar(cx + r * 0.1, cy + r * 0.2, r * 0.1, r * 0.62, ink)
    cv.bar(cx + r * 0.34, cy + r * 0.62, r * 0.24, r * 0.08, acc)
    cv.bar(cx + r * 0.34, cy + r * 0.4, r * 0.18, r * 0.07, acc)


def art_bell(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx - r * 0.7, cy + r * 0.42), (cx - r * 0.42, cy - r * 0.2), (cx, cy - r * 0.62),
             (cx + r * 0.42, cy - r * 0.2), (cx + r * 0.7, cy + r * 0.42)], ink)
    cv.bar(cx, cy + r * 0.56, r * 0.82, r * 0.12, ink)
    cv.disc(cx, cy + r * 0.78, r * 0.14, acc)


def art_train(cv, cx, cy, r, ink, acc, bg):
    cv.rrect(cx - r * 0.8, cy - r * 0.1, cx + r * 0.55, cy + r * 0.5, r * 0.1, ink)
    cv.poly([(cx + r * 0.55, cy + r * 0.5), (cx + r * 0.55, cy - r * 0.3), (cx + r * 0.85, cy + r * 0.1),
             (cx + r * 0.85, cy + r * 0.5)], shade(ink, 1.2))
    cv.disc(cx - r * 0.5, cy + r * 0.62, r * 0.16, acc)
    cv.disc(cx + r * 0.1, cy + r * 0.62, r * 0.16, acc)
    cv.bar(cx, cy + r * 0.86, r * 0.9, r * 0.07, acc)


def art_tower(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx - r * 0.6, cy + r * 0.8), (cx - r * 0.4, cy - r * 0.6), (cx + r * 0.4, cy - r * 0.6),
             (cx + r * 0.6, cy + r * 0.8)], ink)
    cv.bar(cx, cy - r * 0.72, r * 0.5, r * 0.12, acc)
    for dy in (-0.2, 0.2, 0.6):
        cv.bar(cx, cy + dy * r, r * 0.2, r * 0.06, bg)


def art_scales(cv, cx, cy, r, ink, acc, bg):
    cv.bar(cx, cy - r * 0.55, r * 0.06, r * 0.75, ink)
    cv.bar(cx, cy + r * 0.12, r * 0.75, r * 0.07, ink)
    for dx in (-0.6, 0.6):
        cv.ring(cx + dx * r, cy + r * 0.46, r * 0.26, r * 0.09, acc)
        cv.line((cx, cy + r * 0.12), (cx + dx * r, cy + r * 0.2), 1.4, ink)


def art_fan(cv, cx, cy, r, ink, acc, bg):
    for a in (-55, -27, 0, 27, 55):
        rad = math.radians(a - 90)
        cv.line((cx, cy + r * 0.7), (cx + math.cos(rad) * r * 0.95, cy + r * 0.7 + math.sin(rad) * r * 0.95),
                2.6, ink)
    cv.disc(cx, cy + r * 0.7, r * 0.16, acc)


def art_lantern(cv, cx, cy, r, ink, acc, bg):
    cv.rrect(cx - r * 0.45, cy - r * 0.5, cx + r * 0.45, cy + r * 0.5, r * 0.2, ink)
    cv.bar(cx, cy - r * 0.62, r * 0.3, r * 0.08, acc)
    cv.bar(cx, cy + r * 0.62, r * 0.3, r * 0.08, acc)
    cv.disc(cx, cy, r * 0.18, acc)


def art_leaf(cv, cx, cy, r, ink, acc, bg):
    cv.line((cx, cy + r * 0.85), (cx, cy - r * 0.75), 2.2, shade(ink, 0.8))
    for i, s in enumerate((-0.5, -0.1, 0.3)):
        for side in (-1, 1):
            cv.poly([(cx, cy + s * r), (cx + side * r * 0.62, cy + (s - 0.22) * r),
                     (cx + side * r * 0.1, cy + (s + 0.2) * r)], ink if i % 2 == 0 else acc)


def art_sword(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx, cy - r * 0.9), (cx + r * 0.18, cy - r * 0.5), (cx + r * 0.12, cy + r * 0.35),
             (cx - r * 0.12, cy + r * 0.35), (cx - r * 0.18, cy - r * 0.5)], ink)
    cv.bar(cx, cy + r * 0.46, r * 0.55, r * 0.1, acc)
    cv.bar(cx, cy + r * 0.72, r * 0.12, r * 0.22, acc)


def art_shield(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx - r * 0.7, cy - r * 0.6), (cx + r * 0.7, cy - r * 0.6), (cx + r * 0.55, cy + r * 0.35),
             (cx, cy + r * 0.85), (cx - r * 0.55, cy + r * 0.35)], ink)
    cv.poly([(cx, cy - r * 0.35), (cx + r * 0.34, cy), (cx, cy + r * 0.45), (cx - r * 0.34, cy)], acc)


def art_mirror(cv, cx, cy, r, ink, acc, bg):
    cv.disc(cx, cy - r * 0.2, r * 0.62, ink)
    cv.disc(cx, cy - r * 0.2, r * 0.44, bg)
    cv.bar(cx, cy + r * 0.6, r * 0.14, r * 0.34, ink)
    cv.bar(cx, cy + r * 0.9, r * 0.34, r * 0.1, acc)


def art_book(cv, cx, cy, r, ink, acc, bg):
    cv.rrect(cx - r * 0.7, cy - r * 0.72, cx + r * 0.7, cy + r * 0.72, r * 0.1, ink)
    cv.rrect(cx - r * 0.55, cy - r * 0.58, cx + r * 0.55, cy + r * 0.58, r * 0.06, bg)
    for dy in (-0.28, 0, 0.28):
        cv.bar(cx, cy + dy * r, r * 0.4, r * 0.05, acc)


def art_hourglass(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx - r * 0.55, cy - r * 0.8), (cx + r * 0.55, cy - r * 0.8), (cx + r * 0.1, cy),
             (cx + r * 0.55, cy + r * 0.8), (cx - r * 0.55, cy + r * 0.8), (cx - r * 0.1, cy)], ink)
    cv.poly([(cx - r * 0.3, cy + r * 0.2), (cx + r * 0.3, cy + r * 0.2), (cx, cy + r * 0.6)], acc)
    cv.bar(cx, cy - r * 0.86, r * 0.6, r * 0.08, acc)


def art_gears(cv, cx, cy, r, ink, acc, bg):
    for (dx, dy, rr, teeth) in ((-0.26, -0.22, 0.5, 8), (0.36, 0.34, 0.34, 7)):
        x0, y0 = cx + dx * r, cy + dy * r
        cv.disc(x0, y0, rr * r, ink)
        for i in range(teeth):
            a = i * 2 * math.pi / teeth
            cv.disc(x0 + math.cos(a) * rr * r, y0 + math.sin(a) * rr * r, r * 0.08, ink)
        cv.disc(x0, y0, rr * r * 0.34, acc)


def art_droplet(cv, cx, cy, r, ink, acc, bg):
    cv.poly([(cx, cy - r * 0.85), (cx + r * 0.55, cy + r * 0.25), (cx, cy + r * 0.8),
             (cx - r * 0.55, cy + r * 0.25)], ink)
    cv.disc(cx - r * 0.16, cy + r * 0.18, r * 0.16, acc)


def art_lotus(cv, cx, cy, r, ink, acc, bg):
    for a in (-70, -35, 0, 35, 70):
        rad = math.radians(a - 90)
        cv.poly([(cx, cy + r * 0.6), (cx + math.cos(rad - 0.28) * r * 0.9, cy + r * 0.6 + math.sin(rad - 0.28) * r * 0.9),
                 (cx + math.cos(rad) * r * 1.05, cy + r * 0.6 + math.sin(rad) * r * 1.05),
                 (cx + math.cos(rad + 0.28) * r * 0.9, cy + r * 0.6 + math.sin(rad + 0.28) * r * 0.9)], ink)
    cv.disc(cx, cy + r * 0.72, r * 0.18, acc)


def art_pillar(cv, cx, cy, r, ink, acc, bg):
    cv.bar(cx, cy - r * 0.68, r * 0.55, r * 0.1, ink)
    cv.bar(cx, cy + r * 0.72, r * 0.62, r * 0.1, ink)
    cv.bar(cx, cy, r * 0.3, r * 0.66, ink)
    for dy in (-0.4, -0.14, 0.14, 0.4):
        cv.bar(cx, cy + dy * r, r * 0.24, r * 0.03, acc)


def art_skull(cv, cx, cy, r, ink, acc, bg):
    cv.disc(cx, cy - r * 0.1, r * 0.68, ink)
    cv.poly([(cx - r * 0.4, cy + r * 0.35), (cx + r * 0.4, cy + r * 0.35), (cx + r * 0.3, cy + r * 0.72),
             (cx - r * 0.3, cy + r * 0.72)], ink)
    for dx in (-0.26, 0.26):
        cv.disc(cx + dx * r, cy - r * 0.16, r * 0.16, bg)
    cv.poly([(cx - r * 0.06, cy + r * 0.14), (cx + r * 0.06, cy + r * 0.14), (cx, cy + r * 0.3)], bg)


def art_hand(cv, cx, cy, r, ink, acc, bg):
    cv.rrect(cx - r * 0.42, cy - r * 0.05, cx + r * 0.42, cy + r * 0.7, r * 0.18, ink)
    for dx, h in ((-0.3, 0.5), (-0.1, 0.68), (0.1, 0.62), (0.3, 0.44)):
        cv.bar(cx + dx * r, cy - h * r * 0.5, r * 0.09, h * r * 0.5, ink)
    cv.bar(cx - r * 0.5, cy + r * 0.22, r * 0.16, r * 0.1, acc)


def art_spider(cv, cx, cy, r, ink, acc, bg):
    cv.disc(cx, cy, r * 0.26, ink)
    cv.disc(cx, cy - r * 0.34, r * 0.16, ink)
    for side in (-1, 1):
        for i, a in enumerate((-40, -10, 20)):
            rad = math.radians(a)
            cv.line((cx, cy), (cx + side * math.cos(rad) * r * 0.85, cy + math.sin(rad) * r * 0.85), 1.6, acc)
    cv.ring(cx, cy, r * 0.8, 1.4, shade(acc, 0.8))


def art_needle(cv, cx, cy, r, ink, acc, bg):
    cv.bar(cx, cy, r * 0.1, r * 0.62, ink)
    cv.poly([(cx - r * 0.1, cy - r * 0.62), (cx + r * 0.1, cy - r * 0.62), (cx, cy - r * 0.95)], acc)
    cv.bar(cx, cy + r * 0.24, r * 0.3, r * 0.07, ink)
    cv.bar(cx, cy + r * 0.55, r * 0.22, r * 0.07, ink)
    cv.rrect(cx - r * 0.16, cy + r * 0.62, cx + r * 0.16, cy + r * 0.9, r * 0.05, acc)


def art_anchor(cv, cx, cy, r, ink, acc, bg):
    cv.ring(cx, cy - r * 0.6, r * 0.22, r * 0.1, ink)
    cv.bar(cx, cy - r * 0.1, r * 0.08, r * 0.55, ink)
    cv.bar(cx, cy - r * 0.34, r * 0.42, r * 0.07, ink)
    cv.ring(cx, cy + r * 0.42, r * 0.52, r * 0.13, acc, 20, 160)


def art_maze(cv, cx, cy, r, ink, acc, bg):
    cv.rrect(cx - r * 0.78, cy - r * 0.78, cx + r * 0.78, cy + r * 0.78, r * 0.1, ink)
    cv.rrect(cx - r * 0.6, cy - r * 0.6, cx + r * 0.6, cy + r * 0.6, r * 0.06, bg)
    for i, s in enumerate((0.36, 0.16)):
        cv.ring(cx, cy, s * r, r * 0.09, ink if i == 0 else acc, -90, 90)
        cv.ring(cx, cy, s * r, r * 0.09, ink if i == 1 else acc, 90, 270)
    cv.bar(cx, cy, r * 0.42, r * 0.08, ink)


ART = [art_crown, art_mask, art_eye, art_moon, art_serpent, art_gate, art_chest, art_dice, art_bolt,
       art_flame, art_ripple, art_spiral, art_coins, art_key, art_bell, art_train, art_tower, art_scales,
       art_fan, art_lantern, art_leaf, art_sword, art_shield, art_mirror, art_book, art_hourglass,
       art_gears, art_droplet, art_lotus, art_pillar, art_skull, art_hand, art_spider, art_needle,
       art_anchor, art_maze]


# ------------------------------------------------------------------ 卡面形制（构图/背景/配色三重变化）
def card_shell(cv, pal, radius=6):
    cv.rrect(0, 0, CW - 1, CH - 1, radius, pal['outline'])
    cv.rrect(1, 1, CW - 2, CH - 2, radius - 1, pal['frame'])
    cv.rrect(4, 4, CW - 5, CH - 5, radius - 2, pal['bg'])


def art_for(cv, box, idx, ink, acc, bg, seed=0):
    """背景纹理 + 构图模板 + 主体图形 三者按 idx/seed 确定性组合"""
    motif = ART[(idx + seed) % len(ART)]
    col, row = idx % 6, idx // 6
    BACKGROUNDS[(idx * 5 + row * 3 + seed * 7) % len(BACKGROUNDS)](cv, box, bg, acc)
    TEMPLATES[(idx * 7 + col * 2 + row * 5 + seed * 3) % len(TEMPLATES)](cv, box, motif, ink, acc, bg)


def badge(cv, cx, cy, r, idx, pal):
    """封印/贴纸的小徽章内部符号（粗剪影）"""
    cv.disc(cx, cy, r, pal['bg'])
    BOLD[(idx * 3) % len(BOLD)](cv, cx, cy, r * 0.62, pal['ink'], pal['acc'], pal['bg'])


def paint_joker(cv, idx, pal):
    card_shell(cv, pal)
    strip = shade(pal['bg'], 0.55 if pal['bg'][2] < 128 else 1.18)
    cv.rrect(4, 10, 12, 88, 2, strip)
    art_for(cv, (15, 9, CW - 9, CH - 12), idx, pal['ink'], pal['acc'], pal['bg'], seed=idx)
    # 标签与底条形成对比
    lab = (245, 245, 240, 255) if sum(strip[:3]) < 380 else (30, 26, 22, 255)
    text_v(cv, 'JOKER', 5, 33, 1, lab)
    cv.bar(CW / 2, 87, 24, 1.2, pal['acc'])


def paint_tarot(cv, idx, name, accent):
    bg = (230, 216, 178, 255)
    ink = (78, 54, 30, 255)
    cv.rrect(0, 0, CW - 1, CH - 1, 6, (54, 36, 20, 255))
    cv.rrect(1, 1, CW - 2, CH - 2, 5, bg)
    cv.rrect_outline(4, 4, CW - 5, CH - 5, 4, 1, ink)
    cv.rrect_outline(7, 7, CW - 8, CH - 8, 3, 1, accent)
    for (dx, dy) in ((11, 11), (CW - 12, 11), (11, CH - 12), (CW - 12, CH - 12)):
        star(cv, dx, dy, 2.6, 4, accent)
    art_for(cv, (11, 11, CW - 12, 70), idx, ink, accent, bg, seed=13)
    cv.rrect(9, 73, CW - 10, 87, 2, accent)
    cv.rrect(10, 74, CW - 11, 86, 2, (246, 238, 216, 255))
    w = text_w(name, 1, 1) - 1
    text(cv, name, CW / 2 - w / 2, 78, 1, ink, 1)


def paint_spectral(cv, idx, name, accent):
    bg = (20, 28, 62, 255)
    ink = (186, 220, 255, 255)
    cv.rrect(0, 0, CW - 1, CH - 1, 6, (8, 11, 28, 255))
    cv.rrect(1, 1, CW - 2, CH - 2, 5, (86, 122, 205, 255))
    cv.rrect(4, 4, CW - 5, CH - 5, 4, bg)
    cv.rrect_outline(7, 7, CW - 8, CH - 8, 3, 1, accent)
    for (dx, dy) in ((11, 11), (CW - 12, 11), (11, CH - 12), (CW - 12, CH - 12)):
        cv.disc(dx, dy, 1.8, ink)
    art_for(cv, (11, 11, CW - 12, 69), idx, ink, accent, bg, seed=29)
    cv.rrect(9, 72, CW - 10, 87, 2, accent)
    cv.rrect(10, 73, CW - 11, 86, 2, (16, 22, 50, 255))
    w = text_w(name, 1, 1) - 1
    text(cv, name, CW / 2 - w / 2, 77, 1, ink, 1)


def paint_voucher(cv, idx, pal):
    cv.rrect(0, 0, CW - 1, CH - 1, 6, pal['outline'])
    cv.rrect(1, 1, CW - 2, CH - 2, 5, pal['bg'])
    cv.rrect_outline(4, 4, CW - 5, CH - 5, 4, 2, (238, 238, 236, 255))
    cv.rrect(13, 7, CW - 14, 18, 2, pal['outline'])
    cv.rrect(14, 8, CW - 15, 17, 2, (238, 238, 236, 255))
    w = text_w('VOUCHER', 1, 1) - 1
    text(cv, 'VOUCHER', CW / 2 - w / 2, 11, 1, pal['outline'], 1)
    art_for(cv, (10, 22, CW - 11, 80), idx, pal['ink'], pal['acc'], pal['bg'], seed=41)
    cv.bar(CW / 2, 85, 22, 1.2, (238, 238, 236, 200))


def paint_seal(cv, idx, pal):
    cx, cy, r = 13, 13, 10
    cv.disc(cx, cy, r, pal['outline'])
    cv.disc(cx, cy, r - 1.4, pal['bg'])
    cv.ring(cx, cy, r - 2.6, 1.2, pal['ink'])
    badge(cv, cx, cy, r - 4.0, idx, pal)


def paint_sticker(cv, idx, pal):
    cx, cy, r = 12, 12, 9.5
    cv.disc(cx, cy, r, pal['outline'])
    cv.disc(cx, cy, r - 1.2, pal['bg'])
    for i in range(10):
        a = i * math.pi / 5
        cv.disc(cx + math.cos(a) * (r - 0.7), cy + math.sin(a) * (r - 0.7), 1.4, pal['acc'])
    cv.disc(cx, cy, r - 3.2, pal['panel'])
    BOLD[(idx * 5) % len(BOLD)](cv, cx, cy, (r - 4.2) * 0.7, pal['ink'], pal['acc'], pal['panel'])


def paint_tag(cv, idx, pal, size=34):
    cv.rrect(1, 1, size - 2, size - 2, 6, (234, 234, 230, 255))
    cv.rrect(3, 3, size - 4, size - 4, 5, pal['outline'])
    cv.rrect(4, 4, size - 5, size - 5, 4, pal['bg'])
    # 面板纹理按 idx 变化
    style = (idx * 3 + idx // 8) % 4
    if style == 1:
        for y in range(8, size - 7, 4):
            cv.bar(size / 2, y, (size - 12) / 2, 0.9, shade(pal['bg'], 1.25))
    elif style == 2:
        scatter(cv, (7, 7, size - 7, size - 7), 14, shade(pal['bg'], 1.3), 1.0, seed=idx + 5)
    elif style == 3:
        for k in range(3):
            y = 9 + k * 7
            cv.poly([(6, y), (size / 2, y + 4), (size - 6, y), (size - 6, y + 1.6),
                     (size / 2, y + 5.6), (6, y + 1.6)], shade(pal['bg'], 1.25))
    BOLD[idx % len(BOLD)](cv, size / 2, size / 2, 9.2, pal['ink'], pal['acc'], pal['bg'])
    for t in range(2):
        cv.line((6, 5 + t), (size - 7, 5 + t), 1, shade(pal['bg'], 1.5))
        cv.line((6, size - 6 - t), (size - 7, size - 6 - t), 1, shade(pal['bg'], 0.7))


def paint_blind(cv, idx, pal, label, frame, size=34):
    c = size / 2
    r = size / 2 - 0.6
    cv.disc(c, c, r, pal['outline'])
    cv.disc(c, c, r - 1.2, pal['bg'])
    style = idx % 4
    ang0 = frame * (360.0 / 21.0)
    if style == 0:
        for i in range(10):
            a0 = ang0 + i * 36
            cv.ring(c, c, r - 1.8, 1.6, shade(pal['bg'], 1.4), a0, a0 + 20)
    elif style == 1:
        for i in range(6):
            a0 = ang0 + i * 60
            cv.ring(c, c, r - 1.8, 2.0, shade(pal['bg'], 1.4), a0, a0 + 34)
    elif style == 2:
        for i in range(12):
            a = math.radians(ang0 + i * 30)
            cv.disc(c + math.cos(a) * (r - 1.8), c + math.sin(a) * (r - 1.8), 1.3, shade(pal['bg'], 1.45))
    else:
        cv.ring(c, c, r - 1.6, 1.0, shade(pal['bg'], 1.4))
        cv.ring(c, c, r - 3.2, 1.0, shade(pal['bg'], 1.3))
    cv.ring(c, c, r - 4.2, 1.1, pal['outline'])
    cv.disc(c, c, r - 5.6, pal['panel'])
    BOLD[idx % len(BOLD)](cv, c, c + 1.0, 7.6, pal['ink'], pal['acc'], pal['panel'])
    w = text_w(label, 1, 0) - 1
    cv.rrect(c - w / 2 - 1, 1.4, c + w / 2 + 1, 6.4, 1.5, pal['outline'])
    text(cv, label, c - w / 2, 2.2, 1, (246, 246, 242, 255), 0)


# ------------------------------------------------------------------ 调色
def pal_card(idx, seed=0):
    h = (idx * 47 + seed * 23 + 12) % 360
    light = (idx + seed) % 3 == 0          # 1/3 的卡用浅底深墨，避免全是深底
    if light:
        return {'bg': hsv(h, 0.28, 0.86), 'ink': hsv(h, 0.75, 0.24), 'acc': hsv((h + 200) % 360, 0.6, 0.45),
                'frame': hsv(h, 0.12, 0.96), 'outline': hsv(h, 0.6, 0.2), 'label': hsv(h, 0.7, 0.3)}
    return {'bg': hsv(h, 0.7, 0.30), 'ink': hsv((h + 24) % 360, 0.14, 0.97), 'acc': hsv((h + 180) % 360, 0.62, 0.80),
            'frame': hsv((h + 12) % 360, 0.10, 0.92), 'outline': hsv(h, 0.5, 0.13), 'label': hsv(h, 0.4, 0.24)}


def pal_voucher(idx):
    h = (idx * 53 + 8) % 360
    return {'bg': hsv(h, 0.6, 0.62), 'ink': hsv((h + 20) % 360, 0.05, 0.98),
            'acc': hsv((h + 30) % 360, 0.35, 0.32), 'outline': hsv(h, 0.68, 0.22),
            'frame': hsv(h, 0.2, 0.9)}


def pal_seal(idx):
    h = idx * 67
    return {'bg': hsv(h, 0.55, 0.72), 'ink': hsv((h + 20) % 360, 0.1, 0.98),
            'acc': hsv((h + 180) % 360, 0.5, 0.9), 'outline': hsv(h, 0.6, 0.22)}


def pal_sticker(idx):
    h = idx * 71 + 30
    return {'bg': hsv(h, 0.6, 0.66), 'ink': hsv((h + 20) % 360, 0.12, 0.98),
            'acc': hsv((h + 180) % 360, 0.55, 0.9), 'outline': hsv(h, 0.65, 0.2),
            'panel': hsv(h, 0.3, 0.88)}


def pal_tag(idx):
    h = (idx * 59 + 20) % 360
    return {'bg': hsv(h, 0.45, 0.74), 'ink': hsv((h + 20) % 360, 0.08, 0.98),
            'acc': hsv((h + 190) % 360, 0.5, 0.85), 'outline': hsv(h, 0.5, 0.24),
            'panel': hsv(h, 0.2, 0.9)}


def pal_blind(idx):
    h = (idx * 31 + 205) % 360
    return {'bg': hsv(h, 0.5, 0.60), 'outline': hsv(h, 0.45, 0.15),
            'panel': hsv(h, 0.18, 0.88), 'ink': hsv(h, 0.65, 0.22),
            'acc': hsv((h + 45) % 360, 0.6, 0.5), 'frame': hsv(h, 0.3, 0.8)}


# ------------------------------------------------------------------ 输出
def downsample(src, factor):
    w, h = src.w // factor, src.h // factor
    out = bytearray(w * h * 4)
    n = factor * factor
    for y in range(h):
        for x in range(w):
            r = g = b = a = 0
            for dy in range(factor):
                base = ((y * factor + dy) * src.w + x * factor) * 4
                for dx in range(factor):
                    i = base + dx * 4
                    r += src.buf[i]; g += src.buf[i + 1]; b += src.buf[i + 2]; a += src.buf[i + 3]
            j = (y * w + x) * 4
            out[j:j + 4] = bytes((r // n, g // n, b // n, a // n))
    return w, h, out


def write_png(path, w, h, px):
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        raw += px[y * w * 4:(y + 1) * w * 4]

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "wb").write(png)


def render_at(w, h, painter):
    cv = Canvas(w * SS, h * SS, SS)
    painter(cv)
    return cv


def sheet(name, cols, rows, cw, ch, painter_at, scales=(1, 2)):
    if globals().get('ONLY') and name not in globals()['ONLY']:
        return
    for scale in scales:
        s_cw, s_ch = cw * scale, ch * scale
        sw, sh = s_cw * cols, s_ch * rows
        out = bytearray(sw * sh * 4)
        for idx in range(cols * rows):
            col, row = idx % cols, idx // cols
            cv = render_at(cw, ch, lambda c, i=idx: painter_at(c, i))
            w, h, px = downsample(cv, SS // scale)
            assert (w, h) == (s_cw, s_ch), (w, h, s_cw, s_ch)
            x0, y0 = col * s_cw, row * s_ch
            for y in range(s_ch):
                si = y * s_cw * 4
                di = ((y0 + y) * sw + x0) * 4
                out[di:di + s_cw * 4] = px[si:si + s_cw * 4]
        path = f"{ROOT}/{scale}x/{name}.png"
        write_png(path, sw, sh, out)
        print("wrote", path, sw, sh, flush=True)


# ------------------------------------------------------------------ 内容清单
TAROT_NAMES = ['DOMINION', 'MIRROR', 'ASCENSION', 'PACT', 'CORNUCOPIA',
               'RAT', 'OX', 'TIGER', 'RABBIT', 'DRAGON', 'SNAKE', 'HORSE',
               'GOAT', 'MONKEY', 'ROOSTER', 'DOG', 'PIG',
               'AZURE DRAGON', 'VERMILION', 'WHITE TIGER', 'BLACK TORTOISE']

SPECTRAL_NAMES = ['DOPPELGANGER', 'ANTIMATTER', 'OFFERING', 'ENTROPY', 'ECHO',
                  'SAMSARA', 'MEMORY', 'VORTEX', 'CONTRACT', 'INDEX']

BLIND_LABELS = ['RAT', 'OX', 'TIGER', 'RABBIT', 'SNAKE', 'HORSE',
                'GOAT', 'MONKEY', 'ROOSTER', 'DOG', 'PIG', 'DRAGON']

TAROT_ACCENTS = [(176, 136, 58, 255), (150, 60, 50, 255), (60, 100, 130, 255), (110, 80, 150, 255)]


def main():
    sheet('blh_joker', 6, 6, CW, CH,
          lambda c, i: _joker(c, i))
    sheet('blh_tarot', 7, 3, CW, CH,
          lambda c, i: paint_tarot(c, i, TAROT_NAMES[i], TAROT_ACCENTS[i % 4]))
    sheet('blh_spectral', 5, 2, CW, CH,
          lambda c, i: paint_spectral(c, i, SPECTRAL_NAMES[i], TAROT_ACCENTS[(i + 2) % 4]))
    sheet('blh_voucher', 8, 2, CW, CH,
          lambda c, i: paint_voucher(c, i, pal_voucher(i)))
    sheet('blh_seal', 5, 1, CW, CH, lambda c, i: paint_seal(c, i, pal_seal(i)))
    sheet('blh_sticker', 5, 1, CW, CH, lambda c, i: paint_sticker(c, i, pal_sticker(i)))
    sheet('blh_tag', 8, 2, 34, 34, lambda c, i: paint_tag(c, i, pal_tag(i)))
    sheet('blh_blind', 21, 12, 34, 34,
          lambda c, i: paint_blind(c, i // 21, pal_blind(i // 21), BLIND_LABELS[i // 21], i % 21))


def _joker(c, i):
    paint_joker(c, i, pal_card(i))


if __name__ == '__main__':
    import sys
    only = set(sys.argv[1:])
    if only:
        globals()['ONLY'] = only
    main()
