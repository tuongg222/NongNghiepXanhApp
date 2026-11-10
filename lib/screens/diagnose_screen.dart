
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({super.key});

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  final picker = ImagePicker();

  File? image;
  bool busy = false;
  String? result;
  String? error;

  Future<void> chooseImage(ImageSource source) async {
    try {
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (picked != null && mounted) {
        setState(() {
          image = File(picked.path);
          result = null;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Không thể chọn ảnh: $e');
    }
  }

  Future<void> analyze() async {
    if (image == null || busy) return;

    setState(() {
      busy = true;
      error = null;
      result = null;
    });

    try {
      final bytes = await image!.readAsBytes();
      final path = image!.path.toLowerCase();

      final mime = path.endsWith('.png')
          ? 'image/png'
          : path.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';

      final response = await ApiService.diagnose(
        imageBase64: base64Encode(bytes),
        mimeType: mime,
      );

      if (mounted) {
        setState(() {
          result = const JsonEncoder.withIndent('  ').convert(response);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Phân tích thất bại.\n'
              'Kiểm tra Internet hoặc máy chủ AI.\n\n$e';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget actionButton({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    bool primary = false,
  }) {
    return Expanded(
      child: primary
          ? FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(title),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF167A45),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(title),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF167A45);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI nhận diện cây trồng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE5F5E9), Color(0xFFF4FAF5)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              children: [
                Icon(Icons.eco_rounded, size: 55, color: green),
                SizedBox(height: 12),
                Text(
                  'Trợ lý chẩn đoán cây trồng',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Chụp hoặc tải ảnh cây để AI phân tích dấu hiệu bệnh.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              actionButton(
                icon: Icons.camera_alt_rounded,
                title: 'Chụp ảnh',
                onTap: busy ? null : () => chooseImage(ImageSource.camera),
              ),
              const SizedBox(width: 10),
              actionButton(
                icon: Icons.photo_library_rounded,
                title: 'Thư viện',
                onTap: busy ? null : () => chooseImage(ImageSource.gallery),
              ),
            ],
          ),

          if (image != null) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                image!,
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => chooseImage(ImageSource.gallery),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Đổi ảnh'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : analyze,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Phân tích AI'),
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (busy) ...[
            const SizedBox(height: 25),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: green),
                  SizedBox(height: 14),
                  Text(
                    'AI đang phân tích ảnh...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6),
                  Text('Vui lòng chờ trong giây lát'),
                ],
              ),
            ),
          ],

          if (error != null) ...[
            const SizedBox(height: 18),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableText(
                        error!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (result != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCEBDD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.biotech_rounded, color: green, size: 26),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kết quả phân tích',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 25),
                  SelectableText(
                    result!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Lưu ý: Kết quả AI chỉ mang tính tham khảo. '
              'Hãy kiểm tra thực tế hoặc hỏi cán bộ nông nghiệp '
              'trước khi sử dụng thuốc.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
