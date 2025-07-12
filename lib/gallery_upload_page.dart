import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GalleryUploadPage extends StatefulWidget {
  final String template;
  const GalleryUploadPage({super.key, required this.template});

  @override
  State<GalleryUploadPage> createState() => _GalleryUploadPageState();
}

class _GalleryUploadPageState extends State<GalleryUploadPage> {
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  String? _downloadedUrl;

  @override
  void initState() {
    super.initState();
    _loadImageFromFirestore(); // 🔁 이전에 올린 이미지 불러오기
  }

  Future<void> _loadImageFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('uploadedImages')
        .where('template', isEqualTo: widget.template)
        .orderBy('uploadedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _downloadedUrl = snapshot.docs.first['url'];
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _pickedImage = image;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final file = File(image.path);
    final ref = FirebaseStorage.instance
        .ref()
        .child('uploads/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('uploadedImages')
        .add({
      'template': widget.template,
      'url': downloadUrl,
      'uploadedAt': Timestamp.now(),
    });

    setState(() {
      _downloadedUrl = downloadUrl;
    });
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
            : _downloadedUrl != null
            ? Image.network(_downloadedUrl!, width: 300)
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
