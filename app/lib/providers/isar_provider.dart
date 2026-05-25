import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whipup/repositories/impl/isar_achievement.dart';
import 'package:whipup/repositories/impl/isar_cached_recipe.dart';
import 'package:whipup/repositories/impl/isar_reward_stats.dart';
import 'package:whipup/repositories/impl/isar_stock_item.dart';

part 'isar_provider.g.dart';

/// Isar 데이터베이스 인스턴스 Provider.
///
/// `keepAlive: true` — 앱 생명주기 동안 단 하나의 Isar 인스턴스를 유지한다.
/// 스키마: StockItem, CachedRecipe, Achievement, RewardStats
///
/// Bridge 레이어가 사용하며, main.dart의 ProviderScope override로 주입된다.
@Riverpod(keepAlive: true)
Future<Isar> isarDb(Ref ref) async {
  final dir = await getApplicationDocumentsDirectory();
  if (Isar.instanceNames.isEmpty) {
    return await Isar.open(
      [
        IsarStockItemSchema,
        IsarCachedRecipeSchema,
        IsarAchievementSchema,
        IsarRewardStatsSchema,
      ],
      directory: dir.path,
      name: 'whipup_db',
    );
  }
  return Isar.getInstance('whipup_db')!;
}
