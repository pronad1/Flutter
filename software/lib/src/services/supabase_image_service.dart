import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of an upload: keep BOTH the public URL (for UI)
/// and the storage path (for future deletion/updates).
class UploadResult {
  final String path;      // e.g. users/<uid>/1716030123.jpg
  final String publicUrl; // e.g. https://.../storage/v1/object/public/avatars/users/...
  UploadResult({required this.path, required this.publicUrl});
}

class SupabaseImageService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Default public bucket for profile photos.
  /// You can pass a different bucket name to the item upload helpers below.
  final String bucket;

  SupabaseImageService({this.bucket = 'avatars'});

  /// Upload a profile image under:  users/<uid>/<timestamp>.<ext>
  /// Returns (path, publicUrl).
  Future<UploadResult> uploadProfileImage({
    required String uid,
    required XFile file,
  }) async {
    final ext = _normalizedExt(file.name);
    final contentType = lookupMimeType(file.name) ?? 'image/*';
    final path = 'users/$uid/${DateTime.now().millisecondsSinceEpoch}$ext';

    await _uploadAny(path: path, file: file, contentType: contentType, toBucket: bucket);

    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    return UploadResult(path: path, publicUrl: publicUrl);
  }

  /// Upload an item image under: items/<uid>/<itemId>/<timestamp>.<ext>
  /// Optionally use another bucket (e.g., 'items'), defaults to current [bucket].
  Future<UploadResult> uploadItemImage({
    required String uid,
    required String itemId,
    required XFile file,
    String? toBucket,
  }) async {
    final b = toBucket ?? bucket;
    final ext = _normalizedExt(file.name);
    final contentType = lookupMimeType(file.name) ?? 'image/*';
    final path = 'items/$uid/$itemId/${DateTime.now().millisecondsSinceEpoch}$ext';

    await _uploadAny(path: path, file: file, contentType: contentType, toBucket: b);

    final publicUrl = _client.storage.from(b).getPublicUrl(path);
    return UploadResult(path: path, publicUrl: publicUrl);
  }

  /// Delete by storage path (NOT URL). Safe to call even if file is missing.
  Future<void> deleteIfExists(String? path, {String? fromBucket}) async {
    if (path == null || path.trim().isEmpty) return;
    final b = fromBucket ?? bucket;
    try {
      await _client.storage.from(b).remove([path]);
    } catch (_) {
      // Ignore: file may not exist or already deleted.
    }
  }

  /// Utility: if you stored URL earlier and need to backfill the path.
  /// Example public URL:
  /// https://<project>.supabase.co/storage/v1/object/public/<bucket>/users/uid/123.jpg
  static String? pathFromPublicUrl(String url, {required String bucket}) {
    final marker = '/storage/v1/object/public/$bucket/';
    final i = url.indexOf(marker);
    if (i < 0) return null;
    return url.substring(i + marker.length);
  }

  // --------------------------------------------------------------------------
  // Internals
  // --------------------------------------------------------------------------

  Future<void> _uploadAny({
    required String path,
    required XFile file,
    required String contentType,
    required String toBucket,
  }) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await _client.storage.from(toBucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
    } else {
      await _client.storage.from(toBucket).upload(
        path,
        File(file.path),
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
    }
  }

  String _normalizedExt(String name) {
    final ext = p.extension(name).trim().toLowerCase();
    if (ext.isEmpty) return '.jpg';
    // ensure it begins with a dot
    return ext.startsWith('.') ? ext : '.$ext';
  }
}
