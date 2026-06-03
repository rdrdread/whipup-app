import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whipup/models/stock_category.dart';

part 'storage_config_provider.g.dart';

/// 재고함 이름 저장 키. 형식: "fridge:0=냉장고,fridge:1=냉장고 2"
const kContainerNamesKey = 'container_names';

/// 사용자가 보유한 재고함 슬롯 정보.
class StorageContainerSlot {
  const StorageContainerSlot({
    required this.location,
    required this.index,
    required this.totalCount,
    this.customName,
  });

  /// 보관 위치 (냉장고/냉동고/팬트리/양념 서랍장).
  final StorageLocation location;

  /// 같은 보관 위치 내 컨테이너 인덱스 (0-based).
  final int index;

  /// 해당 위치의 총 컨테이너 수.
  final int totalCount;

  /// 사용자 지정 이름 (null이면 기본 레이블 사용).
  final String? customName;

  /// 탭 레이블: 사용자 지정 이름 > 기본 위치명(번호 병기).
  String get label {
    if (customName != null && customName!.isNotEmpty) return customName!;
    return totalCount > 1 ? '${location.label} ${index + 1}' : location.label;
  }

  String get emoji => location.emoji;

  /// 저장 키: "fridge:0"
  String get storageKey => '${location.name}:$index';
}

/// 재고함 슬롯 목록 Provider.
///
/// [StorageSetupScreen]에서 저장한 `storage_config`와 `container_names`를 파싱하여
/// 활성화된 컨테이너 슬롯 목록을 반환한다.
/// 미설정 시 각 위치별 1개씩 기본값으로 반환.
@riverpod
Future<List<StorageContainerSlot>> storageContainerSlots(Ref ref) async {
  const storage = FlutterSecureStorage();
  final rawConfig = await storage.read(key: 'storage_config');
  final rawNames = await storage.read(key: kContainerNamesKey);

  // 개수 파싱
  final counts = <StorageLocation, int>{};
  if (rawConfig != null && rawConfig.isNotEmpty) {
    for (final entry in rawConfig.split(',')) {
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

  // 이름 파싱: "fridge:0=냉장고,fridge:1=냉장고 2"
  final names = <String, String>{};
  if (rawNames != null && rawNames.isNotEmpty) {
    for (final entry in rawNames.split(',')) {
      final eqIdx = entry.indexOf('=');
      if (eqIdx < 0) continue;
      names[entry.substring(0, eqIdx)] = entry.substring(eqIdx + 1);
    }
  }

  final slots = <StorageContainerSlot>[];
  for (final loc in StorageLocation.values) {
    final count = counts[loc] ?? 1;
    if (count <= 0) continue;
    for (var i = 0; i < count; i++) {
      final key = '${loc.name}:$i';
      slots.add(StorageContainerSlot(
        location: loc,
        index: i,
        totalCount: count,
        customName: names[key],
      ));
    }
  }
  return slots;
}
