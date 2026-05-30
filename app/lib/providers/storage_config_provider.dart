import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whipup/models/stock_category.dart';

part 'storage_config_provider.g.dart';

/// 사용자가 보유한 재고함 슬롯 정보.
class StorageContainerSlot {
  const StorageContainerSlot({
    required this.location,
    required this.index,
    required this.totalCount,
  });

  /// 보관 위치 (냉장고/냉동고/팬트리/양념 서랍장).
  final StorageLocation location;

  /// 같은 보관 위치 내 컨테이너 인덱스 (0-based).
  final int index;

  /// 해당 위치의 총 컨테이너 수.
  final int totalCount;

  /// 탭 레이블: 1개면 위치명만, 2개 이상이면 번호 병기.
  String get label => totalCount > 1 ? '${location.label} ${index + 1}' : location.label;

  String get emoji => location.emoji;
}

/// 재고함 슬롯 목록 Provider.
///
/// [StorageSetupScreen]에서 저장한 `storage_config` 값을 파싱하여
/// 활성화된 컨테이너 슬롯 목록을 반환한다.
/// 미설정 시 각 위치별 1개씩 기본값으로 반환.
@riverpod
Future<List<StorageContainerSlot>> storageContainerSlots(Ref ref) async {
  const storage = FlutterSecureStorage();
  final raw = await storage.read(key: 'storage_config');

  final counts = <StorageLocation, int>{};
  if (raw != null && raw.isNotEmpty) {
    for (final entry in raw.split(',')) {
      final parts = entry.split(':');
      if (parts.length != 2) continue;
      final count = int.tryParse(parts[1]);
      if (count == null) continue;
      final loc = StorageLocation.values
          .where((l) => l.name == parts[0])
          .firstOrNull;
      if (loc != null) counts[loc] = count;
    }
  }

  final slots = <StorageContainerSlot>[];
  for (final loc in StorageLocation.values) {
    final count = counts[loc] ?? 1;
    if (count <= 0) continue;
    for (var i = 0; i < count; i++) {
      slots.add(StorageContainerSlot(location: loc, index: i, totalCount: count));
    }
  }
  return slots;
}
