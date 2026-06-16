import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whipup/models/household.dart';
import 'package:whipup/providers/auth_providers.dart';
import 'package:whipup/providers/household_providers.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';

/// 가구 관리 화면.
///
/// 설정 화면의 "가구 공유" 섹션에서 push로 진입한다.
/// - 가구 미가입: 만들기 / 참여하기 선택
/// - 가구 가입 중: 초대 코드 표시 + 구성원 목록 + 탈퇴 버튼
class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(currentHouseholdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('가구 공유', style: AppTheme.screenTitleStyle),
        centerTitle: false,
        elevation: 0,
      ),
      body: householdAsync.when(
        data: (household) => household == null
            ? const _NoHouseholdView()
            : _HouseholdView(household: household),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
    );
  }
}

// ─── 가구 미가입 화면 ─────────────────────────────────────────────────────────

class _NoHouseholdView extends ConsumerWidget {
  const _NoHouseholdView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Center(child: TwemojiIcon('🏠', size: 64)),
          const SizedBox(height: 20),
          Text(
            '함께 쓰는 냉장고',
            textAlign: TextAlign.center,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '가족·룸메이트와 재고 목록을 실시간으로\n함께 조회하고 수정할 수 있어요.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: () => _showCreateDialog(context, ref),
            icon: const Icon(Icons.add_home_rounded),
            label: const Text('가구 만들기'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showJoinDialog(context, ref),
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('초대 코드로 참여하기'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController(text: '우리 집');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('가구 만들기'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '가구 이름',
            hintText: '예: 우리 집, 자취방, 기숙사',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('만들기'),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (!context.mounted) return;

    try {
      final appUser = ref.read(appUserProvider).asData?.value;
      if (appUser == null) return;

      await ref.read(householdServiceProvider).createHousehold(
            uid: appUser.uid,
            email: appUser.email,
            displayName: appUser.displayName,
            photoUrl: appUser.photoUrl,
            name: nameController.text.trim().isEmpty ? '우리 집' : nameController.text.trim(),
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가구를 만들었어요! 초대 코드를 공유해 보세요 🏠')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가구 생성 실패: $e')),
        );
      }
    }
  }

  Future<void> _showJoinDialog(BuildContext context, WidgetRef ref) async {
    final codeController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('초대 코드로 참여'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: '6자리 초대 코드',
            hintText: 'AB12CD',
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('참여하기'),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (!context.mounted) return;

    try {
      final appUser = ref.read(appUserProvider).asData?.value;
      if (appUser == null) return;

      final household = await ref.read(householdServiceProvider).joinByInviteCode(
            code: codeController.text.trim(),
            uid: appUser.uid,
            email: appUser.email,
            displayName: appUser.displayName,
            photoUrl: appUser.photoUrl,
          );

      if (!context.mounted) return;
      if (household == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('유효하지 않은 초대 코드예요. 다시 확인해 주세요.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${household.name}에 참여했어요! 🎉')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('참여 실패: $e')),
        );
      }
    }
  }
}

// ─── 가구 가입 중 화면 ────────────────────────────────────────────────────────

class _HouseholdView extends ConsumerWidget {
  const _HouseholdView({required this.household});

  final Household household;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final appUser = ref.watch(appUserProvider).asData?.value;
    final isOwner = appUser?.uid == household.ownerId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── 가구 이름 ─────────────────────────────────────────────
        Row(
          children: [
            const TwemojiIcon('🏠', size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                household.name,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ─── 초대 코드 카드 ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '초대 코드',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    household.inviteCode,
                    style: tt.headlineMedium?.copyWith(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: cs.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    tooltip: '복사',
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: household.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('초대 코드를 복사했어요'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: '코드 재생성',
                      onPressed: () async {
                        final newCode = await ref
                            .read(householdServiceProvider)
                            .refreshInviteCode(household.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('새 코드: $newCode')),
                          );
                        }
                      },
                    ),
                ],
              ),
              Text(
                '이 코드를 가족·룸메이트에게 공유하세요',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ─── 구성원 목록 ───────────────────────────────────────────
        Text('구성원 (${household.members.length}명)',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...household.members.map(
          (member) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: CircleAvatar(
              backgroundColor: cs.secondaryContainer,
              backgroundImage: member.photoUrl != null
                  ? NetworkImage(member.photoUrl!)
                  : null,
              child: member.photoUrl == null
                  ? Text(
                      member.displayName.isNotEmpty
                          ? member.displayName[0].toUpperCase()
                          : '?',
                      style: tt.titleMedium?.copyWith(
                          color: cs.onSecondaryContainer),
                    )
                  : null,
            ),
            title: Text(member.displayName),
            subtitle: Text(member.email,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            trailing: member.uid == household.ownerId
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.flameOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '방장',
                      style: tt.labelSmall?.copyWith(
                          color: AppTheme.flameOrange,
                          fontWeight: FontWeight.w700),
                    ),
                  )
                : null,
          ),
        ),

        const SizedBox(height: 32),

        // ─── 탈퇴 버튼 ────────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: () => _confirmLeave(context, ref, appUser?.uid ?? ''),
          icon: const Icon(Icons.exit_to_app_rounded),
          label: const Text('가구 탈퇴하기'),
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.error,
            side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLeave(
      BuildContext context, WidgetRef ref, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('가구 탈퇴'),
        content: const Text('탈퇴하면 공유 재고에 접근할 수 없어요.\n개인 재고로 전환됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(householdServiceProvider).leaveHousehold(
            uid: uid,
            householdId: household.id,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가구에서 탈퇴했어요. 이제 개인 모드로 전환됩니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('탈퇴 실패: $e')));
      }
    }
  }
}
