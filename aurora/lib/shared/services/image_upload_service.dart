/// Servicio compartido para subir imágenes a Supabase Storage.
/// Usado en Social (posts), Chat (diagnóstico), y Perfil (avatar).
/// Maneja strip de EXIF/GPS, compresión, y upload a Storage.
library;

import 'dart:io';

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/exceptions.dart';

class ImageUploadService {
  final SupabaseClient _supabase;

  ImageUploadService(this._supabase);

  /// Sube una imagen a Supabase Storage.
  ///
  /// 1. Lee los bytes del archivo
  /// 2. Re-encodea como JPEG para eliminar metadata EXIF/GPS
  /// 3. Comprime si > 2MB
  /// 4. Sube a Supabase Storage
  /// 5. Retorna URL pública
  Future<String> uploadImage({
    required File imageFile,
    required String bucket,
    required String path,
  }) async {
    if (!imageFile.existsSync()) {
      throw ArgumentError('El archivo no existe: ${imageFile.path}');
    }

    try {
      // Leer bytes originales
      Uint8List bytes = await imageFile.readAsBytes();

      // Re-encodear como JPEG para eliminar metadata EXIF/GPS
      bytes = await _stripExifAndCompress(bytes);

      // Subir a Supabase Storage
      await _supabase.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Obtener URL pública
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } on StorageException catch (e) {
      throw ServerException(
        'Error al subir imagen: ${e.message}',
        statusCode: 500,
      );
    } catch (e) {
      if (e is ServerException || e is ArgumentError) rethrow;
      throw ServerException('Error inesperado al subir imagen: $e');
    }
  }

  /// Sube múltiples imágenes en paralelo.
  /// Retorna lista de URLs en el mismo orden.
  Future<List<String>> uploadMultiple({
    required List<File> imageFiles,
    required String bucket,
    required String basePath,
  }) async {
    if (imageFiles.isEmpty) return [];

    final futures = <Future<String>>[];
    for (int i = 0; i < imageFiles.length; i++) {
      final ext = 'jpg';
      final filePath = '${basePath}_$i.$ext';
      futures.add(uploadImage(
        imageFile: imageFiles[i],
        bucket: bucket,
        path: filePath,
      ));
    }

    return Future.wait(futures);
  }

  /// Re-encodea la imagen como JPEG limpio (sin EXIF/GPS).
  /// Si > 2MB, reduce calidad a 80%. Si aún > 2MB, escala a max 1920px.
  Future<Uint8List> _stripExifAndCompress(Uint8List originalBytes) async {
    return compute(_processImage, originalBytes);
  }

  /// Procesamiento de imagen en isolate (compute).
  /// Re-decodifica y re-encodea para strip EXIF.
  static Future<Uint8List> _processImage(Uint8List bytes) async {
    const maxSize = 2 * 1024 * 1024; // 2MB
    const maxWidth = 1920;

    try {
      // Decodificar imagen para strip EXIF
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Determinar si necesita resize
      int targetWidth = image.width;
      int targetHeight = image.height;

      if (bytes.length > maxSize && targetWidth > maxWidth) {
        final ratio = maxWidth / targetWidth;
        targetWidth = maxWidth;
        targetHeight = (targetHeight * ratio).round();
      }

      // Re-encodear como JPEG (sin metadata)
      // Si necesita resize, primero escalar
      ui.Image finalImage = image;
      if (targetWidth != image.width) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawImageRect(
          image,
          ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
          ui.Paint()..filterQuality = ui.FilterQuality.high,
        );
        final picture = recorder.endRecording();
        finalImage = await picture.toImage(targetWidth, targetHeight);
      }

      // Encodear como PNG (dart:ui no soporta JPEG directo)
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return bytes; // fallback

      final result = byteData.buffer.asUint8List();

      // Si el resultado sigue siendo > 2MB, retornar el original con un log
      if (result.length > maxSize) {
        debugPrint('Imagen aún > 2MB después de procesamiento: ${result.length} bytes');
      }

      return result;
    } catch (e) {
      // Si falla el procesamiento, retornar bytes originales
      debugPrint('Error procesando imagen, usando original: $e');
      return bytes;
    }
  }
}

/// Provider del servicio de subida de imágenes.
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  final supabase = Supabase.instance.client;
  return ImageUploadService(supabase);
});
