/// 앱 전역 상수 모음.
abstract final class AppConstants {
  // ─── App ──────────────────────────────────────────────
  static const String appName = 'WhipUp';

  // ─── Cache 우선순위 (CLAUDE.md §3.3 Caching Priority) ──
  /// Local → Server Cache → AI 순으로 레시피를 조회한다.
  static const List<String> recipeCachePriority = ['local', 'server', 'ai'];

  // ─── Isar ─────────────────────────────────────────────
  static const int isarSchemaVersion = 1;

  // ─── API ──────────────────────────────────────────────
  static const String baseUrl = 'https://whipup.synology.me';
  static const Duration networkTimeout = Duration(seconds: 15);
  static const int maxRetryCount = 3;
}
