from pathlib import Path
import shutil

p = Path("lib/screens/ai_chat_screen.dart")
s = p.read_text()

backup = Path("lib/screens/ai_chat_screen.dart.before_image_backup")
if not backup.exists():
    shutil.copy2(p, backup)

# Imports
imports = [
    "import 'dart:convert';",
    "import 'dart:io';",
    "import 'package:image_picker/image_picker.dart';",
    "import '../services/api_service.dart';",
]

for imp in imports:
    if imp not in s:
        s = imp + "\n" + s

# State
if "XFile? selectedImage;" not in s:
    marker = "  bool sending = false;"
    if marker not in s:
        raise SystemExit("LOI: Khong tim thay state sending")

    s = s.replace(marker, marker + """
  XFile? selectedImage;
  final imagePicker = ImagePicker();
""", 1)

# Image selection + diagnosis
if "Future<void> pickImage" not in s:
    marker = "  Future<void> send([String? text]) async {"
    if marker not in s:
        raise SystemExit("LOI: Khong tim thay ham send")

    method = r'''
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

'''
    s = s.replace(marker, method + marker, 1)

# Add image preview above input
if "selectedImage != null" not in s:
    marker = "          Container(\n            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),"
    if marker not in s:
        raise SystemExit("LOI: Khong tim thay khung nhap chat")

    preview = """          if (selectedImage != null)
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
"""
    s = s.replace(marker, preview + marker, 1)

# Add image picker buttons beside text input
if "pickImage(ImageSource.gallery)" not in s:
    marker = "                  Expanded(\n                    child: TextField("
    if marker not in s:
        raise SystemExit("LOI: Khong tim thay TextField")

    buttons = """                  IconButton(
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
"""
    s = s.replace(marker, buttons + marker, 1)

# Send button: send image when selected
old = "onPressed: sending ? null : () => send(),"
new = """onPressed: sending
                        ? null
                        : () => selectedImage != null ? sendImage() : send(),"""
if old in s:
    s = s.replace(old, new, 1)

p.write_text(s)
print("DA THEM CHON ANH, CAMERA VA PHAN TICH ANH AI!")
