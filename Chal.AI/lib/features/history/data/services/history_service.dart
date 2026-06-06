import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/api_config.dart';
import '../../domain/models/analysis_record.dart';

class HistoryService {
  final SupabaseClient _client;

  HistoryService(this._client);

  Future<void> saveAnalysis({required Map<String, dynamic> data}) async {
    try {
      await _client.from('rice_analysis_records').insert(data);
    } catch (e) {
      debugPrint('saveAnalysis failed: $e');
      throw Exception(
        'Failed to save analysis. Please check your connection and try again.',
      );
    }
  }

  /// Update specific fields of an existing record (used by the background
  /// poller when a RunPod async job finishes or fails).
  Future<void> updateRecord(
    String recordId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client
          .from('rice_analysis_records')
          .update(data)
          .eq('id', recordId);
    } catch (e) {
      debugPrint('updateRecord failed: $e');
      throw Exception(
        'Failed to update analysis record. Please check your connection.',
      );
    }
  }

  Future<List<AnalysisRecord>> fetchHistory(String userId) async {
    try {
      final rows = await _client
          .from('rice_analysis_records')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return (rows as List)
          .map((r) => AnalysisRecord.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchHistory failed: $e');
      throw Exception(
        'Failed to load history. Please check your connection and try again.',
      );
    }
  }

  Future<void> deleteRecord(String recordId) async {
    try {
      await _client
          .from('rice_analysis_records')
          .delete()
          .eq('id', recordId);
    } catch (e) {
      debugPrint('deleteRecord failed: $e');
      throw Exception('Failed to delete record. Please try again.');
    }
  }

  Future<String?> uploadImage({
    required String userId,
    required String analysisId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final path = '$userId/$analysisId/$filename';
    try {
      await _client.storage
          .from(ApiConfig.supabaseUploadBucket)
          .uploadBinary(path, bytes,
              fileOptions: const FileOptions(upsert: true));
      return path;
    } catch (e) {
      debugPrint('Image upload failed (non-fatal): $e');
      return null;
    }
  }

  Future<Uint8List?> downloadImage(String storagePath) async {
    try {
      return await _client.storage
          .from(ApiConfig.supabaseUploadBucket)
          .download(storagePath);
    } catch (e) {
      debugPrint('Image download failed: $e');
      return null;
    }
  }
}
