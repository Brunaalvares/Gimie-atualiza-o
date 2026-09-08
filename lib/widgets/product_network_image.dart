import 'package:flutter/material.dart';

/// Product image that works on Flutter web (CDN CORS) and native.
///
/// Uses [WebHtmlElementStrategy.fallback] so CanvasKit can fall back to an
/// HTML &lt;img&gt; when the image host does not send CORS headers.
class ProductNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final Color placeholderColor;

  const ProductNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.errorWidget,
    this.placeholderColor = const Color(0xFFEFEFEF),
  });

  static String normalizeUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://')) {
      return 'https://${trimmed.substring(7)}';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final url = normalizeUrl(imageUrl);
    final fallback = errorWidget ??
        ColoredBox(
          color: placeholderColor,
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFFBDBDBD),
              size: 28,
            ),
          ),
        );

    if (url.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: fallback,
      );
    }

    Widget image = Image.network(
      url,
      fit: fit,
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      alignment: Alignment.center,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: placeholderColor,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF8B7FB8),
              ),
            ),
          ),
        );
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
