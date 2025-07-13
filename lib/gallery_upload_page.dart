import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GalleryUploadPage extends StatefulWidget {
  final String auditId;
  final String scheduleId;
  final String itemId; // 항목의 고유 ID
  final String itemDisplayName; // 항목의 표시 이름

  const GalleryUploadPage({
    super.key,
    required this.auditId,
    required this.scheduleId,
    required this.itemId,
    required this.itemDisplayName,
  });

  @override
  State<GalleryUploadPage> createState() => _GalleryUploadPageState();
}

class _GalleryUploadPageState extends State<GalleryUploadPage> {
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  String? _imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImageFromFirestore();
  }

  // itemId가 변경될 때마다 이미지를 다시 로드
  @override
  void didUpdateWidget(covariant GalleryUploadPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemId != oldWidget.itemId) {
      _loadImageFromFirestore();
    }
  }

  // Firestore에서 이미지 URL 불러오기
  Future<void> _loadImageFromFirestore() async {
    setState(() {
      _isLoading = true;
      _imageUrl = null;
      _pickedImage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('audits')
          .doc(widget.auditId)
          .collection('schedules')
          .doc(widget.scheduleId)
          .collection('categories')
          .doc(widget.itemId)
          .get();

      if (docSnapshot.exists && docSnapshot.data()!.containsKey('imageUrl')) {
        setState(() {
          _imageUrl = docSnapshot.data()!['imageUrl'];
        });
      }
    } catch (e) {
      // 에러 처리
      print("Error loading image: $e");
    }

    setState(() => _isLoading = false);
  }

  // 갤러리에서 이미지 선택 및 업로드
  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _pickedImage = image;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Storage에 이미지 업로드
      final storageRef = FirebaseStorage.instance.ref().child(
          'uploads/${user.uid}/${widget.auditId}/${widget.scheduleId}/${widget.itemId}.jpg');
      await storageRef.putFile(File(image.path));
      final downloadUrl = await storageRef.getDownloadURL();

      // 2. Firestore 문서에 이미지 URL 업데이트
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('audits')
          .doc(widget.auditId)
          .collection('schedules')
          .doc(widget.scheduleId)
          .collection('categories')
          .doc(widget.itemId)
          .update({
        'imageUrl': downloadUrl,
        'uploadedAt': Timestamp.now(),
      });

      setState(() {
        _imageUrl = downloadUrl;
      });
    } catch (e) {
      // 에러 처리
      print("Error uploading image: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (_isLoading) {
      imageWidget = const CircularProgressIndicator();
    } else if (_pickedImage != null) {
      imageWidget = Image.file(File(_pickedImage!.path), width: 300, fit: BoxFit.contain);
    } else if (_imageUrl != null) {
      imageWidget = Image.network(_imageUrl!, width: 300, fit: BoxFit.contain);
    } else {
      imageWidget = const Text("업로드된 사진이 없습니다.");
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.itemDisplayName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: Center(child: imageWidget),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _pickAndUploadImage,
          child: const Text("갤러리에서 사진 선택/변경"),
        ),
      ],
    );
  }
}
