import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_localizations.dart';
import '../models/gallery_item.dart';
import '../providers/auth_provider.dart';

class GalleryViewerScreen extends StatefulWidget {
  const GalleryViewerScreen({
    super.key,
    required this.item,
    required this.heroTag,
  });

  static const String routeName = 'GalleryViewerScreen';

  final GalleryItem item;
  final String heroTag;

  @override
  State<GalleryViewerScreen> createState() => _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends State<GalleryViewerScreen> {
  VideoPlayerController? _videoController;
  bool _initializing = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    if (widget.item.isVideo && widget.item.url != null) {
      _initializing = true;
      final Uri uri = Uri.parse(widget.item.url!);
      final VideoPlayerController controller =
          VideoPlayerController.networkUrl(uri)
            ..setLooping(true);
      controller.initialize().then((_) {
        if (!mounted) {
          controller.dispose();
          return;
        }
        setState(() {
          _initializing = false;
          _videoController = controller;
        });
        controller.play();
      }).catchError((Object error) {
        controller.dispose();
        if (!mounted) return;
        setState(() {
          _videoError = error.toString();
          _initializing = false;
          _videoController = null;
        });
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GalleryItem item = widget.item;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(item.caption?.isNotEmpty == true
            ? item.caption!
            : context.tr('gallery')),
      ),
      floatingActionButton: item.isVideo && _videoController != null
          ? FloatingActionButton(
              onPressed: _togglePlayback,
              tooltip: _videoController!.value.isPlaying
                  ? context.tr('galleryPauseVideo')
                  : context.tr('galleryPlayVideo'),
              child: Icon(_videoController!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMedia(context, item)),
            Container(
              width: double.infinity,
              color: Colors.black.withValues(alpha: 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _GalleryMetadata(item: item, textTheme: textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(BuildContext context, GalleryItem item) {
    if (item.isVideo) {
      return _buildVideoPlayer(context);
    }
    final String? url = item.url;
    if (url == null) {
      return Center(
        child: Text(
          context.tr('galleryMissingMedia'),
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.white),
        ),
      );
    }
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 4,
        child: Center(
          child: Hero(
            tag: widget.heroTag,
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context) {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_videoError != null) {
      return Center(
        child: Text(
          context.tr('galleryVideoFailed'),
          style:
              Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }
    final VideoPlayerController? controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: Text(
          context.tr('galleryMissingMedia'),
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.white),
        ),
      );
    }
    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Hero(
              tag: widget.heroTag,
              child: AspectRatio(
                aspectRatio:
                    controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: controller.value.isPlaying ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
            ),
          ),
        ],
      ),
    );
  }

  void _togglePlayback() {
    final VideoPlayerController? controller = _videoController;
    if (controller == null) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }
}

class _GalleryMetadata extends StatelessWidget {
  const _GalleryMetadata({required this.item, required this.textTheme});

  final GalleryItem item;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final String createdAt = item.createdAt != null
        ? DateFormat.yMMMd(locale.toString())
            .add_jm()
            .format(item.createdAt!.toLocal())
        : context.tr('unknownDate');
    final String typeLabel = _describeType(context, item);
    final String sizeLabel =
        item.sizeBytes != null ? _formatBytes(item.sizeBytes!) : context.tr('unknownSize');
    final auth = context.watch<AuthProvider>();
    final ownerId = item.ownerId;
    final String ownerLabel;
    if (ownerId != null && auth.currentMember?.id == ownerId) {
      ownerLabel = context.tr('galleryOwnerYou');
    } else if (ownerId != null) {
      ownerLabel = ownerId;
    } else {
      ownerLabel = context.tr('galleryOwnerUnknown');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.caption != null && item.caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              item.caption!,
              style: textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ),
        _MetadataRow(
          label: context.tr('galleryMetadataOwner'),
          value: ownerLabel,
        ),
        const SizedBox(height: 4),
        _MetadataRow(
          label: context.tr('galleryMetadataType'),
          value: typeLabel,
        ),
        const SizedBox(height: 4),
        _MetadataRow(
          label: context.tr('galleryMetadataSize'),
          value: sizeLabel,
        ),
        const SizedBox(height: 4),
        _MetadataRow(
          label: context.tr('galleryMetadataCreated'),
          value: createdAt,
        ),
      ],
    );
  }

  String _formatBytes(int value) {
    if (value <= 0) {
      return '0 B';
    }
    const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    double size = value.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final bool useDecimals = unitIndex > 0 && size < 100;
    final String formatted = useDecimals
        ? size.toStringAsFixed(1)
        : size.toStringAsFixed(0);
    return '$formatted ${units[unitIndex]}';
  }

  String _describeType(BuildContext context, GalleryItem item) {
    switch (item.mediaType) {
      case GalleryMediaType.image:
        return context.tr('galleryTypeImage');
      case GalleryMediaType.video:
        return context.tr('galleryTypeVideo');
      case GalleryMediaType.other:
        return context.tr('galleryTypeFile');
    }
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.white70),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
