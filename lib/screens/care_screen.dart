import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CareScreen extends StatefulWidget {
  const CareScreen({super.key});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  List<Map<String, dynamic>> tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('nx_care_tasks');

    if (data != null) {
      final decoded = jsonDecode(data) as List;
      tasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nx_care_tasks', jsonEncode(tasks));
  }

  Future<void> addTask() async {
    String type = 'Tưới nước';
    final titleController = TextEditingController();
    DateTime date = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm lịch chăm sóc'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                items: ['Tưới nước', 'Bón phân', 'Phun thuốc', 'Thu hoạch']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setDialogState(() => type = v!),
                decoration: const InputDecoration(labelText: 'Công việc'),
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên cây / ghi chú',
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  '${date.day}/${date.month}/${date.year}',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => date = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                tasks.add({
                  'type': type,
                  'title': titleController.text.trim(),
                  'date': date.toIso8601String(),
                });
                saveTasks();
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteTask(int index) async {
    tasks.removeAt(index);
    await saveTasks();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch chăm sóc cây trồng'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addTask,
        icon: const Icon(Icons.add),
        label: const Text('Thêm lịch'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(
                  child: Text('Chưa có lịch chăm sóc.\nNhấn + để thêm lịch!'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final date = DateTime.parse(task['date']);
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.eco),
                        ),
                        title: Text(task['title']),
                        subtitle: Text(
                          '${task['type']} • ${date.day}/${date.month}/${date.year}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => deleteTask(index),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
