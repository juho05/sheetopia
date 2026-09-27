"""Freehand stroke generation for the demo library.

Strokes are stored the same way the app stores them (see
lib/data/repositories/scores/stroke.dart): normalized 0..1 page coordinates plus
a baked outline polygon that the painter fills directly. The app bakes that
outline with perfect_freehand in a fixed 1000 x (1000 * aspect) reference space;
this module reproduces the same space with a plain constant-width offset
polygon, which renders identically for the smooth strokes used here.
"""

import math
import random

REF_WIDTH = 1000.0
CAP_SEGMENTS = 8

RED = 0xFFFF0000
BLUE = 0xFF2196F3
GREEN = 0xFF4CAF50
HIGHLIGHTER = 0x88FFEB3B

PEN_WIDTH = 0.0035
HIGHLIGHTER_WIDTH = 0.018


def _round(v):
    return round(v * 100000) / 100000


def _offsets(points, half_width):
    left, right = [], []
    n = len(points)
    for i, (px, py) in enumerate(points):
        if i == 0:
            dx, dy = points[1][0] - px, points[1][1] - py
        elif i == n - 1:
            dx, dy = px - points[-2][0], py - points[-2][1]
        else:
            dx = points[i + 1][0] - points[i - 1][0]
            dy = points[i + 1][1] - points[i - 1][1]
        length = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / length * half_width, dx / length * half_width
        left.append((px + nx, py + ny))
        right.append((px - nx, py - ny))
    return left, right


def _cap(center, start, radius):
    """Half circle sweeping -pi from `start`, i.e. around the outside of an end."""
    cx, cy = center
    a0 = math.atan2(start[1] - cy, start[0] - cx)
    return [
        (cx + math.cos(a0 - math.pi * i / CAP_SEGMENTS) * radius,
         cy + math.sin(a0 - math.pi * i / CAP_SEGMENTS) * radius)
        for i in range(1, CAP_SEGMENTS)
    ]


def build_outline(points, width, aspect):
    ref_height = REF_WIDTH * aspect
    pts = []
    for x, y in points:
        p = (x * REF_WIDTH, y * ref_height)
        if not pts or math.dist(p, pts[-1]) > 1e-6:
            pts.append(p)

    half = width * max(REF_WIDTH, ref_height) / 2

    if len(pts) < 2:
        cx, cy = pts[0]
        ring = [
            (cx + math.cos(2 * math.pi * i / 24) * half,
             cy + math.sin(2 * math.pi * i / 24) * half)
            for i in range(24)
        ]
        outline = ring
    else:
        left, right = _offsets(pts, half)
        outline = (
            left
            + _cap(pts[-1], left[-1], half)
            + list(reversed(right))
            + _cap(pts[0], right[0], half)
        )

    flat = []
    for x, y in outline:
        flat.append(_round(x / REF_WIDTH))
        flat.append(_round(y / ref_height))
    return flat


def stroke(points, color=RED, width=PEN_WIDTH, aspect=math.sqrt(2), pressure=0.5):
    return {
        "c": color,
        "w": width,
        "p": [[_round(x), _round(y), pressure] for x, y in points],
        "o": build_outline(points, width, aspect),
    }


# --- shape helpers -----------------------------------------------------------
# A small amount of jitter keeps the marks from looking machine drawn. The RNG is
# seeded per library build so the output stays byte identical between runs.

def _jitter(rng, amount):
    return (rng.uniform(-amount, amount), rng.uniform(-amount, amount))


def ellipse(rng, cx, cy, rx, ry, segments=28, wobble=0.0012, overshoot=0.35):
    pts = []
    start = rng.uniform(0, 2 * math.pi)
    total = 2 * math.pi + overshoot
    for i in range(segments + 1):
        a = start + total * i / segments
        jx, jy = _jitter(rng, wobble)
        pts.append((cx + math.cos(a) * rx + jx, cy + math.sin(a) * ry + jy))
    return pts


def line(rng, x1, y1, x2, y2, segments=10, wobble=0.0012):
    pts = []
    for i in range(segments + 1):
        t = i / segments
        jx, jy = _jitter(rng, wobble)
        pts.append((x1 + (x2 - x1) * t + jx, y1 + (y2 - y1) * t + jy))
    return pts


def wave(rng, x1, x2, y, cycles=5, amplitude=0.004, segments=48):
    pts = []
    for i in range(segments + 1):
        t = i / segments
        pts.append((
            x1 + (x2 - x1) * t,
            y + math.sin(t * cycles * 2 * math.pi) * amplitude + rng.uniform(-0.0006, 0.0006),
        ))
    return pts


def bracket(rng, x, y1, y2, arm=0.014):
    pts = line(rng, x + arm, y1, x, y1, segments=4)
    pts += line(rng, x, y1, x, y2, segments=10)[1:]
    pts += line(rng, x, y2, x + arm, y2, segments=4)[1:]
    return pts


def check(rng, x, y, size=0.012):
    return line(rng, x, y, x + size * 0.5, y + size, segments=4) + \
        line(rng, x + size * 0.5, y + size, x + size * 1.6, y - size * 0.9, segments=6)[1:]


def caret(rng, x, y, size=0.010):
    return line(rng, x - size, y + size, x, y, segments=4) + \
        line(rng, x, y, x + size, y + size, segments=4)[1:]
