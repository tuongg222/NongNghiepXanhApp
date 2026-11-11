from pathlib import Path
import re

ROOT = Path(".")
errors = []
checked = 0

def check_file(path):
    global checked
    p = ROOT / path

    if not p.exists():
        errors.append(f"FILE MISSING: {path}")
        return ""

    checked += 1
    return p.read_text(encoding="utf-8")

print("=" * 50)
print(" NONG NGHIEP XANH - PROJECT CHECK")
print("=" * 50)

# Kiểm tra file chính
main = check_file("lib/main.dart")
api = check_file("lib/services/api_service.dart")
chat = check_file("lib/screens/chat_ai_screen.dart")
nav = check_file("lib/screens/main_navigation.dart")
worker = check_file("worker.js")

# Kiểm tra import Dart
for path in (ROOT / "lib").rglob("*.dart"):
    content = path.read_text(encoding="utf-8")

    for imp in re.findall(r"import\s+'([^']+)'", content):
        if imp.startswith(("package:", "dart:")):
            continue

        target = (path.parent / imp).resolve()

        if not target.exists():
            errors.append(
                f"IMPORT MISSING: {path} -> {imp}"
            )

# Kiểm tra API Chat
if "static Future<Map<String, dynamic>> chat(" in api:
    print("[OK] ApiService.chat")
else:
    errors.append("API CHAT MISSING")

# Kiểm tra Worker Chat
if '"/chat"' in worker or "'/chat'" in worker:
    print("[OK] Worker chat route")
else:
    errors.append("WORKER CHAT ROUTE MISSING")

if "env.AI.run" in worker:
    print("[OK] Cloudflare AI")
else:
    errors.append("WORKER AI NOT FOUND")

# Kiểm tra Navigation
if "ChatAiScreen" in nav:
    print("[OK] Chat AI navigation")
else:
    errors.append("CHAT AI NOT CONNECTED")

print()
print("Files checked:", checked)

if errors:
    print("\nERRORS:")
    for e in errors:
        print(" -", e)
else:
    print("\n[OK] Khong phat hien loi file/import co ban.")

print("\nLuu y: Python khong thay the Flutter analyze.")
print("=" * 50)
