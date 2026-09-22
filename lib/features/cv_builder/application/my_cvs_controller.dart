import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';

/// The user's saved CVs, keyed by UI language.
///
/// The first load may be served from cache; every later load bypasses it.
final myCvsProvider =
    AsyncNotifierProvider.autoDispose.family<MyCvsController, CvList, bool>(
  MyCvsController.new,
  // The screen has an explicit Retry; don't silently hammer a failing API.
  retry: (_, __) => null,
);

class MyCvsController extends AsyncNotifier<CvList> {
  MyCvsController(this.english);

  final bool english;
  bool _loadedOnce = false;
  final _deleting = <int>{};

  @override
  Future<CvList> build() async {
    final force = _loadedOnce;
    _loadedOnce = true;
    final data = await ref
        .read(mobileContentServiceProvider)
        .myCvs(english, force: force);
    return CvList.fromPayload(data, english: english);
  }

  /// Deletes [id] on the server, removes it from the list immediately, then
  /// refetches. A second call for an id already being deleted is ignored.
  /// Throws the API error so the caller can report it.
  Future<void> delete(int id) async {
    if (!_deleting.add(id)) return;
    try {
      await ref.read(cvApiServiceProvider).deleteGeneratedCv(id);
      MobileContentService.invalidateCvRelated();
      if (!ref.mounted) return;
      final current = state.value;
      if (current != null) state = AsyncData(current.without(id));
      ref.invalidateSelf();
    } finally {
      _deleting.remove(id);
    }
  }
}

/// Re-fetches (bypassing the cache) and completes once new data or an error
/// is in. Errors surface through the provider state.
Future<void> refreshMyCvs(WidgetRef ref, {required bool english}) async {
  try {
    final next = ref.refresh(myCvsProvider(english).future);
    await next;
  } catch (_) {}
}

/// The PDF link to open for [item] in [templateSlug].
///
/// Prefers a fresh link from the CV record (links can expire); falls back to
/// the one stored on the list row. Empty when neither is available.
Future<String> resolveCvDownloadUrl(
  CvApiService api,
  CvListItem item, {
  String? templateSlug,
}) async {
  final id = item.id;
  if (id != null) {
    try {
      final cv = await api.getGeneratedCv(id);
      final url = api.pdfUrlForTemplate(cv, templateSlug);
      if (url.isNotEmpty) return url;
    } catch (_) {
      // Offline or expired session: the stored link may still work.
    }
  }
  return withTemplateParam(item.storedPdfUrl, templateSlug);
}
