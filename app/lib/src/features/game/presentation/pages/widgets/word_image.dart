import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/presentation/theme/app_theme.dart';

class WordImage extends StatefulWidget {
  final String imageUrl;

  const WordImage({super.key, required this.imageUrl});

  @override
  State<WordImage> createState() => _WordImageState();
}

class _WordImageState extends State<WordImage> {
  late List<String> _candidates;
  int _candidateIndex = 0;

  @override
  void initState() {
    super.initState();
    _candidates = _buildCandidates(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant WordImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _candidates = _buildCandidates(widget.imageUrl);
      _candidateIndex = 0;
    }
  }

  List<String> _buildCandidates(String url) {
    final candidates = <String>[url];
    final match = RegExp(r'\.([^.\/]+)$').firstMatch(url);
    final hasExtension = match != null;
    final base = hasExtension ? url.substring(0, match.start) : url;

    const extensions = ['png', 'jpg', 'jpeg', 'JPG', 'JPEG', 'PNG'];
    for (final extension in extensions) {
      final candidate = '$base.$extension';
      if (!candidates.contains(candidate)) {
        candidates.add(candidate);
      }
    }

    return candidates;
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _candidates[_candidateIndex],
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.neonCyan,
        ),
      ),
      errorWidget: (context, url, error) {
        if (_candidateIndex < _candidates.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _candidateIndex++;
            });
          });
          return const SizedBox.shrink();
        }

        return const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white24,
          size: 48,
        );
      },
    );
  }
}
