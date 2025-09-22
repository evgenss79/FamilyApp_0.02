import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/gallery_item.dart';
import '../providers/gallery_data.dart';
import 'add_gallery_item_screen.dart';

/// Displays a grid of gallery items and allows adding/removing entries.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('gallery'))),
      body: Consumer<GalleryData>(
        builder: (context, data, _) {
          if (data.isLoading && data.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.items.isEmpty) {
            return Center(child: Text(context.tr('galleryEmpty')));
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
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.url != null)
                      Image.network(
                        item.url!,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(color: Colors.grey.shade200),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        backgroundColor:

                            Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.8),

                        child: IconButton(
                          onPressed: () async {
                            final id = item.id ?? item.url ?? '';
                            await context.read<GalleryData>().removeItem(id);
                          },
                          icon: const Icon(Icons.delete, size: 18),
                          tooltip: context.tr('deleteAction'),
                        ),
                      ),
                    ),
                  ],
                ),
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
        tooltip: context.tr('addGalleryItemTitle'),
        child: const Icon(Icons.add),
        tooltip: context.tr('addGalleryItemTitle'),
      ),
    );
  }
}
