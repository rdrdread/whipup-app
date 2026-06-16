/// 가구(공유 재고 그룹) 모델.
class Household {
  const Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.members,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;

  /// 6자리 영숫자 초대 코드 (예: "AB12CD").
  final String inviteCode;
  final List<HouseholdMember> members;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'ownerId': ownerId,
        'inviteCode': inviteCode,
        'members': members.map((m) => m.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Household.fromFirestore(String id, Map<String, dynamic> data) =>
      Household(
        id: id,
        name: data['name'] as String? ?? '',
        ownerId: data['ownerId'] as String? ?? '',
        inviteCode: data['inviteCode'] as String? ?? '',
        members: (data['members'] as List<dynamic>? ?? [])
            .map((m) => HouseholdMember.fromMap(m as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// 가구 구성원 정보.
class HouseholdMember {
  const HouseholdMember({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.joinedAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime joinedAt;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory HouseholdMember.fromMap(Map<String, dynamic> m) => HouseholdMember(
        uid: m['uid'] as String,
        email: m['email'] as String? ?? '',
        displayName: m['displayName'] as String? ?? '',
        photoUrl: m['photoUrl'] as String?,
        joinedAt:
            DateTime.tryParse(m['joinedAt'] as String? ?? '') ?? DateTime.now(),
      );
}
