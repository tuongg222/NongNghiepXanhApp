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
  String? imagePath;

  @override
  void initState() {
    super.initState();
    loadAvatar();
  }

  Future<void> loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('nx_profile_avatar');

    if (path != null && File(path).existsSync()) {
      if (mounted) setState(() => imagePath = path);
    }
  }

  Future<void> chooseAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 700,
    );

    if (image == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nx_profile_avatar', image.path);

    if (mounted) setState(() => imagePath = image.path);
  }

  @override
  Widget build(BuildContext context) {
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
          child: imagePath != null
              ? Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person,
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
