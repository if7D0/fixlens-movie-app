import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../core/network/tmdb_image.dart';

/// YouTube trailer player (API locked from installed
/// youtube_player_flutter 10.0.1 + iframe 6.0.2: `fromVideoId` + `close()`).
/// Without a [videoId] renders a backdrop thumbnail fallback instead.
class TrailerPlayer extends StatefulWidget {
  final String? videoId;
  final String? backdropPath;

  const TrailerPlayer({super.key, this.videoId, this.backdropPath});

  @override
  State<TrailerPlayer> createState() => _TrailerPlayerState();
}

class _TrailerPlayerState extends State<TrailerPlayer> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = _create(widget.videoId);
  }

  @override
  void didUpdateWidget(covariant TrailerPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      unawaited(_controller?.close());
      setState(() => _controller = _create(widget.videoId));
    }
  }

  YoutubePlayerController? _create(String? videoId) {
    if (videoId == null || videoId.isEmpty) return null;
    return YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
    );
  }

  @override
  void dispose() {
    unawaited(_controller?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return _Fallback(backdropPath: widget.backdropPath);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: YoutubePlayer(controller: controller),
    );
  }
}

class _Fallback extends StatelessWidget {
  final String? backdropPath;

  const _Fallback({this.backdropPath});

  @override
  Widget build(BuildContext context) {
    final url = TmdbImage.backdrop(backdropPath);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
            else
              Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
              ),
            Container(color: Colors.black45),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_outline, size: 48, color: Colors.white),
                SizedBox(height: 4),
                Text(
                  'Trailer tidak tersedia',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
