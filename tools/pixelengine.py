#!/usr/bin/env python3
"""
Gọi API PixelEngine (https://pixelengine.ai/docs/api-reference).

    # điền PIXELENGINE_API_KEY=pe_sk_... vào .env ở thư mục dự án (mẫu: .env.example)
    python3 tools/pixelengine.py balance                                  # credit còn lại (miễn phí)
    python3 tools/pixelengine.py billing                                  # credit đã dùng 30 ngày qua (miễn phí)
    python3 tools/pixelengine.py image "mô tả" --name TÊN [--ref ẢNH.png] [--model nb_flash] [--colors 32]
    python3 tools/pixelengine.py animate ẢNH.png "mô tả" [--frames 8]   # 20 credit
    python3 tools/pixelengine.py batch ẢNH.png "idle=8:mô tả" "hurt=6:mô tả" ...   # 20 + 12 mỗi animation thêm
    python3 tools/pixelengine.py nobg ẢNH.png                             # xoá nền, 2 credit
    python3 tools/pixelengine.py fit ẢNH.png --name art/pixelengine/TÊN    # nền trong, khung 68×68 (miễn phí)
    python3 tools/pixelengine.py pack TÊN ẢNH_GỐC.png idle=SHEET.png run=SHEET.png ...   # xếp cho game (miễn phí)

image tạo ảnh pixel art từ mô tả (model oai_gpt25_low 6, nb_flash / oai_gpt25_high 12, nb_pro / oai_gpt25_max 36
credit); --ref là ảnh mẫu để giữ phong cách. animate và batch dùng model pixel-engine-v1.1 (PNG ≤256 px mỗi chiều,
frame chẵn 2–16), trả spritesheet có nền --matte (mặc định hồng #FF00FF để xoá nền dễ). Mỗi lệnh chờ job xong rồi tải kết quả về --out (mặc định art/pixelengine/), kèm file .json
ghi mô tả, cỡ ảnh và số credit đã trừ. File trên máy chủ PixelEngine hết hạn sau 24 giờ nên phải tải về ngay.
"""
import argparse
import base64
import colorsys
import json
import os
import sys
import time
import urllib.error
import urllib.request

BASE = "https://api.pixelengine.ai/functions/v1"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "art", "pixelengine")
EXT = {"image/png": ".png", "image/webp": ".webp", "image/gif": ".gif"}


def load_env():
    """Đọc ROOT/.env (dòng TÊN=giá trị). Biến đã đặt sẵn trong shell được ưu tiên."""
    path = os.path.join(ROOT, ".env")
    if not os.path.exists(path):
        return
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            name, value = line.split("=", 1)
            os.environ.setdefault(name.strip(), value.strip().strip("\"'"))


def call(method, path, body=None):
    key = os.environ.get("PIXELENGINE_API_KEY")
    if not key:
        sys.exit("Thiếu PIXELENGINE_API_KEY: điền key (pe_sk_...) vào %s" % os.path.join(ROOT, ".env"))
    req = urllib.request.Request(
        BASE + path, method=method,
        data=None if body is None else json.dumps(body).encode(),
        headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
    try:
        return json.load(urllib.request.urlopen(req, timeout=120))
    except urllib.error.HTTPError as e:
        sys.exit("Lỗi %d: %s" % (e.code, e.read().decode(errors="replace")))


def data_url(path):
    mime = "image/jpeg" if path.lower().endswith((".jpg", ".jpeg")) else "image/png"
    with open(path, "rb") as f:
        return "data:%s;base64,%s" % (mime, base64.b64encode(f.read()).decode())


def run(path, body, name, out_dir):
    """Gửi job, chờ xong, tải kết quả về out_dir/<name>_<id>.<đuôi> kèm .json. Trả đường dẫn file."""
    job_id = call("POST", path, body)["api_job_id"]
    print("Đã gửi job", job_id)
    started = time.time()
    while True:
        time.sleep(4)
        job = call("GET", "/jobs?id=" + job_id)
        print("  %s %d%%" % (job["status"], round((job.get("progress") or 0) * 100)))
        if job["status"] not in ("queued", "pending"):
            break
    if job["status"] != "success":
        sys.exit("Job %s: %s" % (job["status"], job.get("error")))
    return save(job, body, name, out_dir, started)


def save(job, body, name, out_dir, started):
    out = job["output"]
    job_id = job["api_job_id"]
    os.makedirs(out_dir, exist_ok=True)
    stem = os.path.join(out_dir, "%s_%s" % (name, job_id[:8]))
    with open(stem + EXT.get(out["content_type"], ".bin"), "wb") as f:
        f.write(urllib.request.urlopen(out["url"], timeout=120).read())
    credits = job["billing"]["credits_charged"]
    info = {k: v for k, v in body.items() if k not in ("image", "jobs", "frames")}
    info.update(job=job_id, credits=credits, seconds=round(time.time() - started), **out["metadata"])
    with open(stem + ".json", "w", encoding="utf-8") as f:
        json.dump(info, f, ensure_ascii=False, indent=2)
    print("Đã lưu %s%s · %s credit · %s giây · %s" % (
        stem, EXT.get(out["content_type"], ".bin"), credits, info["seconds"], out["metadata"]))
    return stem


def balance(_):
    b = call("GET", "/balance")
    print("Còn dùng được: %(available)s credit (tháng %(monthly_balance)s + mua %(purchased_balance)s,"
          " đang giữ %(reserved)s)" % b)


def billing(_):
    t = call("GET", "/billing")["totals"]
    print("30 ngày qua: dùng %(credits_used)s credit cho %(jobs_charged)s job, hoàn %(refunds)s" % t)


def image(args):
    body = {"prompt": args.prompt, "model": args.model, "pixel_config": {"colors": args.colors}}
    if args.ref:
        body["image"] = data_url(args.ref)
    run("/generate-image", body, args.name, args.out)


def anim_body(image, prompt, frames, matte):
    return {"image": image, "prompt": prompt, "model": "pixel-engine-v1.1", "output_frames": frames,
            "output_format": "spritesheet", "matte_color": matte}


def animate(args):
    body = anim_body(data_url(args.image), args.prompt, args.frames, args.matte)
    run("/animate", body, os.path.splitext(os.path.basename(args.image))[0], args.out)


def batch(args):
    """Nhiều animation cho cùng một ảnh trong một lần gọi: 20 credit + 12 cho mỗi animation thêm."""
    image = data_url(args.image)
    specs = []
    for spec in args.anims:  # tên=số_frame:mô tả
        name, rest = spec.split("=", 1)
        frames, prompt = rest.split(":", 1)
        specs.append((name, anim_body(image, prompt.strip(), int(frames), args.matte)))
    res = call("POST", "/animate-batch", {"jobs": [body for _, body in specs]})
    print("Đã gửi batch", res["batch_id"])
    started = time.time()
    while True:
        time.sleep(4)
        b = call("GET", "/batch-jobs?batch_id=" + res["batch_id"])
        print("  %s" % b["summary"])
        if b["summary"]["queued"] + b["summary"]["pending"] == 0:
            break
    stem = os.path.splitext(os.path.basename(args.image))[0]
    for sub in sorted(b["sub_jobs"], key=lambda s: s["batch_position"]):
        name, body = specs[sub["batch_position"]]
        if sub["status"] == "success":
            save(sub, body, "%s_%s" % (stem, name), args.out, started)
        else:
            print("  %s: %s %s" % (name, sub["status"], sub.get("error")))


def clear_matte(fr, matte, palette):
    """Xoá nền matte: tô loang từ 4 góc, rồi xoá nốt pixel ảnh gốc không có mà gần màu matte (khoảng nền kẹt
    giữa tay và thân) hoặc cùng sắc với matte (pixel pha giữa nền hồng và nhân vật)."""
    from PIL import ImageDraw
    w, h = fr.size
    for xy in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        if fr.getpixel(xy)[3]:
            ImageDraw.floodfill(fr, xy, (0, 0, 0, 0), thresh=40)
    mh, ms, _ = colorsys.rgb_to_hsv(*[v / 255.0 for v in matte])
    px = fr.load()
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if not c[3] or c[:3] in palette:
                continue
            ch, cs, _ = colorsys.rgb_to_hsv(*[v / 255.0 for v in c[:3]])
            if sum(abs(a - b) for a, b in zip(c, matte)) <= 24 or (ms > 0.4 and cs > 0.4 and abs(ch - mh) < 0.07):
                px[x, y] = (0, 0, 0, 0)
    return fr


def head_parts(base):
    """Tách sừng / mào trên đỉnh mũ của ảnh gốc: các hàng phía trên đỉnh mũ, tức 3 hàng liên tiếp đầu tiên rộng
    >= 70% bề ngang đầu (thanh ngang của sừng Kabuto Hyper rộng nhưng chỉ dày 1–2 hàng).
    Trả (pixel sừng, pixel mẫu đầu 10 hàng ngay dưới), mỗi pixel là (x, y, màu)."""
    px = base.load()
    box = base.getbbox()
    widths = [sum(1 for x in range(base.width) if px[x, y][3]) for y in range(box[1], box[1] + 24)]
    wide = [w >= 0.7 * max(widths) for w in widths]
    top = box[1] + next(i for i in range(len(wide) - 2) if wide[i] and wide[i + 1] and wide[i + 2])
    pick = lambda y0, y1: [(x, y, px[x, y]) for y in range(y0, y1) for x in range(base.width) if px[x, y][3]]
    return pick(box[1], top), pick(top, top + 10)


def head_offset(fr, head):
    """Độ lệch (dx, dy) của đầu trong frame so với ảnh gốc, tìm bằng mẫu đầu của head_parts. None khi không chắc
    (đầu ngửa khi trúng đòn): phải khớp từ một nửa mẫu và hơn hẳn vị trí kế tiếp."""
    px = fr.load()
    w, h = fr.size
    scores = []
    for dy in range(-10, 11):
        for dx in range(-14, 15):
            score = 0
            for x, y, c in head:
                if 0 <= x + dx < w and 0 <= y + dy < h:
                    p = px[x + dx, y + dy]
                    if p[3] and abs(p[0] - c[0]) + abs(p[1] - c[1]) + abs(p[2] - c[2]) < 40:
                        score += 1
            scores.append((score, dx, dy))
    scores.sort(reverse=True)
    best, dx, dy = scores[0]
    if best < 0.5 * len(head) or best < 1.2 * scores[1][0]:
        return None
    return dx, dy


def restore_crest(fr, crest, head, min_ratio=0.4):
    """AI hay vẽ thiếu sừng ở frame đánh: tìm đầu trong frame bằng mẫu đầu của ảnh gốc, chỗ sừng trống quá nửa thì
    vẽ lại sừng vào các ô trống. Bỏ qua frame không tìm thấy đầu (đầu ngửa khi trúng đòn). Trả True nếu đã vá."""
    if not crest:
        return False
    px = fr.load()
    w, h = fr.size
    at = lambda x, y: px[x, y] if 0 <= x < w and 0 <= y < h else (0, 0, 0, 0)
    off = head_offset(fr, head)
    if off is None:
        return False
    dx, dy = off
    # Sừng AI vẽ có thể lệch, nhỏ hơn hoặc nghiêng theo đầu: coi như còn sừng nếu vùng phía trên đỉnh đầu (rộng thêm
    # 4 px quanh chỗ sừng của ảnh gốc) có từ min_ratio số pixel sừng. Frame mất sừng thật chỉ còn 0–9 pixel; sừng to
    # như Kabuto Hyper mất một nửa đã lộ rõ, nên dùng ngưỡng cao hơn (--crest-min).
    x0 = min(x for x, _, _ in crest) + dx - 4
    x1 = max(x for x, _, _ in crest) + dx + 4
    y0 = min(y for _, y, _ in crest) + dy - 4
    y1 = min(y for _, y, _ in head) + dy
    if sum(1 for y in range(y0, y1) for x in range(x0, x1 + 1) if at(x, y)[3]) >= min_ratio * len(crest):
        return False
    # Hạ sừng xuống tới khi chân sừng chạm mũ (đầu trong frame đánh hay thấp hơn mẫu 1–3 px).
    cells = {(x, y) for x, y, _ in crest}
    for _ in range(4):
        if any(at(x + dx, y + dy + 1)[3] for x, y in cells if (x, y + 1) not in cells):
            break
        dy += 1
    for x, y, c in crest:
        if 0 <= x + dx < w and 0 <= y + dy < h and not px[x + dx, y + dy][3]:
            px[x + dx, y + dy] = c
    return True


def fit(args):
    """Ảnh của lệnh image (nền trắng, ~92 px) → <tên>_<cell>.png: nền trong, nhân vật cao --height px, chân ở hàng
    cell-7 như sprite PixelLab. Thu nhỏ kiểu nearest để giữ viền sắc."""
    from PIL import Image, ImageDraw
    im = Image.open(args.image).convert("RGBA")
    w, h = im.size
    for xy in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        if im.getpixel(xy)[3]:
            ImageDraw.floodfill(im, xy, (0, 0, 0, 0), thresh=24)
    fig = im.crop(im.getbbox())
    size = (max(1, round(fig.width * args.height / fig.height)), args.height)
    out = Image.new("RGBA", (args.cell, args.cell), (0, 0, 0, 0))
    out.alpha_composite(fig.resize(size, Image.NEAREST), ((args.cell - size[0]) // 2, args.cell - 7 - size[1]))
    path = "%s_%d.png" % (args.name or os.path.splitext(args.image)[0], args.cell)
    out.save(path)
    print("Đã lưu %s (nhân vật %d×%d từ %d×%d)" % (path, size[0], size[1], fig.width, fig.height))


def pack(args):
    """Xếp ảnh gốc và các spritesheet thành art/pixelengine/<tên>/ cùng cấu trúc thư mục PixelLab (metadata.json,
    hướng east) để tools/import_pixellab.py đọc như nhân vật PixelLab. Xoá nền matte, vá sừng AI vẽ thiếu."""
    from PIL import Image
    base = Image.open(args.base).convert("RGBA")
    palette = {c[:3] for c in base.getdata() if c[3]}
    crest, head = head_parts(base)
    target = os.path.join(OUT_DIR, args.name)
    os.makedirs(os.path.join(target, "rotations"), exist_ok=True)
    base.save(os.path.join(target, "rotations", "east.png"))
    anims = {}
    for spec in args.anims:  # tên=spritesheet.png (file .json cùng tên do lệnh animate/batch ghi)
        name, sheet_path = spec.split("=", 1)
        meta = json.load(open(os.path.splitext(sheet_path)[0] + ".json", encoding="utf-8"))
        matte = meta.get("matte_color", "#808080").lstrip("#")
        matte = tuple(int(matte[i:i + 2], 16) for i in (0, 2, 4))
        sheet = Image.open(sheet_path).convert("RGBA")
        os.makedirs(os.path.join(target, "animations", name, "east"), exist_ok=True)
        anims[name] = {"east": []}
        fw, fh = meta["frame_w"], meta["frame_h"]
        patched = []
        for i in range(meta["frame_count"]):
            rel = "animations/%s/east/frame_%03d.png" % (name, i)
            fr = clear_matte(sheet.crop((fw * i, 0, fw * (i + 1), fh)), matte, palette)
            if restore_crest(fr, crest, head, args.crest_min):
                patched.append(i + 1)
            fr.save(os.path.join(target, rel))
            anims[name]["east"].append(rel)
        print("  %s: %d frame%s" % (name, meta["frame_count"], " · vá sừng frame %s" % patched if patched else ""))
    states = [{"frames": {"rotations": {"east": "rotations/east.png"}, "animations": anims}}]
    with open(os.path.join(target, "metadata.json"), "w", encoding="utf-8") as f:
        json.dump({"source": "pixelengine", "states": states}, f, indent=2)
    print("Đã xếp", target)


def nobg(args):
    run("/remove-background", {"image": data_url(args.image)},
        os.path.splitext(os.path.basename(args.image))[0] + "_nobg", args.out)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("balance").set_defaults(fn=balance)
    sub.add_parser("billing").set_defaults(fn=billing)
    a = sub.add_parser("image")
    a.add_argument("prompt")
    a.add_argument("--name", default="image")
    a.add_argument("--ref")
    a.add_argument("--model", default="nb_flash")
    a.add_argument("--colors", type=int, default=32)
    a.set_defaults(fn=image)
    a = sub.add_parser("animate")
    a.add_argument("image")
    a.add_argument("prompt")
    a.add_argument("--frames", type=int, default=8)
    a.add_argument("--matte", default="#FF00FF")
    a.set_defaults(fn=animate)
    a = sub.add_parser("batch")
    a.add_argument("image")
    a.add_argument("anims", nargs="+", metavar="TÊN=FRAME:MÔ_TẢ")
    a.add_argument("--matte", default="#FF00FF")
    a.set_defaults(fn=batch)
    a = sub.add_parser("nobg")
    a.add_argument("image")
    a.set_defaults(fn=nobg)
    a = sub.add_parser("fit")
    a.add_argument("image")
    a.add_argument("--name", help="đường dẫn không đuôi cho file ra (mặc định: cạnh ảnh gốc)")
    a.add_argument("--height", type=int, default=54)
    a.add_argument("--cell", type=int, default=68)
    a.set_defaults(fn=fit)
    a = sub.add_parser("pack")
    a.add_argument("name")
    a.add_argument("base")
    a.add_argument("anims", nargs="+", metavar="TÊN=SPRITESHEET.png")
    a.add_argument("--crest-min", type=float, default=0.4, help="còn ít hơn tỉ lệ này số pixel sừng thì vá sừng")
    a.set_defaults(fn=pack)
    for a in sub.choices.values():
        a.add_argument("--out", default=OUT_DIR)
    args = p.parse_args()
    load_env()
    args.fn(args)


if __name__ == "__main__":
    main()
