import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../analysis/domain/models/analysis_result.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/history_service.dart';
import '../../domain/models/analysis_record.dart';

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService(Supabase.instance.client);
});

class HistoryNotifier extends AsyncNotifier<List<AnalysisRecord>> {
  @override
  Future<List<AnalysisRecord>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return ref.read(historyServiceProvider).fetchHistory(user.id);
  }

  Future<void> save(AnalysisResult result) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(historyServiceProvider).saveAnalysis(
      data: AnalysisRecord.toDatabaseMap(result, user.id),
    );
    ref.invalidateSelf();
  }

  Future<void> delete(String recordId) async {
    await ref.read(historyServiceProvider).deleteRecord(recordId);
    ref.invalidateSelf();
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<AnalysisRecord>>(
  HistoryNotifier.new,
);
