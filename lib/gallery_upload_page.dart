import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http; // Add this line

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
  List<XFile> _imageFiles = []; // Changed to list
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isLoading = false; // Added
  List<String> _downloadedImageUrls = []; // Added
  Map<String, Uint8List> _imageBytesCache = {}; // New cache for image bytes
  late PageController _pageController; // Added
  int _currentPage = 0; // Added

  // SnackBar를 표시하는 헬퍼 함수
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return; // 위젯이 화면에 없으면 스낵바를 표시하지 않음
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.black87,
      ),
    );
  }

  Future<void> _deleteImage(int index) async {
    if (index < 0 || index >= _downloadedImageUrls.length) {
      _showSnackBar('삭제할 이미지를 찾을 수 없습니다.', isError: true);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('로그인이 필요합니다.', isError: true);
      return;
    }

    final imageUrlToDelete = _downloadedImageUrls[index];

    setState(() {
      _isLoading = true; // Indicate loading
    });

    try {
      // 1. Delete from Firebase Storage
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrlToDelete);
      await storageRef.delete();

      // 2. Remove from local list
      _downloadedImageUrls.removeAt(index);
      _imageBytesCache.remove(imageUrlToDelete); // Remove from cache

      // 3. Update Firestore document
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('audits')
          .doc(widget.auditId)
          .collection('schedules')
          .doc(widget.scheduleId)
          .collection('categories')
          .doc(widget.itemId);

      await docRef.update({'imageUrls': _downloadedImageUrls});

      _showSnackBar('사진이 성공적으로 삭제되었습니다.');

      // Adjust _currentPage if the last image was deleted
      if (_currentPage >= _downloadedImageUrls.length && _downloadedImageUrls.isNotEmpty) {
        _pageController.jumpToPage(_downloadedImageUrls.length - 1);
      } else if (_downloadedImageUrls.isEmpty) {
        _pageController.jumpToPage(0); // Or handle empty state
      }
    } catch (e) {
      print("Error deleting image: $e");
      _showSnackBar('사진 삭제 실패: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        // Ensure UI updates after deletion
        if (_downloadedImageUrls.isEmpty) {
          _currentPage = 0; // Reset current page if no images left
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadImageUrlsFromFirestore(); // Call the new function
    _pageController = PageController(); // Initialize PageController
    _pageController.addListener(() {
      if (_pageController.page != null && _pageController.page!.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose(); // Dispose PageController
    super.dispose();
  }

  // Firestore에서 이미지 URL 불러오기
  Future<void> _loadImageUrlsFromFirestore() async {
    setState(() {
      _isLoading = true;
      _imageFiles = []; // Clear previously picked images
      _downloadedImageUrls = []; // Clear previously downloaded images
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

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        List<String> urls = [];
        if (data.containsKey('imageUrls')) {
          urls = List<String>.from(data['imageUrls']);
        } else if (data.containsKey('imageUrl')) { // Backward compatibility
          urls = [data['imageUrl']];
        }

        _downloadedImageUrls = urls;
        _imageBytesCache.clear(); // Clear cache before loading new images

        for (String url in urls) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(url);
            final Uint8List? bytes = (await http.get(Uri.parse(url))).bodyBytes;
            if (bytes != null && bytes.isNotEmpty) {
              _imageBytesCache[url] = bytes;
            }
          } catch (e) {
            print("Error downloading image from $url: $e (Type: ${e.runtimeType})");
          }
        }
        print('Loaded imageUrls: $_downloadedImageUrls');
        setState(() {
          _downloadedImageUrls = urls; // Ensure this is updated within setState
          _imageBytesCache = _imageBytesCache; // Trigger rebuild with updated cache
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading image URLs: $e");
      setState(() => _isLoading = false); // Ensure loading state is reset even on error
    }
  }

  // 갤러리에서 이미지 선택 및 업로드
  Future<void> _pickAndUploadImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isEmpty) return;

    setState(() {
      _imageFiles = selectedImages;
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      List<String> newDownloadUrls = [];
      for (XFile image in _imageFiles) {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
        final storageRef = FirebaseStorage.instance.ref().child(
          'uploads/${user.uid}/${widget.auditId}/${widget.scheduleId}/${widget.itemId}/$fileName',
        );

        final metadata = SettableMetadata(contentType: image.mimeType);
        if (kIsWeb) {
          final imageData = await image.readAsBytes();
          await storageRef.putData(imageData, metadata);
        } else {
          await storageRef.putFile(File(image.path), metadata);
        }
        final downloadUrl = await storageRef.getDownloadURL();
        newDownloadUrls.add(downloadUrl);
      }

      // Get existing image URLs
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('audits')
          .doc(widget.auditId)
          .collection('schedules')
          .doc(widget.scheduleId)
          .collection('categories')
          .doc(widget.itemId);

      final docSnapshot = await docRef.get();
      List<String> existingImageUrls = [];
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        if (data.containsKey('imageUrls')) {
          existingImageUrls = List<String>.from(data['imageUrls']);
        } else if (data.containsKey('imageUrl')) { // Backward compatibility
          existingImageUrls = [data['imageUrl']];
        }
      }

      // Combine existing and new URLs
      existingImageUrls.addAll(newDownloadUrls);

      // Update Firestore document with new imageUrls
      await docRef.set(
        {'imageUrls': existingImageUrls, 'uploadedAt': Timestamp.now()},
        SetOptions(merge: true),
      );

      setState(() {
        _downloadedImageUrls = existingImageUrls;
        _imageFiles = []; // Clear picked images after upload
      });
      if (mounted) {
        _showSnackBar('사진이 성공적으로 업로드되었습니다.');
      }
    } catch (e) {
      print("Error uploading images: $e");
      if (mounted) {
        _showSnackBar('사진 업로드 실패: $e', isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _imageFiles.isNotEmpty ? _imageFiles.length : _downloadedImageUrls.length;
    final currentImageIndex = totalImages > 0 ? _currentPage + 1 : 0;

    return Scaffold(
      
      body: Column(
        children: [
          Text(
            widget.itemDisplayName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (totalImages > 0)
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: totalImages,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      if (_imageFiles.isNotEmpty) {
                        return kIsWeb
                            ? Image.network(_imageFiles[index].path, fit: BoxFit.contain)
                            : Image.file(File(_imageFiles[index].path), fit: BoxFit.contain);
                      } else {
                        final imageUrl = _downloadedImageUrls[index];
                        final imageBytes = _imageBytesCache[imageUrl];
                        if (imageBytes != null) {
                          return Image.memory(imageBytes, fit: BoxFit.contain);
                        } else {
                          return const Center(child: CircularProgressIndicator());
                        }
                      }
                    },
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red, size: 30),
                      onPressed: () => _deleteImage(_currentPage),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '$currentImageIndex/$totalImages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const Expanded(child: Center(child: Text("업로드된 사진이 없습니다."))),
          const SizedBox(height: 10),
          if (totalImages > 0)
            SizedBox(
              height: 80, // Height for the thumbnail strip
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: totalImages,
                itemBuilder: (context, index) {
                  Widget imageWidget;
                  if (_imageFiles.isNotEmpty) {
                    imageWidget = kIsWeb
                        ? Image.network(_imageFiles[index].path, fit: BoxFit.cover)
                        : Image.file(File(_imageFiles[index].path), fit: BoxFit.cover);
                  } else {
                    final imageUrl = _downloadedImageUrls[index];
                    final imageBytes = _imageBytesCache[imageUrl];
                    if (imageBytes != null) {
                      imageWidget = Image.memory(imageBytes, fit: BoxFit.cover);
                    } else {
                      imageWidget = const Center(child: CircularProgressIndicator());
                    }
                  }
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _currentPage == index ? Colors.blueAccent : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: imageWidget,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickAndUploadImages,
            child: const Text("갤러리에서 사진 선택/변경"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
