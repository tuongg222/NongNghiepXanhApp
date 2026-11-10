from pathlib import Path

p = Path("lib/screens/ai_chat_screen.dart")
s = p.read_text()

old = "        title: const Text('AI Nông nghiệp'),"

if old not in s:
    print("Khong tim thay title cu!")
    raise SystemExit(1)

s = s.replace(old, "", 1)
p.write_text(s)

print("DA SUA: Xoa title trung, giu Nông Nghiệp Xanh AI")
