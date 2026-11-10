from pathlib import Path
import shutil

p = Path("lib/screens/ai_chat_screen.dart")
s = p.read_text()

backup = Path("lib/screens/ai_chat_screen.dart.before_memory_backup")
if not backup.exists():
    shutil.copy2(p, backup)

# SharedPreferences
if "shared_preferences.dart" not in s:
    s = s.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\n"
        "import 'package:shared_preferences/shared_preferences.dart';"
    )

# Restore history when opening screen
if "loadHistory()" not in s:
    s = s.replace(
        "  @override\n  void dispose() {",
        """  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('nx_ai_chat_history');
    if (raw == null || !mounted) return;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      setState(() {
        messages.addAll(decoded.map((e) =>
          Map<String, dynamic>.from(e as Map)));
      });
      scrollToBottom();
    } catch (_) {}
  }

  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nx_ai_chat_history', jsonEncode(messages));
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nx_ai_chat_history');
    if (!mounted) return;
    setState(() {
      messages.clear();
      error = null;
    });
  }

  String get conversationContext {
    final recent = messages.length > 12
        ? messages.sublist(messages.length - 12)
        : messages;
    return recent.map((m) {
      final role = m['role'] == 'user' ? 'Người trồng' : 'AI';
      return '$role: ${m['text']}';
    }).join('\\n');
  }

  @override
  void dispose() {"""
    )

# Build context before adding current question, send with request
if "final context = conversationContext;" not in s:
    s = s.replace(
        "    input.clear();\n\n    setState(() {",
        "    final context = conversationContext;\n    input.clear();\n\n    setState(() {"
    )

if "context: context" not in s:
    s = s.replace(
        "final answer = await ChatService.sendMessage(question);",
        "final answer = await ChatService.sendMessage(question, context: context);"
    )

# Persist user + AI messages
if "await saveHistory();" not in s:
    s = s.replace(
        "    scrollToBottom();\n\n    try {",
        "    await saveHistory();\n    scrollToBottom();\n\n    try {"
    )
    s = s.replace(
        "        messages.add({'role': 'ai', 'text': answer});",
        "        messages.add({'role': 'ai', 'text': answer});"
    )
    s = s.replace(
        "      });\n    } catch (e) {",
        "      });\n      await saveHistory();\n    } catch (e) {"
    )

# Clear history button in appbar
if "Xóa lịch sử chat" not in s:
    marker = "      appBar: AppBar("
    replacement = """      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Xóa lịch sử chat',
            icon: const Icon(Icons.delete_outline),
            onPressed: messages.isEmpty ? null : () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xóa hội thoại?'),
                  content: const Text('Lịch sử trò chuyện sẽ bị xóa khỏi thiết bị.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Hủy'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
              if (ok == true) await clearHistory();
            },
          ),
        ],
"""
    if marker not in s:
        print("LOI: Khong tim thay AppBar")
        raise SystemExit(1)
    s = s.replace(marker, replacement, 1)

p.write_text(s)
print("DA NANG CAP AI CHAT: LUU LICH SU + NGU CANH!")
