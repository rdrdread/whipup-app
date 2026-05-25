import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whipup/providers/isar_provider.dart';
import 'package:whipup/repositories/impl/isar_stock_repository.dart';
import 'package:whipup/repositories/stock_repository.dart';

part 'stock_repository_provider.g.dart';

/// [StockRepository] 인스턴스 Provider.
///
/// Isar 초기화 완료 후 [IsarStockRepository]를 생성한다.
/// UI와 Provider는 이 Provider를 통해 Repository에 접근한다.
///
/// 의존성 역전: [StockRepository] 인터페이스에만 의존함.
@Riverpod(keepAlive: true)
Future<StockRepository> stockRepository(Ref ref) async {
  final isar = await ref.watch(isarDbProvider.future);
  return IsarStockRepository(isar);
}
