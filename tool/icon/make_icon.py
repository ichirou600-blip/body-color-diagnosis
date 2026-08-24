"""ラキカラのアプリアイコンを生成する。

コンセプト: 「ラッキー × カラー」= 4色の花びらでできた四つ葉のクローバー。
- 淡い色を4つ使い、色数で「カラー」を、四つ葉で「ラッキー」を出す
- 重なりは明るいまま保つ（乗算だと濁ってベン図に見えるため使わない）
- 小さく表示しても4色が判別できるよう、花びらは重ねすぎない
"""
from PIL import Image, ImageDraw, ImageFilter

SS = 4
SIZE = 1024
S = SIZE * SS
C = S // 2

# 4分類のパーソナルカラーを淡くしたもの。小さくても色が飛ばない程度の彩度は残す
PETAL_COLORS = [
    (255, 154, 174),   # コーラルピンク
    (255, 206, 143),   # アプリコット
    (150, 216, 196),   # ミント
    (176, 178, 240),   # ラベンダー
]


def diagonal_gradient(size, top, bottom):
    base = Image.new("RGB", (size, size), top)
    grad = Image.new("L", (size, size))
    px = grad.load()
    for y in range(size):
        v_row = (y / size) * 0.62
        for x in range(0, size, 8):
            v = int(255 * (v_row + (x / size) * 0.38))
            for dx in range(8):
                if x + dx < size:
                    px[x + dx, y] = v
    return Image.composite(Image.new("RGB", (size, size), bottom), base, grad)


def petal_mask(rx, ry, offset):
    """上向きの花びら1枚。放射方向に伸ばした楕円にすると花びららしく見える。
    真円にすると「4つの丸」にしか見えず、クローバーとして読まれない。"""
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse(
        [C - rx, C - offset - ry, C + rx, C - offset + ry], fill=255)
    return mask


def build(with_background=True, art_scale=1.0):
    if with_background:
        img = diagonal_gradient(S, (255, 247, 249), (240, 238, 252)).convert("RGBA")
    else:
        img = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    base = petal_mask(
        rx=int(S * 0.118 * art_scale),
        ry=int(S * 0.163 * art_scale),
        offset=int(S * 0.142 * art_scale),
    )

    # 45度ずらした4枚で四つ葉にする。重なりは中心付近だけ
    for index, color in enumerate(PETAL_COLORS):
        mask = base.rotate(45 + index * 90, resample=Image.BICUBIC, center=(C, C))
        mask = mask.filter(ImageFilter.GaussianBlur(SS * 1.4))
        layer = Image.new("RGBA", (S, S), color + (232,))
        img = Image.alpha_composite(img, Image.composite(
            layer, Image.new("RGBA", (S, S), (0, 0, 0, 0)), mask))

    overlay = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    # 花の中心。ぼかしを強くしすぎると灰色のにじみに見えるので、
    # 白をはっきり置いて縁だけ少しぼかす
    core = int(S * 0.050 * art_scale)
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse(
        [C - core, C - core, C + core, C + core], fill=(255, 253, 250, 255))
    overlay = Image.alpha_composite(
        overlay, glow.filter(ImageFilter.GaussianBlur(SS * 2.2)))
    d = ImageDraw.Draw(overlay)

    def sparkle(cx, cy, r, w, alpha):
        d.polygon([(cx, cy - r), (cx + w, cy), (cx, cy + r), (cx - w, cy)], fill=(255, 255, 255, alpha))
        d.polygon([(cx - r, cy), (cx, cy - w), (cx + r, cy), (cx, cy + w)], fill=(255, 255, 255, alpha))

    sparkle(int(S * 0.792), int(S * 0.212), int(S * 0.070 * art_scale), int(S * 0.015 * art_scale), 255)
    sparkle(int(S * 0.222), int(S * 0.788), int(S * 0.042 * art_scale), int(S * 0.009 * art_scale), 225)

    img = Image.alpha_composite(img, overlay)
    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    return img.convert("RGB") if with_background else img


build(with_background=True).save("tool/icon/app_icon.png")
build(with_background=False, art_scale=0.68).save("tool/icon/app_icon_foreground.png")
print("done")
