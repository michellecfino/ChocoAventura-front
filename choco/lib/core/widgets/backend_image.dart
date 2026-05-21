import 'package:choco/core/services/api_client.dart';
import 'package:flutter/material.dart';

/// Imagen que puede venir como URL absoluta, ruta estática del backend
/// (`/assets/...`) o ruta legacy (`assets/...`).
class BackendImage extends StatelessWidget {
  final String? source;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final FilterQuality filterQuality;
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;

  const BackendImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit,
    this.filterQuality = FilterQuality.medium,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = resolveBackendAssetUrl(source);
    if (resolved == null || resolved.isEmpty) {
      return _fallback(context, StateError('No image source'), null);
    }
    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return Image.network(
        resolved,
        width: width,
        height: height,
        fit: fit,
        filterQuality: filterQuality,
        errorBuilder: errorBuilder ?? _fallback,
      );
    }
    return Image.asset(
      resolved,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      errorBuilder: errorBuilder ?? _fallback,
    );
  }

  Widget _fallback(BuildContext context, Object error, StackTrace? stackTrace) {
    if (errorBuilder != null) return errorBuilder!(context, error, stackTrace);
    return const SizedBox.shrink();
  }
}

String? resolveBackendAssetUrl(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) return value;

  final client = const ApiClient();
  if (value.startsWith('/assets/')) {
    return client.configurado ? '${client.baseUrl}$value' : value;
  }
  if (value.startsWith('assets/')) {
    return client.configurado ? '${client.baseUrl}/$value' : value;
  }
  return value;
}
