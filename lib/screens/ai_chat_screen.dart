import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chat_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  static const green = Color(0xFF167A45);

  final input = TextEditingController();
  final scroll = ScrollController();

  final messages = <Map<String, dynamic>>[];
  bool sending = false;
  XFile? selectedImage;
  final imagePicker = ImagePicker();

  String? error;

  final suggestions = [
    'Lúa 20 ngày tuổi chăm sóc thế nào?',
    'Dấu hiệu lúa thiếu dinh dưỡng?',
    'Thời tiết này có nên tưới ruộng?',
    'Cách kiểm tra sâu bệnh trên lúa?',
  ];

  @override
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
    }).join('\n');
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }


  Future<void> pickImage(ImageSource source) async {
    try {
      final file = await imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (file != null && mounted) {
        setState(() => selectedImage = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không chọn được ảnh: $e')),
        );
      }
    }
  }

  Future<void> sendImage() async {
    final file = selectedImage;
    if (file == null || sending) return;

    final question = input.text.trim().isEmpty
        ? 'Hãy phân tích ảnh cây lúa này.'
        : input.text.trim();

    setState(() {
      sending = true;
      error = null;
      messages.add({
        'role': 'user',
        'text': '[Ảnh cây lúa] $question',
      });
    });

    input.clear();
    selectedImage = null;
    await saveHistory();
    scrollToBottom();

    try {
      final bytes = await file.readAsBytes();
      final path = file.path.toLowerCase();
      final mime = path.endsWith('.png')
          ? 'image/png'
          : path.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';

      final data = await ApiService.diagnose(
        imageBase64: base64Encode(bytes),
        mimeType: mime,
        context: question,
      );

      final answer = data['result']?.toString() ??
          data['description']?.toString() ??
          'AI chưa trả về kết quả.';

      if (!mounted) return;
      setState(() {
        messages.add({'role': 'ai', 'text': answer});
      });
      await saveHistory();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) {
        setState(() => sending = false);
        scrollToBottom();
      }
    }
  }

  Future<void> send([String? text]) async {
    final question = (text ?? input.text).trim();
    if (question.isEmpty || sending) return;

    final context = conversationContext;
    input.clear();

    setState(() {
      error = null;
      sending = true;
      messages.add({'role': 'user', 'text': question});
    });

    await saveHistory();
    scrollToBottom();

    try {
      final answer = await ChatService.sendMessage(question, context: context);
      if (!mounted) return;

      setState(() {
        messages.add({'role': 'ai', 'text': answer});
      });
      await saveHistory();
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) {
        setState(() => sending = false);
        scrollToBottom();
      }
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget bubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? green : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isUser ? null : Border.all(color: const Color(0xFFE3ECE4)),
        ),
        child: SelectableText(
          message['text'] as String,
          style: TextStyle(
            height: 1.5,
            color: isUser ? Colors.white : const Color(0xFF26382A),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F4),
      appBar: AppBar(
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

        title: const Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFE0F2E4),
              child: Icon(Icons.eco_rounded, color: green, size: 20),
            ),
            SizedBox(width: 10),
            Text('Nông Nghiệp Xanh AI'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const SizedBox(height: 25),
                      const Icon(Icons.auto_awesome, size: 58, color: green),
                      const SizedBox(height: 14),
                      const Text(
                        'Xin chào nhà nông!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mình có thể hỗ trợ bạn về lúa, thời tiết, '
                        'chăm sóc cây trồng và mùa vụ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(height: 1.5, color: Colors.black54),
                      ),
                      const SizedBox(height: 25),
                      ...suggestions.map((question) => Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.chat_bubble_outline, color: green),
                              title: Text(question),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              onTap: sending ? null : () => send(question),
                            ),
                          )),
                    ],
                  )
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(14),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 10),
                                  Text('AI đang suy nghĩ...'),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return bubble(messages[index]);
                    },
                  ),
          ),
          if (error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: sending
                        ? null
                        : () => selectedImage != null ? sendImage() : send(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          if (selectedImage != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Icon(Icons.image, color: green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(selectedImage!.name)),
                  IconButton(
                    onPressed: () => setState(() => selectedImage = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Chọn ảnh',
                    onPressed: sending
                        ? null
                        : () => pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                  IconButton(
                    tooltip: 'Chụp ảnh',
                    onPressed: sending
                        ? null
                        : () => pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                      decoration: InputDecoration(
                        hintText: 'Hỏi AI về nông nghiệp...',
                        filled: true,
                        fillColor: const Color(0xFFF4F7F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: sending ? null : () => send(),
                    style: IconButton.styleFrom(backgroundColor: green),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
