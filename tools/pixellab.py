#!/usr/bin/env python3
"""
Gọi PixelLab (https://api.pixellab.ai/mcp) thẳng từ dòng lệnh, không cần MCP của Claude.

    # điền PIXELLAB_API_KEY=... vào .env ở thư mục dự án (mẫu: .env.example)
    python3 tools/pixellab.py balance                          # số lượt tạo còn lại
    python3 tools/pixellab.py jobs                             # job đang chạy
    python3 tools/pixellab.py call <tool> '<json đối số>'      # gọi một tool bất kỳ, vd. animate_image
    python3 tools/pixellab.py download <job_id> <file.png> [index]   # chờ job xong rồi tải ảnh

Trong JSON đối số, chuỗi "@đường/dẫn.png" được thay bằng base64 của file (gửi ảnh gốc).
Key lấy theo thứ tự: biến môi trường PIXELLAB_API_KEY → .env → header pixellab trong ~/.claude.json.
Gói dùng thử chỉ chạy 1 job một lúc; ảnh trên máy chủ hết hạn sau khoảng 1 ngày nên tải về ngay.
"""
import base64
import json
import os
import sys
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
URL = "https://api.pixellab.ai/mcp"


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


def auth_header():
    load_env()
    key = os.environ.get("PIXELLAB_API_KEY", "").strip()
    if key and not key.endswith("..."):
        return key if key.lower().startswith("bearer ") else "Bearer " + key
    try:   # chưa điền .env: dùng key đang cấu hình cho MCP
        cfg = json.load(open(os.path.expanduser("~/.claude.json"), encoding="utf-8"))
        return cfg["mcpServers"]["pixellab"]["headers"]["Authorization"]
    except (OSError, KeyError, ValueError):
        sys.exit("Thiếu PIXELLAB_API_KEY: điền key vào %s" % os.path.join(ROOT, ".env"))


def call(tool, args):
    """Gọi tool PixelLab, trả về phần chữ của kết quả."""
    for k, v in list(args.items()):
        if isinstance(v, str) and v.startswith("@"):
            args[k] = base64.b64encode(open(v[1:], "rb").read()).decode()
    body = {"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": tool, "arguments": args}}
    req = urllib.request.Request(URL, data=json.dumps(body).encode(), headers={
        "Authorization": auth_header(), "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream"})
    raw = urllib.request.urlopen(req, timeout=120).read().decode()
    out = []
    for line in raw.splitlines():
        if not line.startswith("data:"):
            continue
        msg = json.loads(line[5:])
        if "error" in msg:
            out.append("LỖI %s" % msg["error"])
        for c in (msg.get("result") or {}).get("content", []):
            if c.get("type") == "text":
                out.append(c["text"])
    return "\n".join(out)


def download(job, path, index=None, tries=120):
    """Chờ job xong (ảnh tải được) rồi lưu. index: frame thứ mấy của animation (0 = ảnh đầu vào)."""
    url = "%s/images/%s/download%s" % (URL, job, "" if index is None else "?index=%d" % index)
    for _ in range(tries):
        try:
            data = urllib.request.urlopen(url, timeout=60).read()
            open(path, "wb").write(data)
            return True
        except Exception:
            time.sleep(5)
    return False


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd = sys.argv[1]
    if cmd == "balance":
        print(call("get_balance", {}))
    elif cmd == "jobs":
        print(call("list_jobs", {"include_recent": True}))
    elif cmd == "call":
        print(call(sys.argv[2], json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}))
    elif cmd == "download":
        index = int(sys.argv[4]) if len(sys.argv) > 4 else None
        ok = download(sys.argv[2], sys.argv[3], index)
        print("đã lưu %s" % sys.argv[3] if ok else "hết giờ chờ job %s" % sys.argv[2])
        sys.exit(0 if ok else 1)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
