import 'dart:convert';
import 'package:flutter/material.dart';

/// Renders the operator's custom beach background image (a photo or
/// planimetry uploaded from the map editor) full-bleed behind the map
/// elements. Returns an empty widget when no custom background is set, so
/// callers can unconditionally place this at the bottom of their Stack.
class BeachBackgroundLayer extends StatelessWidget {
  final String? backgroundImageDataUrl;

  const BeachBackgroundLayer({super.key, required this.backgroundImageDataUrl});

  @override
  Widget build(BuildContext context) {
    final dataUrl = backgroundImageDataUrl;
    if (dataUrl == null) return const SizedBox.shrink();
    try {
      final bytes = base64Decode(dataUrl.split(',').last);
      return Positioned.fill(
        child: Image.memory(bytes, fit: BoxFit.cover),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
