import 'package:flutter/material.dart';

/// 중앙 토스트 위젯 (1.5초 자동 소멸).
class _CenterToastWidget extends StatefulWidget {
  const _CenterToastWidget({required this.message});
  final String message;

  @override
  State<_CenterToastWidget> createState() => _CenterToastWidgetState();
}

class _CenterToastWidgetState extends State<_CenterToastWidget> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xE6222222),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            widget.message,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// BuildContext 편의 확장 메서드 모음.
extension BuildContextX on BuildContext {
  // ─── 테마 ─────────────────────────────────────────────────────────────────

  /// Material3 ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  // ─── Toast ────────────────────────────────────────────────────────────────

  /// 화면 중앙에 1.5초짜리 토스트를 표시한다. 루트 네비게이터 레벨로 띄워 화면 전환 후에도 유지.
  void showCenterToast(String message) {
    showDialog<void>(
      context: this,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => _CenterToastWidget(message: message),
    );
  }

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
