import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gallery_item.dart';
import '../providers/gallery_data.dart';
import 'add_gallery_item_screen.dart';

/// Displays a grid of gallery items and allows adding/removing entries.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: Consumer<GalleryData>(
        builder: (context, data, _) {
          if (data.items.isEmpty) {
            return const Center(child: Text('No gallery items.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: data.items.length,
            itemBuilder: (context, index) {
              final GalleryItem item = data.items[index];
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      item.url ?? 'No URL',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        final id = item.id ?? item.url ?? '';
                        context.read<GalleryData>().removeItem(id);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddGalleryItemScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
