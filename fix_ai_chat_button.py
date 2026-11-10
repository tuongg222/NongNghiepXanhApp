from pathlib import Path
import shutil

p = Path("lib/screens/care_ai_screen.dart")
s = p.read_text()

if "ai_chat_screen.dart" not in s:
    s = s.replace(
        "import '../services/weather_service.dart';",
        "import '../services/weather_service.dart';\nimport 'ai_chat_screen.dart';"
    )

if "AIChatScreen()" not in s:
    marker = "      appBar: AppBar("
    if marker not in s:
        print("Khong tim thay AppBar")
        raise SystemExit(1)

    button = """      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Trò chuyện với AI',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AIChatScreen(),
                ),
              );
            },
          ),
"""
    s = s.replace(marker, button, 1)

backup = Path("lib/screens/care_ai_screen.dart.before_chat_backup")
if not backup.exists():
    shutil.copy2(p, backup)

p.write_text(s)
print("DA THEM NUT CHAT AI VAO APPBAR!")
