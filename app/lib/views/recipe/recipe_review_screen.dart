import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/services/points_service.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';

/// 레시피 완료 후 후기 작성 화면.
///
/// - 별점 선택 (1~5)
/// - 한 줄 텍스트 후기 (선택)
/// - 후기 제출 시 포인트 적립 + 애니메이션
/// - 건너뛰기 가능
class RecipeReviewScreen extends StatefulWidget {
  const RecipeReviewScreen({super.key, required this.recipeTitle});

  final String recipeTitle;

  @override
  State<RecipeReviewScreen> createState() => _RecipeReviewScreenState();
}

class _RecipeReviewScreenState extends State<RecipeReviewScreen>
    with SingleTickerProviderStateMixin {
  int _starRating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;
  int _earnedPoints = 0;
  int _totalPoints = 0;
  late final AnimationController _pointsAnim;
  late final Animation<double> _pointsFade;

  @override
  void initState() {
    super.initState();
    _pointsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pointsFade = CurvedAnimation(parent: _pointsAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _pointsAnim.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_starRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점을 선택해 주세요 ⭐')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final result = await PointsService.addReviewPoints();
    if (!mounted) return;

    setState(() {
      _earnedPoints = result.earned;
      _totalPoints = result.totalPoints;
      _submitted = true;
      _isSubmitting = false;
    });
    _pointsAnim.forward();

    // 2초 후 자동으로 나가기
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('후기 작성', style: AppTheme.screenTitleStyle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _submitted ? _buildSuccess(cs, tt) : _buildForm(cs, tt),
        ),
      ),
    );
  }

  Widget _buildForm(ColorScheme cs, TextTheme tt) {
    final nextTier = PointsService.nextTier(0); // 현재 포인트 무관하게 안내

    return ListView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        // ─── 헤더 ────────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              const TwemojiIcon('🎉', size: 56),
              const SizedBox(height: 12),
              Text(
                '완성했어요!',
                style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                widget.recipeTitle,
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ─── 별점 ────────────────────────────────────────────────
        Text(
          '맛은 어땠나요?',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final filled = i < _starRating;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _starRating = i + 1);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 42,
                  color: filled ? AppTheme.warningAmber : cs.outlineVariant,
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 28),

        // ─── 텍스트 후기 ──────────────────────────────────────────
        Text(
          '한 줄 후기 (선택)',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          maxLines: 3,
          maxLength: 100,
          style: const TextStyle(fontFamily: 'Pretendard'),
          decoration: InputDecoration(
            hintText: '맛있었어요! 다음엔 파채도 올려봐야겠어요 😋',
            hintStyle: TextStyle(color: cs.onSurfaceVariant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ─── 포인트 안내 ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const TwemojiIcon('💎', size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '후기 작성 시 +${PointsService.pointsPerReview}P 적립!',
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    if (nextTier != null)
                      Text(
                        '${nextTier.points}P 달성 시 ${nextTier.emoji} ${nextTier.title}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ─── 버튼 ────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '후기 작성하기',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: Text(
              '건너뛰기',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(ColorScheme cs, TextTheme tt) {
    final next = PointsService.nextTier(_totalPoints);
    final maxPoints = next?.points ?? PointsService.rewardTiers.last.points;
    final progress = (_totalPoints / maxPoints).clamp(0.0, 1.0);

    return FadeTransition(
      key: const ValueKey('success'),
      opacity: _pointsFade,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TwemojiIcon('💎', size: 64),
            const SizedBox(height: 20),
            Text(
              '+$_earnedPoints 포인트 적립!',
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '누적 $_totalPoints P',
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            // 포인트 프로그레스 바
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
            const SizedBox(height: 8),
            if (next != null)
              Text(
                '${next.emoji} ${next.title}까지 ${next.points - _totalPoints}P 남았어요',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              )
            else
              Text(
                '🎁 모든 리워드를 달성했어요!',
                style: tt.bodyMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
