import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/models/recipe_type.dart';
import 'package:whipup/providers/recipe_providers.dart';
import 'package:whipup/theme/app_theme.dart';

/// 레시피 편집 화면.
///
/// 로컬 캐시 + 백엔드 서버에 저장된 레시피를 수정한다.
/// 편집 가능 항목: 설명, 이미지 URL, 재료 목록, 조리 단계
class RecipeEditScreen extends ConsumerStatefulWidget {
  const RecipeEditScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends ConsumerState<RecipeEditScreen> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _imageCtrl;
  late List<_IngredientRow> _ingredients;
  late List<_StepRow> _steps;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _descCtrl = TextEditingController(text: r.description);
    _imageCtrl = TextEditingController(text: r.imageUrl ?? '');
    _ingredients = r.ingredients
        .map((i) => _IngredientRow(
              nameCtrl: TextEditingController(text: i.name),
              amountCtrl: TextEditingController(text: i.amount),
              unitCtrl: TextEditingController(text: i.unit),
              isOptional: i.isOptional,
            ))
        .toList();
    _steps = r.steps
        .map((s) => _StepRow(
              descCtrl: TextEditingController(text: s.description),
              tipCtrl: TextEditingController(text: s.tip ?? ''),
              phase: s.phase,
              stepNumber: s.stepNumber,
              durationSeconds: s.durationSeconds,
            ))
        .toList();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _imageCtrl.dispose();
    for (final row in _ingredients) {
      row.nameCtrl.dispose();
      row.amountCtrl.dispose();
      row.unitCtrl.dispose();
    }
    for (final row in _steps) {
      row.descCtrl.dispose();
      row.tipCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.recipe.copyWith(
        description: _descCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        ingredients: _ingredients
            .map((row) => RecipeIngredient(
                  name: row.nameCtrl.text.trim(),
                  amount: row.amountCtrl.text.trim(),
                  unit: row.unitCtrl.text.trim(),
                  isOptional: row.isOptional,
                ))
            .where((i) => i.name.isNotEmpty)
            .toList(),
        steps: _steps
            .asMap()
            .entries
            .map((e) => RecipeStep(
                  stepNumber: e.value.stepNumber,
                  phase: e.value.phase,
                  description: e.value.descCtrl.text.trim(),
                  tip: e.value.tipCtrl.text.trim().isEmpty
                      ? null
                      : e.value.tipCtrl.text.trim(),
                  durationSeconds: e.value.durationSeconds,
                ))
            .toList(),
      );

      final repo = await ref.read(recipeRepositoryProvider.future);
      final result = await repo.updateRecipe(updated);

      if (!mounted) return;
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('레시피가 저장되었어요!')),
          );
          context.pop(updated);
        },
        failure: (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('저장 실패: ${e.message}'),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(_IngredientRow(
        nameCtrl: TextEditingController(),
        amountCtrl: TextEditingController(),
        unitCtrl: TextEditingController(),
        isOptional: false,
      ));
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index].nameCtrl.dispose();
      _ingredients[index].amountCtrl.dispose();
      _ingredients[index].unitCtrl.dispose();
      _ingredients.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          widget.recipe.title,
          style: AppTheme.screenTitleStyle,
        ),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text(
                    '저장',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          // ─── 기본 정보 ──────────────────────────────────────────────
          _SectionHeader(title: '기본 정보'),
          _Card(
            child: Column(
              children: [
                _FieldRow(
                  label: '설명',
                  child: TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    style: _fieldStyle,
                    decoration: _fieldDecoration('요리 소개'),
                  ),
                ),
                const Divider(height: 1),
                _FieldRow(
                  label: '이미지 URL',
                  child: TextField(
                    controller: _imageCtrl,
                    style: _fieldStyle,
                    decoration: _fieldDecoration('https://...'),
                  ),
                ),
              ],
            ),
          ),

          // ─── 재료 ───────────────────────────────────────────────────
          _SectionHeader(title: '재료'),
          _Card(
            child: Column(
              children: [
                for (var i = 0; i < _ingredients.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _IngredientEditor(
                    row: _ingredients[i],
                    onRemove: () => _removeIngredient(i),
                    onOptionalChanged: (v) => setState(
                      () => _ingredients[i].isOptional = v,
                    ),
                  ),
                ],
                const Divider(height: 1),
                TextButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('재료 추가'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // ─── 조리 단계 ──────────────────────────────────────────────
          _SectionHeader(title: '조리 단계'),
          for (var i = 0; i < _steps.length; i++)
            _StepEditor(
              step: _steps[i],
              index: i,
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static const _fieldStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
  );

  static InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          color: AppTheme.textDisabled,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      );
}

// ─── 보조 데이터 클래스 ────────────────────────────────────────────────────────

class _IngredientRow {
  _IngredientRow({
    required this.nameCtrl,
    required this.amountCtrl,
    required this.unitCtrl,
    required this.isOptional,
  });

  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final TextEditingController unitCtrl;
  bool isOptional;
}

class _StepRow {
  const _StepRow({
    required this.descCtrl,
    required this.tipCtrl,
    required this.phase,
    required this.stepNumber,
    this.durationSeconds,
  });

  final TextEditingController descCtrl;
  final TextEditingController tipCtrl;
  final CookingPhase phase;
  final int stepNumber;
  final int? durationSeconds;
}

// ─── 공통 레이아웃 위젯 ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.textStrong,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppTheme.dividerSubtle, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: AppTheme.iconSubtle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── 재료 편집 행 ──────────────────────────────────────────────────────────────

class _IngredientEditor extends StatelessWidget {
  const _IngredientEditor({
    required this.row,
    required this.onRemove,
    required this.onOptionalChanged,
  });

  final _IngredientRow row;
  final VoidCallback onRemove;
  final ValueChanged<bool> onOptionalChanged;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontFamily: 'Pretendard', fontSize: 14);
    InputDecoration dec(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: AppTheme.textDisabled),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextField(controller: row.nameCtrl, style: style, decoration: dec('재료명')),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(controller: row.amountCtrl, style: style, decoration: dec('양')),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(controller: row.unitCtrl, style: style, decoration: dec('단위')),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppTheme.iconSubtle,
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── 조리 단계 편집 카드 ────────────────────────────────────────────────────────

class _StepEditor extends StatelessWidget {
  const _StepEditor({required this.step, required this.index});

  final _StepRow step;
  final int index;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontFamily: 'Pretendard', fontSize: 14);
    InputDecoration dec(String hint, {int? maxLines}) => InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: AppTheme.textDisabled),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${step.stepNumber}',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    step.phase.label,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.iconSubtle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: step.descCtrl,
                maxLines: 3,
                style: style,
                decoration: dec('단계 설명'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: step.tipCtrl,
                style: style.copyWith(color: AppTheme.iconSubtle, fontSize: 13),
                decoration: dec('💡 팁 (선택)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
