#!/usr/bin/env python3
"""
Gọi Sprite Fusion từ dòng lệnh — cùng API mà plugin Godot chính thức dùng
(https://github.com/Hugo-Dz/spritefusion-godot, MIT).

    python3 tools/spritefusion.py connect                        # in link để duyệt trên trình duyệt, chờ tới khi xong
    python3 tools/spritefusion.py status
    python3 tools/spritefusion.py generate "prompt" [--size 64] [--out DIR]
    python3 tools/spritefusion.py animate SOURCE.png "idle animation" [--frames 8] [--colors 24] [--out DIR]

Phiên đăng nhập lưu ở ~/.config/spritefusion/session.json (ngoài repo, quyền 600).
Ảnh tải về mặc định vào art/spritefusion/. Cần gói đăng ký Sprite Fusion còn hiệu lực.
"""
import argparse
import base64
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

API = "https://www.spritefusion.com"
SESSION_FILE = Path.home() / ".config" / "spritefusion" / "session.json"
ROOT = Path(__file__).resolve().parent.parent
DEFAULT_OUT = ROOT / "art" / "spritefusion"
UA = "GodotEngine/4.4 (spritefusion-cli)"  # urllib's default UA gets 403 from the asset CDN


def post(path, payload, token=None, timeout=30):
    headers = {"Content-Type": "application/json", "Accept": "application/json", "User-Agent": UA}
    if token:
        headers["Accept"] = "text/event-stream"
        headers["Authorization"] = "Bearer " + token
    req = urllib.request.Request(API + path, json.dumps(payload).encode(), headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


def parse_json(text):
    try:
        data = json.loads(text)
        return data if isinstance(data, dict) else {}
    except ValueError:
        return {}


def parse_events(text):
    events = []
    for raw in text.replace("\r\n", "\n").split("\n\n"):
        lines = [l[5:].strip() for l in raw.split("\n") if l.startswith("data:")]
        if lines:
            ev = parse_json("\n".join(lines))
            if ev:
                events.append(ev)
    return events


def load_session():
    if not SESSION_FILE.exists():
        sys.exit("Chưa kết nối. Chạy: python3 tools/spritefusion.py connect")
    return json.loads(SESSION_FILE.read_text())


def save_session(data, old_email=""):
    user = data.get("user") if isinstance(data.get("user"), dict) else {}
    session = {
        "access_token": data.get("access_token", ""),
        "refresh_token": data.get("refresh_token", ""),
        "expires_at": int(data.get("expires_at", 0)),
        "email": user.get("email", old_email),
    }
    SESSION_FILE.parent.mkdir(parents=True, exist_ok=True)
    SESSION_FILE.write_text(json.dumps(session, indent=2))
    os.chmod(SESSION_FILE, 0o600)
    return session


def refresh(session):
    code, body = post("/api/integrations/auth/refresh", {"refresh_token": session["refresh_token"]})
    if code >= 300:
        sys.exit(f"Làm mới phiên thất bại ({code}). Chạy lại: connect")
    return save_session(parse_json(body), session.get("email", ""))


def fresh_session():
    session = load_session()
    if session.get("expires_at", 0) <= time.time() + 60:
        session = refresh(session)
    return session


def cmd_connect(_args):
    code, body = post("/api/integrations/auth/device/start?integration=godot", {})
    data = parse_json(body)
    if code >= 300 or not data.get("deviceCode"):
        sys.exit(f"Không tạo được mã kết nối ({code}): {body[:200]}")
    print(f"Mở link này và duyệt mã {data.get('userCode', '')}:")
    print("  " + data.get("verificationUriComplete", ""), flush=True)
    interval = int(data.get("interval", 5))
    while True:
        time.sleep(interval)
        code, body = post("/api/integrations/auth/device/token", {"deviceCode": data["deviceCode"]})
        res = parse_json(body)
        if 200 <= code < 300:
            s = save_session(res)
            print(f"Đã kết nối: {s.get('email') or 'Sprite Fusion user'}")
            return
        err = res.get("error")
        if err == "slow_down":
            interval += 5
        elif err not in (None, "authorization_pending"):
            sys.exit(f"Kết nối thất bại: {err}")


def cmd_status(_args):
    s = load_session()
    left = int(s.get("expires_at", 0) - time.time())
    print(f"Tài khoản: {s.get('email') or '?'} — access token còn {max(left, 0)}s (tự làm mới khi hết)")


def run_generation(payload):
    session = fresh_session()
    code, body = post("/api/v1/generate", payload, session["access_token"], timeout=600)
    if code == 401:
        session = refresh(session)
        code, body = post("/api/v1/generate", payload, session["access_token"], timeout=600)
    if code >= 300:
        err = parse_json(body).get("error")
        msg = err.get("message") if isinstance(err, dict) else body[:300]
        sys.exit(f"Lỗi {code}: {msg}")
    events = parse_events(body)
    last = events[-1] if events else {}
    if last.get("type") != "completed" or last.get("status") != "succeeded":
        err = last.get("error")
        sys.exit(f"Tạo thất bại: {err.get('message') if isinstance(err, dict) else last}")
    assets = {}
    for ev in events:
        a = ev.get("asset")
        if ev.get("type") == "output" and isinstance(a, dict) and a.get("id"):
            assets[a["id"]] = a  # sự kiện sau ghi đè sự kiện trước cùng id
    return list(assets.values())


def download(url, path, token=None):
    headers = {"User-Agent": UA}
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=120) as r:
            path.write_bytes(r.read())
    except urllib.error.HTTPError as e:
        if e.code not in (401, 403) or not token:
            raise
        headers["Authorization"] = "Bearer " + token
        with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=120) as r:
            path.write_bytes(r.read())


def slug(text):
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")[:48] or "sprite"


def cmd_generate(args):
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    assets = [a for a in run_generation({"operation": "generate", "prompt": args.prompt, "size": args.size}) if a.get("assetUrl")]
    if not assets:
        sys.exit("Không có ảnh nào trả về.")
    stamp = time.strftime("%Y%m%d_%H%M%S")
    # keep the URLs so a failed download doesn't waste the paid generation
    (out / f"{slug(args.prompt)}_{stamp}.assets.json").write_text(json.dumps(assets, indent=2))
    for i, a in enumerate(assets):
        p = out / f"{slug(args.prompt)}_{stamp}_{i:02d}.png"
        download(a["assetUrl"], p, load_session()["access_token"])
        print(p.relative_to(ROOT) if p.is_relative_to(ROOT) else p)


def cmd_animate(args):
    src = Path(args.source)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    data_url = "data:image/png;base64," + base64.b64encode(src.read_bytes()).decode()
    payload = {"operation": "animate", "prompt": args.prompt, "inputs": [{"data_url": data_url}],
               "output_frames": args.frames, "colors": args.colors}
    assets = [a for a in run_generation(payload) if a.get("spritesheetUrl")]
    if not assets:
        sys.exit("Không có spritesheet nào trả về.")
    a = assets[-1]
    (out / f"{src.stem}__{slug(args.prompt)}.assets.json").write_text(json.dumps(assets, indent=2))
    p = out / f"{src.stem}__{slug(args.prompt)}_{time.strftime('%Y%m%d_%H%M%S')}.png"
    download(a["spritesheetUrl"], p, load_session()["access_token"])
    meta = {k: a.get(k) for k in ("width", "height", "frameCount", "fps")}
    p.with_suffix(".json").write_text(json.dumps(meta, indent=2))
    print(f"{p.relative_to(ROOT) if p.is_relative_to(ROOT) else p}  {meta}")


def main():
    ap = argparse.ArgumentParser(description="Sprite Fusion CLI")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("connect").set_defaults(fn=cmd_connect)
    sub.add_parser("status").set_defaults(fn=cmd_status)
    g = sub.add_parser("generate")
    g.add_argument("prompt")
    g.add_argument("--size", type=int, choices=[16, 32, 64], default=64)
    g.add_argument("--out", default=str(DEFAULT_OUT))
    g.set_defaults(fn=cmd_generate)
    a = sub.add_parser("animate")
    a.add_argument("source")
    a.add_argument("prompt")
    a.add_argument("--frames", type=int, default=8)
    a.add_argument("--colors", type=int, default=24)
    a.add_argument("--out", default=str(DEFAULT_OUT))
    a.set_defaults(fn=cmd_animate)
    args = ap.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
