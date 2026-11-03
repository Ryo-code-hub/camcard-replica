
# -*- coding: utf-8 -*-
"""生成合成测试名片（无需真实个人信息），并输出 Ground Truth JSON。"""
import json
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "sample_data", "cards")
APP_SAMPLE_DIR = os.path.join(ROOT, "App", "Resources", "SampleCards")
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(APP_SAMPLE_DIR, exist_ok=True)

FONT_CANDIDATES = [
    r"C:\Windows\Fonts\msyh.ttc",
    r"C:\Windows\Fonts\msyhbd.ttc",
    r"C:\Windows\Fonts\simhei.ttf",
    r"C:\Windows\Fonts\arial.ttf",
    "/System/Library/Fonts/PingFang.ttc",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
]

def pick_font(size, bold=False):
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()

def hex_color(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))

def make_card(path, width, height, lines, accent="#1f4e79", background="#fdfdfd"):
    image = Image.new("RGB", (width, height), hex_color(background))
    draw = ImageDraw.Draw(image)
    draw.rectangle([0, 0, width, int(height * 0.045)], fill=hex_color(accent))
    y = int(height * 0.16)
    for text, size, color, gap in lines:
        font = pick_font(size)
        draw.text((int(width * 0.08), y), text, font=font, fill=hex_color(color))
        y += gap
    image.save(path, "PNG")

cards = [
    {
        "id": "card_01_en",
        "file": "card_01_en.png",
        "width": 1200,
        "height": 680,
        "lines": [
            ("Dr. David Chen", 62, "#111111", 80),
            ("Professor", 34, "#444444", 55),
            ("School of Computer Science", 28, "#666666", 48),
            ("ABC University", 30, "#1f4e79", 70),
            ("Mobile: +86 138 0013 8000", 26, "#222222", 44),
            ("Email: david@abc.edu", 26, "#222222", 44),
            ("Website: www.abc.edu", 26, "#222222", 44),
        ],
        "ground_truth": {
            "name": "David Chen",
            "company": "ABC University",
            "jobTitle": "Professor",
            "mobile": "+86 138 0013 8000",
            "email": "david@abc.edu",
            "website": "www.abc.edu",
        },
    },
    {
        "id": "card_02_zh",
        "file": "card_02_zh.png",
        "width": 1200,
        "height": 680,
        "lines": [
            ("朱宏明", 66, "#111111", 84),
            ("教授", 36, "#444444", 58),
            ("同济大学", 32, "#1f4e79", 76),
            ("手机：13800138000", 26, "#222222", 44),
            ("邮箱：zhu@tongji.edu.cn", 26, "#222222", 44),
            ("地址：上海市杨浦区四平路1239号", 24, "#222222", 40),
        ],
        "ground_truth": {
            "name": "朱宏明",
            "company": "同济大学",
            "jobTitle": "教授",
            "mobile": "13800138000",
            "email": "zhu@tongji.edu.cn",
            "address": "上海市杨浦区四平路1239号",
        },
    },
    {
        "id": "card_03_bi",
        "file": "card_03_bi.png",
        "width": 1200,
        "height": 680,
        "lines": [
            ("Jordan Lee", 60, "#111111", 78),
            ("Director", 32, "#444444", 52),
            ("Lee Consulting", 30, "#1f4e79", 66),
            ("Tel: 021-12345678", 25, "#222222", 42),
            ("Mobile: 13900139000", 25, "#222222", 42),
            ("Fax: 021-87654321", 25, "#222222", 42),
            ("Email: jordan@leeconsulting.com", 25, "#222222", 42),
        ],
        "ground_truth": {
            "name": "Jordan Lee",
            "company": "Lee Consulting",
            "jobTitle": "Director",
            "officePhone": "021-12345678",
            "mobile": "13900139000",
            "fax": "021-87654321",
            "email": "jordan@leeconsulting.com",
        },
    },
    {
        "id": "card_04_vertical",
        "file": "card_04_vertical.png",
        "width": 900,
        "height": 1500,
        "lines": [
            ("李伟", 84, "#111111", 108),
            ("首席工程师", 46, "#444444", 76),
            ("华为技术有限公司", 44, "#1f4e79", 96),
            ("Mobile: 13700137000", 34, "#222222", 56),
            ("Email: LiWei@example.com", 34, "#222222", 56),
            ("地址：深圳市龙岗区坂田街道1号", 30, "#222222", 50),
        ],
        "ground_truth": {
            "name": "李伟",
            "company": "华为技术有限公司",
            "jobTitle": "首席工程师",
            "mobile": "13700137000",
            "email": "LiWei@example.com",
            "address": "深圳市龙岗区坂田街道1号",
        },
    },
    {
        "id": "card_05_missing",
        "file": "card_05_missing.png",
        "width": 1200,
        "height": 680,
        "lines": [
            ("Alice Wang", 60, "#111111", 80),
            ("XYZ Technologies", 30, "#1f4e79", 70),
            ("Mobile: 13900139001", 26, "#222222", 44),
        ],
        "ground_truth": {
            "name": "Alice Wang",
            "company": "XYZ Technologies",
            "mobile": "13900139001",
        },
    },
    {
        "id": "card_06_ambiguous",
        "file": "card_06_ambiguous.png",
        "width": 1200,
        "height": 680,
        "lines": [
            ("Apple", 58, "#111111", 78),
            ("One Apple Park Way", 26, "#444444", 46),
            ("Mobile: 13800138002", 26, "#222222", 44),
        ],
        "ground_truth": {
            "mobile": "13800138002",
            "address": "One Apple Park Way",
        },
    },
]

manifest = []
for card in cards:
    out_path = os.path.join(OUT_DIR, card["file"])
    make_card(out_path, card["width"], card["height"], card["lines"])
    manifest.append({
        "id": card["id"],
        "image": card["file"],
        "ground_truth": card["ground_truth"],
    })
    print("generated", out_path)

with open(os.path.join(ROOT, "sample_data", "ground_truth.json"), "w", encoding="utf-8") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)

copy_map = {
    "card_01_en.png": "sample_card_01.png",
    "card_02_zh.png": "sample_card_02.png",
    "card_03_bi.png": "sample_card_03.png",
}
for src_name, dst_name in copy_map.items():
    src = os.path.join(OUT_DIR, src_name)
    dst = os.path.join(APP_SAMPLE_DIR, dst_name)
    with open(src, "rb") as fsrc, open(dst, "wb") as fdst:
        fdst.write(fsrc.read())
    print("copied", dst)
