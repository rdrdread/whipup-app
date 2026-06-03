import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/providers/recipe_providers.dart';
import 'package:whipup/theme/app_theme.dart';

/// 요리명 기반 레시피 생성 화면.
///
/// 홈의 빠른 레시피 추천 카드를 탭했을 때 진입한다.
/// 1. Isar 캐시에서 동일 제목 검색
/// 2. 없으면 Gemini로 즉시 생성
/// 3. 완료 후 [RecipeDetailScreen]으로 전환
class QuickRecipeScreen extends ConsumerStatefulWidget {
  const QuickRecipeScreen({
    super.key,
    required this.dishName,
    required this.emoji,
  });

  final String dishName;
  final String emoji;

  @override
  ConsumerState<QuickRecipeScreen> createState() => _QuickRecipeScreenState();
}

class _QuickRecipeScreenState extends ConsumerState<QuickRecipeScreen> {
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final repo = await ref.read(recipeRepositoryProvider.future);
      final result = await repo.generateByName(widget.dishName);
      if (!mounted) return;
      result.when(
        success: (r) => context.pushReplacement('/recipe/${r.id}', extra: r),
        failure: (e) => setState(() {
          _error = e.message;
          _loading = false;
        }),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading(context);
    return _buildError(context);
  }

  Widget _buildLoading(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              widget.dishName,
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              '레시피를 불러오는 중이에요...',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dishName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😥', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                '레시피를 불러오지 못했어요',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? '',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _load();
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
