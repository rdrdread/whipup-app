import 'package:flutter/material.dart';

/// BuildContext 편의 확장 메서드 모음.
extension BuildContextX on BuildContext {
  // ─── 테마 ─────────────────────────────────────────────────────────────────

  /// Material3 ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  // ─── SnackBar ─────────────────────────────────────────────────────────────

  /// 일반 Snackbar를 표시한다.
  void showSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  /// "후속 개발중" SnackBar를 표시한다.
  ///
  /// 아직 구현되지 않은 기능에 사용. (US 명세의 미구현 기능)
  void showComingSoon() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('🚧', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text(
              '후속 개발중이에요!',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  /// "되돌리기" 옵션이 있는 삭제 완료 Snackbar.
  void showDeletedWithUndo({
    required String itemName,
    required VoidCallback onUndo,
  }) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          '$itemName 삭제됨',
          style: const TextStyle(fontFamily: 'Pretendard'),
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: onUndo,
        ),
      ),
    );
  }
}
