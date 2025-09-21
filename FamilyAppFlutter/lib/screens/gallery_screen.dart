import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/gallery_item.dart';
import '../providers/gallery_data.dart';

/// Screen displaying the family gallery of uploaded photos and videos.
///
/// The gallery screen uses a [GridView] to show thumbnails. Users can add
/// new images by tapping the floating action button. In a complete
/// implementation the picked image would be uploaded to Firebase Storage and
/// the resulting download URL stored in [GalleryItem.url]. Here we simply
/// store the local file path for demonstration purposes.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(BuildContext context) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    final file = File(pickedFile.path);
    // In production, upload the file to cloud storage and obtain a download URL.
    final galleryItem = GalleryItem(
      url: file.path,
      uploaderId: null,
    );
    Provider.of<GalleryData>(context, listen: false).addItem(galleryItem);
  }

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryData>();
    return Scaffold(
      appBar: AppBar(title: const Text('Семейная галерея')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: gallery.items.length,
        itemBuilder: (ctx, index) {
          final item = gallery.items[index];
          return GestureDetector(
            onLongPress: () {
              // Long press to delete
              gallery.removeItem(item.id);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(item.url),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.image));
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickImage(context),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}