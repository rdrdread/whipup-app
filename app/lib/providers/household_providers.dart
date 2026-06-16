import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whipup/models/household.dart';
import 'package:whipup/providers/auth_providers.dart';
import 'package:whipup/services/household_service.dart';

/// [HouseholdService] 싱글턴 Provider.
final householdServiceProvider =
    Provider<HouseholdService>((ref) => HouseholdService());

/// 현재 사용자의 가구 실시간 스트림.
///
/// 가구에 속하지 않으면 null을 emit한다.
/// appUserProvider → householdId 변경 시 자동으로 새 가구 스트림으로 전환된다.
final currentHouseholdProvider = StreamProvider<Household?>((ref) {
  final appUser = ref.watch(appUserProvider).asData?.value;
  final householdId = appUser?.householdId;
  if (householdId == null) return Stream.value(null);
  return ref.watch(householdServiceProvider).watchHousehold(householdId);
});
