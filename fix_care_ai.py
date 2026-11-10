from pathlib import Path

p = Path("lib/screens/care_ai_screen.dart")
s = p.read_text()

start = s.index("    appBar: AppBar(")
end = s.index("      body:", start)

new_appbar = """    appBar: AppBar(
      title: const Text('AI chăm sóc cây trồng'),
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
        IconButton(
          onPressed: loading ? null : loadWeather,
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại thời tiết',
        ),
      ],
    ),
"""

s = s[:start] + new_appbar + s[end:]

old = """                if (error != null)
                  Card(color: Colors.red.shade50,
                    child: Padding(padding: const EdgeInsets.all(12),
                      child: Text('Không tải được thời tiết: $error')),
"""

new = """                if (error != null)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Không tải được thời tiết: $error'),
                    ),
                  ),
"""

if old not in s:
    print("KHONG TIM THAY CARD LOI - can kiem tra thu cong")
else:
    s = s.replace(old, new, 1)

p.write_text(s)
print("Da sua AppBar va Card loi CareAI")
