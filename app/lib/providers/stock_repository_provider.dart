import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whipup/providers/auth_providers.dart';
import 'package:whipup/providers/household_providers.dart';
import 'package:whipup/providers/isar_provider.dart';
import 'package:whipup/repositories/impl/firestore_stock_repository.dart';
import 'package:whipup/repositories/impl/isar_stock_repository.dart';
import 'package:whipup/repositories/stock_repository.dart';

part 'stock_repository_provider.g.dart';

/// [StockRepository] 인스턴스 Provider.
///
/// - 가구 미가입 (개인 모드): [IsarStockRepository] (로컬 Isar)
/// - 가구 가입 중: [FirestoreStockRepository] (Firestore 공유 재고)
///
/// currentHouseholdProvider 변경 시 자동으로 재생성된다.
@Riverpod(keepAlive: true)
Future<StockRepository> stockRepository(Ref ref) async {
  final isar = await ref.watch(isarDbProvider.future);

  final household = ref.watch(currentHouseholdProvider).asData?.value;
  final User? firebaseUser = ref.watch(authStateProvider).asData?.value;

  if (household != null && firebaseUser != null) {
    return FirestoreStockRepository(
      householdId: household.id,
      userId: firebaseUser.uid,
    );
  }

  return IsarStockRepository(isar);
}
