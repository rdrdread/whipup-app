import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whipup/models/household.dart';

/// Firestore 기반 가구 관리 서비스.
///
/// 가구 생성·참여·탈퇴 및 초대 코드 검증을 담당한다.
class HouseholdService {
  HouseholdService() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ─── 가구 생성 ────────────────────────────────────────────────────────────

  /// 새 가구를 생성하고 사용자를 소유자로 등록한다.
  Future<Household> createHousehold({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
    String name = '우리 집',
  }) async {
    final code = _generateInviteCode();
    final now = DateTime.now();

    final member = HouseholdMember(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      joinedAt: now,
    );

    final ref = _db.collection('households').doc();
    final household = Household(
      id: ref.id,
      name: name,
      ownerId: uid,
      inviteCode: code,
      members: [member],
      createdAt: now,
    );

    final batch = _db.batch();
    batch.set(ref, household.toFirestore());
    batch.update(_db.collection('users').doc(uid), {'householdId': ref.id});
    await batch.commit();

    return household;
  }

  // ─── 가구 참여 ────────────────────────────────────────────────────────────

  /// 초대 코드로 가구에 참여한다.
  ///
  /// 코드가 유효하지 않으면 null을 반환한다.
  Future<Household?> joinByInviteCode({
    required String code,
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final query = await _db
        .collection('households')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final household = Household.fromFirestore(doc.id, doc.data());

    // 이미 구성원이면 그냥 반환
    if (household.members.any((m) => m.uid == uid)) return household;

    final newMember = HouseholdMember(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      joinedAt: DateTime.now(),
    );

    final updatedMembers = [...household.members, newMember]
        .map((m) => m.toMap())
        .toList();

    final batch = _db.batch();
    batch.update(doc.reference, {'members': updatedMembers});
    batch.update(_db.collection('users').doc(uid), {'householdId': doc.id});
    await batch.commit();

    return Household.fromFirestore(doc.id, {
      ...doc.data(),
      'members': updatedMembers,
    });
  }

  // ─── 가구 탈퇴 ────────────────────────────────────────────────────────────

  /// 가구에서 탈퇴한다.
  ///
  /// 마지막 구성원이 탈퇴하면 가구 문서를 삭제한다.
  Future<void> leaveHousehold({
    required String uid,
    required String householdId,
  }) async {
    final doc = await _db.collection('households').doc(householdId).get();
    if (!doc.exists) {
      await _db.collection('users').doc(uid).update({'householdId': FieldValue.delete()});
      return;
    }

    final household = Household.fromFirestore(doc.id, doc.data()!);
    final remaining = household.members.where((m) => m.uid != uid).toList();

    final batch = _db.batch();

    if (remaining.isEmpty) {
      // 마지막 멤버 — 가구 문서 삭제
      batch.delete(doc.reference);
    } else {
      final newOwner = household.ownerId == uid ? remaining.first.uid : household.ownerId;
      batch.update(doc.reference, {
        'members': remaining.map((m) => m.toMap()).toList(),
        'ownerId': newOwner,
      });
    }
    batch.update(_db.collection('users').doc(uid), {'householdId': FieldValue.delete()});
    await batch.commit();
  }

  // ─── 초대 코드 재생성 ─────────────────────────────────────────────────────

  /// 초대 코드를 새로 생성한다.
  Future<String> refreshInviteCode(String householdId) async {
    final code = _generateInviteCode();
    await _db.collection('households').doc(householdId).update({'inviteCode': code});
    return code;
  }

  // ─── 스트림 ──────────────────────────────────────────────────────────────

  /// 특정 가구의 실시간 스트림.
  Stream<Household?> watchHousehold(String householdId) {
    return _db.collection('households').doc(householdId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return Household.fromFirestore(doc.id, data);
    });
  }

  // ─── 유틸 ─────────────────────────────────────────────────────────────────

  /// 6자리 영숫자 초대 코드를 생성한다 (예: "AB12CD").
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
