"""
앱 아이콘 생성 스크립트.
Pillow로 직접 도형을 그려 SVG 렌더러 의존성 없이 생성.
"""

import os
from PIL import Image, ImageDraw

ICON_COLOR = (240, 78, 35, 255)   # AppTheme.primaryColor #F04E23
BASE_PATH  = 'android/app/src/main/res'

# 색상 (Twemoji 1f373.svg 기준)
DARK  = (41,  47,  51,  255)   # #292F33  손잡이·팬 테두리
GRAY  = (102, 117, 127, 255)   # #66757F  팬 본체
WHITE = (245, 248, 250, 255)   # #F5F8FA  계란 흰자
YOLK  = (255, 172,  51, 255)   # #FFAC33  노른자

SIZES = {
    'mipmap-mdpi':    48,
    'mipmap-hdpi':    72,
    'mipmap-xhdpi':   96,
    'mipmap-xxhdpi':  144,
    'mipmap-xxxhdpi': 192,
}


def draw_emoji(size: int) -> Image.Image:
    """프라이팬 계란 후라이를 Pillow 도형으로 직접 그린다.
    좌표계: Twemoji SVG viewBox 0 0 36 36 기준.
    """
    img  = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    s    = size / 36.0

    def p(v):
        return v * s

    def box(x0, y0, x1, y1):
        return [p(x0), p(y0), p(x1), p(y1)]

    # ── 손잡이 (handle) ──────────────────────────────────────────────
    hw = max(3, int(p(5.2)))
    x1, y1 = p(25.5), p(23)
    x2, y2 = p(35.5), p(33.5)
    draw.line([(x1, y1), (x2, y2)], fill=DARK, width=hw)
    r = hw / 2
    draw.ellipse([x1-r, y1-r, x1+r, y1+r], fill=DARK)
    draw.ellipse([x2-r, y2-r, x2+r, y2+r], fill=DARK)

    # ── 팬 외곽 (다크 테두리 포함 전체) ─────────────────────────────
    draw.ellipse(box(0, 0, 30, 30), fill=DARK)

    # ── 팬 본체 (회색) ───────────────────────────────────────────────
    draw.ellipse(box(3, 3, 27, 27), fill=GRAY)

    # ── 계란 흰자 ────────────────────────────────────────────────────
    draw.ellipse(box(6, 4.5, 21.5, 24.5), fill=WHITE)

    # ── 노른자 ───────────────────────────────────────────────────────
    draw.ellipse(box(9, 14, 17, 22), fill=YOLK)

    return img


def create_icon(size: int, emoji_img: Image.Image) -> Image.Image:
    """오렌지 라운드 사각형 배경 위에 이모지를 합성."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))

    bg   = Image.new('RGBA', (size, size), ICON_COLOR)
    mask = Image.new('L',    (size, size), 0)
    radius = max(1, int(size * 0.22))
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=radius, fill=255
    )
    img.paste(bg, mask=mask)

    # 이모지: 아이콘의 80% 크기, 중앙 배치
    emoji_size = int(size * 0.80)
    emoji = emoji_img.resize((emoji_size, emoji_size), Image.LANCZOS)
    offset = (size - emoji_size) // 2
    img.paste(emoji, (offset, offset), emoji)

    return img


def main():
    print('Drawing emoji...')
    full_emoji = draw_emoji(512)   # 고해상도로 그린 뒤 리사이즈

    for folder, size in SIZES.items():
        out  = os.path.join(BASE_PATH, folder, 'ic_launcher.png')
        icon = create_icon(size, full_emoji)
        icon.save(out, 'PNG')
        print(f'OK  {out}  ({size}x{size})')

    print('\nDone!')


if __name__ == '__main__':
    main()
