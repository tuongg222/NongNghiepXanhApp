from pathlib import Path

p = Path("lib/screens/ai_chat_screen.dart")
s = p.read_text(encoding="utf-8")

if "FarmProfileScreen" not in s:
    s = s.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\n"
        "import 'farm_profile_screen.dart';"
    )

marker = "appBar: AppBar(\n        actions: ["
replacement = """appBar: AppBar(
        title: const Text('AI Nông nghiệp'),
        actions: [
          IconButton(
            tooltip: 'Hồ sơ ruộng',
            icon: const Icon(Icons.agriculture),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FarmProfileScreen(),
                ),
              );
            },
          ),"""

if "tooltip: 'Hồ sơ ruộng'" not in s:
    if marker not in s:
        raise SystemExit("Không tìm thấy AppBar actions")
    s = s.replace(marker, replacement, 1)

p.write_text(s, encoding="utf-8")
print("✅ Đã thêm nút Hồ sơ ruộng vào AI Chat")
