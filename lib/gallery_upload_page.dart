import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GalleryUploadPage extends StatefulWidget {
  final String template; // ex: "영수증 > 카드전표"
  const GalleryUploadPage({super.key, required this.template});

  @override
  State<GalleryUploadPage> createState() => _GalleryUploadPageState();
}

class _GalleryUploadPageState extends State<GalleryUploadPage> {
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadImageFromFirestore(); // ✅ Firestore에서 사진 불러오기
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
      final url = snapshot.docs.first['url'] as String;
      setState(() {
        _imageUrl = url;
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

    final ref = FirebaseStorage.instance
        .ref()
        .child('uploads/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(File(image.path));
    final downloadUrl = await ref.getDownloadURL();

    // ✅ Firestore에 업로드 정보 저장
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
      _imageUrl = downloadUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _pickedImage != null
        ? Image.file(File(_pickedImage!.path), width: 300)
        : _imageUrl != null
        ? Image.network(_imageUrl!, width: 300)
        : const Text("사진 없음");

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.template, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        imageWidget,
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _pickImage,
          child: const Text("갤러리에서 사진 선택"),
        ),
      ],
    );
  }
}
