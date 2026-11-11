import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? imageData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAvatar();
  }

  Future<void> loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();

    // Avatar mới: lưu trực tiếp dữ liệu ảnh
    final saved = prefs.getString('nx_profile_avatar_data');

    // Avatar cũ: vẫn hỗ trợ đường dẫn cũ
    final oldPath = prefs.getString('nx_profile_avatar');

    if (saved != null && saved.isNotEmpty) {
      imageData = saved;
    } else if (oldPath != null && File(oldPath).existsSync()) {
      try {
        imageData = base64Encode(await File(oldPath).readAsBytes());
        await prefs.setString('nx_profile_avatar_data', imageData!);
      } catch (_) {}
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> chooseAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 700,
      );

      if (picked == null) return;

      final bytes = await File(picked.path).readAsBytes();
      final encoded = base64Encode(bytes);

      final prefs = await SharedPreferences.getInstance();

      // Lưu dữ liệu ảnh bền vững, không phụ thuộc file tạm
      await prefs.setString('nx_profile_avatar_data', encoded);

      // Xóa đường dẫn cũ sau khi đã lưu ảnh mới
      await prefs.remove('nx_profile_avatar');

      if (mounted) {
        setState(() => imageData = encoded);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể đổi avatar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = imageData != null && imageData!.isNotEmpty;

    return GestureDetector(
      onTap: chooseAvatar,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFB8F5D2),
              Color(0xFF37C982),
              Color(0xFF087647),
            ],
          ),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : hasAvatar
                  ? Image.memory(
                      base64Decode(imageData!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 35,
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 35,
                    ),
        ),
      ),
    );
  }
}
