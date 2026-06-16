import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whipup/models/app_user.dart';
import 'package:whipup/services/auth_service.dart';

/// [AuthService] 싱글턴 Provider.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Firebase Auth 상태 스트림.
///
/// null = 비로그인, User = 로그인됨.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// 현재 로그인된 [AppUser] 실시간 스트림.
///
/// Firestore 사용자 문서를 구독하므로 householdId 변경 시 자동 갱신된다.
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(authStateProvider).asData?.value;
  if (auth == null) return Stream.value(null);
  return ref.watch(authServiceProvider).watchAppUser(auth.uid);
});
