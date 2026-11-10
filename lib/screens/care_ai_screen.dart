
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';
import 'ai_chat_screen.dart';

class CareAIScreen extends StatefulWidget {
  const CareAIScreen({super.key});

  @override
  State<CareAIScreen> createState() => _CareAIScreenState();
}

class _CareAIScreenState extends State<CareAIScreen> {
  Map<String, dynamic>? weather;
  bool loading = true;
  String? error;
  String stage = 'Đẻ nhánh';

  final stages = [
    'Mạ',
    'Đẻ nhánh',
    'Làm đòng',
    'Trổ bông',
    'Chín',
  ];

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await WeatherService.current();
      if (mounted) setState(() => weather = data);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Map<String, dynamic> get current =>
      (weather?['current'] as Map<String, dynamic>?) ?? {};

  double get temp => (current['temperature_2m'] as num?)?.toDouble() ?? 0;
  double get humidity =>
      (current['relative_humidity_2m'] as num?)?.toDouble() ?? 0;
  double get rain =>
      (current['precipitation'] as num?)?.toDouble() ?? 0;
  double get wind =>
      (current['wind_speed_10m'] as num?)?.toDouble() ?? 0;

  String get irrigation {
    if (rain >= 5) {
      return 'Có mưa gần đây, nên kiểm tra mực nước trước khi tưới.';
    }
    if (temp >= 35) {
      return 'Nắng nóng: kiểm tra nước trong ruộng vào sáng sớm hoặc chiều mát.';
    }
    return 'Kiểm tra đất và mực nước ruộng. Chỉ bổ sung nước khi cần.';
  }

  String get fertilizer {
    switch (stage) {
      case 'Mạ':
        return 'Giai đoạn mạ: ưu tiên cây khỏe, rễ phát triển; bón theo hướng dẫn địa phương.';
      case 'Đẻ nhánh':
        return 'Giai đoạn đẻ nhánh: theo dõi mật độ nhánh, cân đối dinh dưỡng và tránh bón dư đạm.';
      case 'Làm đòng':
        return 'Giai đoạn làm đòng: chú ý dinh dưỡng cân đối, kiểm tra tình trạng cây trước khi bón.';
      case 'Trổ bông':
        return 'Giai đoạn trổ: duy trì nước phù hợp, tránh bón phân hoặc phun thuốc tùy tiện.';
      default:
        return 'Giai đoạn chín: hạn chế tác động không cần thiết, theo dõi độ chín và kế hoạch thu hoạch.';
    }
  }

  List<String> get warnings {
    final result = <String>[];
    if (temp >= 35) result.add('Nắng nóng cao: theo dõi cây và mực nước.');
    if (humidity >= 85) result.add('Độ ẩm cao: tăng kiểm tra dấu hiệu bệnh.');
    if (rain >= 10) result.add('Mưa lớn: kiểm tra thoát nước và nguy cơ ngập.');
    if (result.isEmpty) result.add('Chưa ghi nhận ngưỡng cảnh báo từ dữ liệu hiện tại.');
    return result;
  }

  Future<void> addReminder(String type, String note) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('nx_care_tasks');
    final List<dynamic> tasks = raw == null ? [] : jsonDecode(raw);

    tasks.add({
      'type': type,
      'title': 'Lúa - $note',
      'date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    });

    await prefs.setString('nx_care_tasks', jsonEncode(tasks));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm lịch chăm sóc ngày mai!')),
    );
  }

  Widget infoCard(
    IconData icon,
    String title,
    String content, {
    Color color = const Color(0xFF167A45),
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE4EEE5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ]),
            const SizedBox(height: 10),
            Text(content, style: const TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF167A45);

    return Scaffold(
      appBar: AppBar(
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE3F4E7), Color(0xFFF5FAF5)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.wb_sunny_rounded, size: 42, color: green),
                      const SizedBox(height: 8),
                      const Text('Thời tiết hiện tại',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _weatherValue('Nhiệt độ', '${temp.toStringAsFixed(1)}°C'),
                          _weatherValue('Độ ẩm', '${humidity.toStringAsFixed(0)}%'),
                          _weatherValue('Mưa', '${rain.toStringAsFixed(1)} mm'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Gió ${wind.toStringAsFixed(1)} km/h',
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                if (error != null)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Không tải được thời tiết: $error'),
                    ),
                  ),

                const SizedBox(height: 12),
                infoCard(Icons.warning_amber_rounded, 'Cảnh báo thời tiết',
                    warnings.map((e) => '• $e').join('\n'),
                    color: Colors.orange),

                infoCard(Icons.water_drop_rounded, 'Tư vấn tưới nước',
                    irrigation, color: Colors.blue),

                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFE4EEE5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.grass, color: green),
                          SizedBox(width: 8),
                          Text('Giai đoạn cây lúa',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: stage,
                          decoration: const InputDecoration(
                            labelText: 'Chọn giai đoạn',
                            border: OutlineInputBorder(),
                          ),
                          items: stages.map((s) =>
                              DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => stage = v ?? stage),
                        ),
                        const SizedBox(height: 12),
                        Text(fertilizer, style: const TextStyle(height: 1.5)),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => addReminder('Bón phân', 'Kiểm tra $stage'),
                          icon: const Icon(Icons.notifications_active),
                          label: const Text('Thêm lịch kiểm tra'),
                          style: FilledButton.styleFrom(backgroundColor: green),
                        ),
                      ],
                    ),
                  ),
                ),

                infoCard(Icons.psychology_alt, 'Vì sao cần chăm sóc?',
                    'Khuyến nghị dựa trên nhiệt độ, độ ẩm và lượng mưa hiện tại. '
                    'Mưa có thể làm giảm nhu cầu tưới; nhiệt độ cao làm tăng nguy cơ '
                    'stress nước; độ ẩm cao khiến cần theo dõi bệnh. '
                    'Đây là tư vấn quy tắc, chưa phải kết luận AI chuyên sâu.'),

                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => addReminder('Tưới nước', 'Kiểm tra mực nước'),
                  icon: const Icon(Icons.add_alarm),
                  label: const Text('Nhắc kiểm tra tưới nước ngày mai'),
                  style: FilledButton.styleFrom(
                    backgroundColor: green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Lưu ý: Khuyến nghị chỉ tham khảo. Cần căn cứ giống cây, đất, '
                  'giai đoạn thực tế và hướng dẫn khuyến nông địa phương.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
    );
  }

  Widget _weatherValue(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}
