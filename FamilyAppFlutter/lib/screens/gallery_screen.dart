import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/family_member.dart';
import '../models/gallery_item.dart';
import '../providers/auth_provider.dart';
import '../providers/gallery_data.dart';
import 'add_gallery_item_screen.dart';
import 'gallery_viewer_screen.dart';

/// Displays a grid of gallery items and allows adding/removing entries.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('gallery'))),
      body: Consumer2<GalleryData, AuthProvider>(
        builder: (context, data, auth, _) {
          if (data.isLoading && data.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: data.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(context.tr('galleryEmpty'))),
                ],
              ),
            );
          }
          final FamilyMember? requester = auth.currentMember;
          return RefreshIndicator(
            onRefresh: data.refresh,
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemCount: data.items.length,
              itemBuilder: (context, index) {
                final GalleryItem item = data.items[index];
                final bool canDelete = (requester?.isAdmin ?? false) ||
                    (item.ownerId != null && item.ownerId == requester?.id);
                final String heroTag = 'gallery-${item.id}';
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (item.url == null) {
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GalleryViewerScreen(
                            item: item,
                            heroTag: heroTag,
                          ),
                        ),
                      );
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),

                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,

                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Hero(
                              tag: heroTag,
                              child: _GalleryThumbnail(item: item),
                            ),
                          ),
                          if (item.caption != null && item.caption!.isNotEmpty)
                            Positioned(
                              left: 8,
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(

                                  color: Colors.black.withOpacity(0.45),

                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.caption!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(color: Colors.white),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          Positioned(
                            left: 8,
                            top: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(

                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,

                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  item.createdAt != null
                                      ? _formatDate(context, item.createdAt!)
                                      : context.tr('unknownDate'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall,
                                ),
                              ),
                            ),
                          if (canDelete)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surface

                                    .withOpacity(0.85),

                                child: IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  tooltip: context.tr('deleteAction'),
                                  onPressed: () async {

                                    final gallery =
                                        context.read<GalleryData>();
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final deleteNotAllowedMessage =
                                        context.tr('galleryDeleteNotAllowed');
                                    try {
                                      await gallery.removeItem(
                                        item: item,
                                        requester: requester,
                                      );
                                    } catch (_) {
                                      messenger

                                        ..clearSnackBars()
                                        ..showSnackBar(
                                          SnackBar(
                                            content: Text(

                                              deleteNotAllowedMessage,

                                            ),
                                          ),
                                        );
                                    }
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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
      ),
    );
  }
}

String _formatDate(BuildContext context, DateTime value) {
  final Locale locale = Localizations.localeOf(context);
  return DateFormat.yMMMd(locale.toString()).format(value.toLocal());
}

class _GalleryThumbnail extends StatelessWidget {
  const _GalleryThumbnail({required this.item});

  final GalleryItem item;

  @override
  Widget build(BuildContext context) {
    final String? url = item.thumbnailUrl ?? item.url;
    Widget child;
    if (url == null) {
      child = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),

          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,

        ),
        child: Icon(
          item.isVideo ? Icons.videocam : Icons.photo,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, widget, event) {
            if (event == null) {
              return widget;
            }
            final double? value;
            if (event.expectedTotalBytes != null &&
                event.expectedTotalBytes! > 0) {
              value = event.cumulativeBytesLoaded /
                  event.expectedTotalBytes!.toDouble();
            } else {
              value = null;
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                widget,
                Container(
                  color: Colors.black12,
                  child: Center(
                    child: CircularProgressIndicator(value: value),
                  ),
                ),
              ],
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),

                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,

              ),
              child: Icon(
                item.isVideo ? Icons.videocam_off : Icons.broken_image,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      );
    }

    if (!item.isVideo) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DecoratedBox(
              decoration: BoxDecoration(

                color: Colors.black.withOpacity(0.45),

                borderRadius: BorderRadius.circular(20),
              ),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
