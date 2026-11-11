import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  String crop = 'Lúa';
  String stage = 'Sinh trưởng';
  String part = 'Lá';

  List<Map<String, dynamic>> history = [];

  final crops = ['Lúa', 'Rau', 'Cây ăn trái', 'Khác'];
  final stages = [
    'Mạ', 'Đẻ nhánh', 'Làm đòng', 'Trổ bông',
    'Chắc hạt', 'Sinh trưởng', 'Ra hoa', 'Nuôi trái', 'Thu hoạch'
  ];
  final parts = ['Lá', 'Thân', 'Rễ', 'Bông', 'Hạt', 'Quả', 'Toàn cây'];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString('nx_diagnosis_history');
      if (raw != null) {
        history = List<Map<String, dynamic>>.from(
          (jsonDecode(raw) as List).map(
            (e) => Map<String, dynamic>.from(e),
          ),
        );
      }
    } catch (_) {
      history = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> saveHistory(Map<String, dynamic> item) async {
    history.insert(0, item);
    if (history.length > 50) {
      history = history.take(50).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nx_diagnosis_history', jsonEncode(history));
    if (mounted) setState(() {});
  }

  Future<void> deleteHistory(int index) async {
    history.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nx_diagnosis_history', jsonEncode(history));
    if (mounted) setState(() {});
  }

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


  String cleanAnswer(dynamic value) {
    dynamic data = value;
    for (int i = 0; i < 4; i++) {
      if (data is Map) {
        data = data['result'] ?? data['answer'] ??
            data['response'] ?? data['description'] ??
            data['content'] ?? data['text'] ?? data;
      } else if (data is String) {
        final t = data.trim();
        if (t.startsWith('{') && t.endsWith('}')) {
          try {
            data = jsonDecode(t);
            continue;
          } catch (_) {}
        }
        break;
      } else {
        break;
      }
    }

    String text = data is String
        ? data
        : const JsonEncoder.withIndent('  ').convert(data);

    text = text.replaceAll(r'\n', '\n')
        .replaceAll('**', '')
        .replaceAll('\r', '')
        .trim();

    final lines = text.split('\n');
    final clean = <String>[];

    for (final line in lines) {
      final v = line.trim();
      if (v.isEmpty) {
        if (clean.isNotEmpty && clean.last.isNotEmpty) clean.add('');
      } else if (clean.isEmpty || clean.last != v) {
        clean.add(v);
      }
    }

    text = clean.join('\n').trim();

    // Giữ nguyên xuống dòng và tiêu đề 5 mục của AI.
    text = text
        .replaceAll(RegExp(r'\n{3,}'), '\\n\\n')
        .trim();

    if (text.length > 7000) {
      text = '${text.substring(0, 7000)}\n\n(Đã rút gọn nội dung)';
    }

    return text.isEmpty
        ? 'AI chưa tạo được nội dung phân tích.'
        : text;
  }
  Future<void> analyze() async {
    if (image == null || busy) return;

    setState(() {
      busy = true;
      result = null;
      error = null;
    });

    try {
      final bytes = await image!.readAsBytes();
      final path = image!.path.toLowerCase();

      final mime = path.endsWith('.png')
          ? 'image/png'
          : path.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';

      final context =
          'Loại cây: $crop. Giai đoạn: $stage. Bộ phận: $part. '
          'Hãy phân tích dấu hiệu trong ảnh, bệnh hoặc nguyên nhân nghi ngờ, '
          'mức độ, dấu hiệu nhận biết, cách chăm sóc và phòng ngừa. '
          'Nếu không đủ dữ liệu hãy nói rõ, không khẳng định chắc chắn. '
          'Trả lời bằng tiếng Việt, trình bày dễ hiểu.';

      final response = await ApiService.diagnose(
        imageBase64: base64Encode(bytes),
        mimeType: mime,
        context: context,
      );

      final pretty = cleanAnswer(response);

      await saveHistory({
        'crop': crop,
        'stage': stage,
        'part': part,
        'date': DateTime.now().toIso8601String(),
        'result': pretty,
      });

      if (mounted) setState(() => result = pretty);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Phân tích thất bại. Kiểm tra Internet hoặc Worker AI.\n\n$e';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void showHistoryItem(Map<String, dynamic> item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item['crop'] ?? 'Cây trồng'} • ${item['part'] ?? ''}'),
        content: SingleChildScrollView(
          child: SelectableText(
            item['result']?.toString() ?? 'Không có kết quả',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF167A45);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI chẩn đoán cây trồng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE5F5E9), Color(0xFFF4FAF5)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.eco_rounded, size: 50, color: green),
                SizedBox(height: 10),
                Text(
                  'Trợ lý chẩn đoán cây trồng',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Chọn thông tin cây và gửi ảnh để AI phân tích.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: crop,
            decoration: const InputDecoration(
              labelText: 'Loại cây',
              border: OutlineInputBorder(),
            ),
            items: crops.map((v) {
              return DropdownMenuItem(value: v, child: Text(v));
            }).toList(),
            onChanged: busy ? null : (v) => setState(() => crop = v!),
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: stage,
            decoration: const InputDecoration(
              labelText: 'Giai đoạn sinh trưởng',
              border: OutlineInputBorder(),
            ),
            items: stages.map((v) {
              return DropdownMenuItem(value: v, child: Text(v));
            }).toList(),
            onChanged: busy ? null : (v) => setState(() => stage = v!),
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: part,
            decoration: const InputDecoration(
              labelText: 'Bộ phận cần kiểm tra',
              border: OutlineInputBorder(),
            ),
            items: parts.map((v) {
              return DropdownMenuItem(value: v, child: Text(v));
            }).toList(),
            onChanged: busy ? null : (v) => setState(() => part = v!),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => chooseImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Chụp ảnh'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => chooseImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Thư viện'),
                ),
              ),
            ],
          ),

          if (image != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(image!, height: 250, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: busy ? null : analyze,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Phân tích bằng AI'),
              style: FilledButton.styleFrom(
                backgroundColor: green,
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],

          if (busy) ...[
            const SizedBox(height: 24),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: green),
                  SizedBox(height: 12),
                  Text('AI đang phân tích ảnh...'),
                  SizedBox(height: 5),
                  Text('Vui lòng chờ, có thể mất một lúc'),
                ],
              ),
            ),
          ],

          if (error != null) ...[
            const SizedBox(height: 14),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(error!),
              ),
            ),
          ],

          if (result != null) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KẾT QUẢ AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: green,
                      ),
                    ),
                    const Divider(height: 24),
                    SelectableText(result!, style: const TextStyle(height: 1.5)),
                  ],
                ),
              ),
            ),
            const Text(
              'Kết quả chỉ mang tính tham khảo. Không sử dụng thuốc chỉ dựa vào AI.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],

          const SizedBox(height: 22),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lịch sử chẩn đoán',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text('${history.length}/50'),
            ],
          ),

          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chưa có lịch sử phân tích.'),
            ),

          ...history.asMap().entries.map((entry) {
            final i = entry.key;
            final h = entry.value;
            final d = DateTime.tryParse(h['date']?.toString() ?? '')
                ?? DateTime.now();

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.biotech),
                ),
                title: Text('${h['crop'] ?? 'Cây'} • ${h['part'] ?? ''}'),
                subtitle: Text(
                  '${h['stage'] ?? ''} • ${d.day}/${d.month}/${d.year}',
                ),
                onTap: () => showHistoryItem(h),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => deleteHistory(i),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
