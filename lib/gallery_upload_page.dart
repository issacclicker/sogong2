import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GalleryUploadPage extends StatefulWidget {
  final String template;
  const GalleryUploadPage({super.key, required this.template});

  @override
  State<GalleryUploadPage> createState() => _GalleryUploadPageState();
}

class _GalleryUploadPageState extends State<GalleryUploadPage> {
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.template, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _pickedImage != null
            ? Image.file(File(_pickedImage!.path), width: 300)
            : const Text("선택된 사진 없음"),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _pickImage,
          child: const Text("갤러리에서 사진 선택"),
        ),
      ],
    );
  }
}
