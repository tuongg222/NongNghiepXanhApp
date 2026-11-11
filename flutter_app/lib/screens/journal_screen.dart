import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sync_service.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<Map<String, dynamic>> entries = [];
  List<Map<String, dynamic>> fields = [];
  final note = TextEditingController();
  final amount = TextEditingController();
  final cost = TextEditingController();
  final condition = TextEditingController();
  String type = 'Tưới nước';
  String selectedField = 'Tất cả ruộng';
  DateTime date = DateTime.now();

  final types = ['Tưới nước', 'Bón phân', 'Gieo trồng', 'Phun thuốc',
    'Thu hoạch', 'Làm cỏ', 'Dặm lúa', 'Công việc khác'];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    note.dispose();
    amount.dispose();
    cost.dispose();
    condition.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('nx_journal');
    final rawFields = prefs.getString('nx_fields');
    if (raw != null) {
      entries = List<Map<String, dynamic>>.from(
        (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }
    if (rawFields != null) {
      fields = List<Map<String, dynamic>>.from(
        (jsonDecode(rawFields) as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nx_journal', jsonEncode(entries));
    await SyncService.uploadKey('journal', entries);
  }

  String dateText(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String get fieldName => selectedField;

  List<Map<String, dynamic>> get visibleEntries => entries.where((e) {
    if (selectedField == 'Tất cả ruộng') return true;
    return (e['field']?.toString() ?? 'Chưa gắn ruộng') == selectedField;
  }).toList();

  double get totalCost => visibleEntries.fold<double>(
    0, (sum, e) => sum + ((e['cost'] as num?)?.toDouble() ?? 0),
  );

  Future<void> addEntry() async {
    note.clear();
    amount.clear();
    cost.clear();
    condition.clear();
    date = DateTime.now();
    type = types.first;
    String field = fields.isEmpty ? 'Chưa gắn ruộng' : fields.first['name'].toString();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: const Text('📝 Ghi nhật ký canh tác'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Công việc'),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => refresh(() => type = v ?? types.first),
              ),
              DropdownButtonFormField<String>(
                value: field,
                decoration: const InputDecoration(labelText: 'Thửa ruộng'),
                items: [
                  const DropdownMenuItem(value: 'Chưa gắn ruộng', child: Text('Chưa gắn ruộng')),
                  ...fields.map((f) => DropdownMenuItem(
                    value: f['name'].toString(), child: Text(f['name'].toString()),
                  )),
                ],
                onChanged: (v) => refresh(() => field = v ?? 'Chưa gắn ruộng'),
              ),
              TextField(controller: amount, decoration: const InputDecoration(
                labelText: 'Lượng sử dụng', hintText: 'Ví dụ: 20 kg, 500 lít')),
              TextField(controller: cost, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Chi phí (VNĐ)', hintText: 'Ví dụ: 250000')),
              TextField(controller: condition, decoration: const InputDecoration(
                labelText: 'Tình trạng lúa', hintText: 'Ví dụ: lúa xanh, sâu nhẹ...')),
              TextField(controller: note, maxLines: 3, decoration: const InputDecoration(
                labelText: 'Ghi chú', hintText: 'Mô tả công việc...')),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(context: ctx, initialDate: date,
                    firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (d != null) refresh(() => date = d);
                },
                child: Text('Ngày: ${dateText(date)}'),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );
    if (result != true) return;
    entries.insert(0, {
      'type': type,
      'field': field,
      'amount': amount.text.trim(),
      'cost': double.tryParse(cost.text.trim().replaceAll(',', '')) ?? 0,
      'condition': condition.text.trim(),
      'note': note.text.trim(),
      'date': date.toIso8601String(),
    });
    await save();
    if (mounted) setState(() {});
  }

  Future<void> deleteEntry(int i) async {
    final item = visibleEntries[i];
    entries.remove(item);
    await save();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = visibleEntries;
    return Scaffold(
      appBar: AppBar(title: const Text('📒 Nhật ký canh tác'),
        backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.white],
          begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.shade700, Colors.teal.shade400]),
              borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🌿 Nhật ký nhà nông', style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Đang xem ${list.length} công việc • Tổng chi phí: ${totalCost.toStringAsFixed(0)} đ',
                style: const TextStyle(color: Colors.white)),
            ]),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedField,
            decoration: const InputDecoration(labelText: 'Lọc theo ruộng', border: OutlineInputBorder()),
            items: ['Tất cả ruộng', ...fields.map((f) => f['name'].toString()),
              if (entries.any((e) => e['field'] == 'Chưa gắn ruộng')) 'Chưa gắn ruộng'
            ].toSet().map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            onChanged: (v) => setState(() => selectedField = v ?? 'Tất cả ruộng'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: addEntry, icon: const Icon(Icons.add),
            label: const Text('Ghi công việc mới'),
            style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.all(15))),
          const SizedBox(height: 12),
          if (list.isEmpty) const Card(child: Padding(
            padding: EdgeInsets.all(24), child: Center(child: Text('Chưa có nhật ký nào 🌱')))),
          ...list.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final d = DateTime.tryParse(item['date']?.toString() ?? '') ?? DateTime.now();
            final oldField = item['field']?.toString() ?? 'Chưa gắn ruộng';
            final oldCost = (item['cost'] as num?)?.toDouble() ?? 0;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE0F2E5),
                  child: Icon(Icons.eco, color: Colors.green)),
                title: Text('${item['type'] ?? 'Công việc'} • $oldField',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text([
                  dateText(d),
                  if ((item['amount']?.toString() ?? '').isNotEmpty) 'Lượng: ${item['amount']}',
                  if (oldCost > 0) 'Chi phí: ${oldCost.toStringAsFixed(0)} đ',
                  if ((item['condition']?.toString() ?? '').isNotEmpty) 'Tình trạng: ${item['condition']}',
                  if ((item['note']?.toString() ?? '').isNotEmpty) item['note'].toString(),
                ].join('\n')),
                isThreeLine: true,
                trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => deleteEntry(i)),
              ),
            );
          }),
        ]),
      ),
    );
  }
}
