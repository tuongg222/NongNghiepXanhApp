
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmProfileScreen extends StatefulWidget {
  const FarmProfileScreen({super.key});

  @override
  State<FarmProfileScreen> createState() => _FarmProfileScreenState();
}

class _FarmProfileScreenState extends State<FarmProfileScreen> {
  final name = TextEditingController();
  final area = TextEditingController();
  final variety = TextEditingController();
  final sowDate = TextEditingController();
  final location = TextEditingController();
  final note = TextEditingController();

  String stage = 'Mạ';
  bool loading = true;

  final stages = [
    'Mạ', 'Đẻ nhánh', 'Làm đòng', 'Trổ bông',
    'Chắc hạt', 'Sắp thu hoạch'
  ];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('nx_farm_profile');
    if (raw != null) {
      final d = jsonDecode(raw) as Map<String, dynamic>;
      name.text = d['name'] ?? '';
      area.text = d['area'] ?? '';
      variety.text = d['variety'] ?? '';
      sowDate.text = d['sowDate'] ?? '';
      location.text = d['location'] ?? '';
      note.text = d['note'] ?? '';
      stage = d['stage'] ?? 'Mạ';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> saveProfile() async {
    final data = {
      'name': name.text.trim(),
      'area': area.text.trim(),
      'variety': variety.text.trim(),
      'sowDate': sowDate.text.trim(),
      'location': location.text.trim(),
      'stage': stage,
      'note': note.text.trim(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nx_farm_profile', jsonEncode(data));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu hồ sơ ruộng 🌾')),
    );
  }

  Widget field(String label, TextEditingController c,
      {String hint = '', TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    name.dispose();
    area.dispose();
    variety.dispose();
    sowDate.dispose();
    location.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌾 Hồ sơ ruộng')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text('Thông tin ruộng của bạn',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('AI sẽ sử dụng hồ sơ này để tư vấn sát thực tế hơn.'),
                const SizedBox(height: 20),
                field('Tên ruộng', name, hint: 'Ví dụ: Ruộng nhà'),
                field('Diện tích (ha)', area, type: TextInputType.number),
                field('Giống lúa', variety, hint: 'Ví dụ: OM18'),
                field('Ngày gieo sạ', sowDate, hint: 'dd/mm/yyyy'),
                field('Địa điểm', location, hint: 'Xã, huyện, tỉnh'),
                DropdownButtonFormField<String>(
                  value: stages.contains(stage) ? stage : stages.first,
                  decoration: const InputDecoration(
                    labelText: 'Giai đoạn sinh trưởng',
                    border: OutlineInputBorder(),
                  ),
                  items: stages.map((s) =>
                    DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => stage = v ?? stages.first),
                ),
                const SizedBox(height: 14),
                field('Ghi chú tình trạng ruộng', note,
                    hint: 'Ví dụ: lá hơi vàng, nước đang ngập 3cm'),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: saveProfile,
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu hồ sơ ruộng'),
                ),
              ],
            ),
    );
  }
}
