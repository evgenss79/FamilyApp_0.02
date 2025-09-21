import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gallery_data.dart';
import '../models/gallery_item.dart';

/// Displays a grid of gallery items.  Each item simply shows the URL
/// text in this stub; images could be displayed using a network
/// image widget in a real implementation.
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
              return Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: Center(
                  child: Text(item.url ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}