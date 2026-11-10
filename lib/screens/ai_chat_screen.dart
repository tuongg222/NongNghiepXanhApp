import 'package:flutter/material.dart';
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
  String? error;

  final suggestions = [
    'Lúa 20 ngày tuổi chăm sóc thế nào?',
    'Dấu hiệu lúa thiếu dinh dưỡng?',
    'Thời tiết này có nên tưới ruộng?',
    'Cách kiểm tra sâu bệnh trên lúa?',
  ];

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? text]) async {
    final question = (text ?? input.text).trim();
    if (question.isEmpty || sending) return;

    input.clear();

    setState(() {
      error = null;
      sending = true;
      messages.add({'role': 'user', 'text': question});
    });

    scrollToBottom();

    try {
      final answer = await ChatService.sendMessage(question);
      if (!mounted) return;

      setState(() {
        messages.add({'role': 'ai', 'text': answer});
      });
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
                    onPressed: sending ? null : () => send(),
                    child: const Text('Thử lại'),
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
