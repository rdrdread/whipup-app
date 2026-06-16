/// Firebase Auth + Firestore 사용자 모델.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.householdId,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  /// 현재 속한 가구 ID. null이면 개인 모드.
  final String? householdId;

  bool get inHousehold => householdId != null;

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (householdId != null) 'householdId': householdId,
      };

  factory AppUser.fromFirestore(Map<String, dynamic> data) => AppUser(
        uid: data['uid'] as String,
        email: data['email'] as String? ?? '',
        displayName: data['displayName'] as String? ?? '',
        photoUrl: data['photoUrl'] as String?,
        householdId: data['householdId'] as String?,
      );

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    Object? householdId = _sentinel,
  }) =>
      AppUser(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        householdId:
            householdId == _sentinel ? this.householdId : householdId as String?,
      );
}

const _sentinel = Object();
