import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/core/extensions/build_context_extensions.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/providers/reward_providers.dart';
import 'package:whipup/providers/storage_config_provider.dart';
import 'package:whipup/providers/stock_providers.dart';
import 'package:whipup/providers/stock_repository_provider.dart';
import 'package:whipup/services/sub_category_service.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';

/// 마지막으로 선택한 보관 위치 — 앱 세션 내 유지.
class _LastStorage {
  static StorageLocation location = StorageLocation.fridge;
  static int containerIndex = 0;
}

/// 재료 추가/수정 화면.
///
/// - 카테고리 → 서브 카테고리 → 부위/종류 캐스케이딩 선택 (US-6)
/// - 재료명 자동 입력 (AC-10)
/// - 단위 자동 설정 (AC-11)
/// - 사용자 수동 변경 가능 (AC-12)
/// - 폼 유효성 검사 (AC-8)
///
/// 레이아웃: `docs/core/screen_layout.md §3.3`
class StockAddScreen extends ConsumerStatefulWidget {
  const StockAddScreen({
    super.key,
    this.itemId,
    this.initialStorageLocationName,
    this.initialContainerIndex = 0,
    this.initialCategoryName,
  });

  final int? itemId;
  final String? initialStorageLocationName;
  final int initialContainerIndex;
  final String? initialCategoryName;

  @override
  ConsumerState<StockAddScreen> createState() => _StockAddScreenState();
}

class _StockAddScreenState extends ConsumerState<StockAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: '개');

  StockCategory? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedPart;
  StorageLocation _selectedLocation = StorageLocation.fridge;
  int _containerIndex = 0;
  DateTime? _expiryDate;
  bool _isUnitAutoSet = false;
  bool _isNameAutoSet = false;
  bool _isSaving = false;

  StockItem? _existingItem;

  @override
  void initState() {
    super.initState();
    if (widget.initialStorageLocationName != null) {
      final loc = StorageLocation.values.where(
        (l) => l.name == widget.initialStorageLocationName,
      );
      if (loc.isNotEmpty) _selectedLocation = loc.first;
      _containerIndex = widget.initialContainerIndex;
    } else {
      // 마지막으로 사용한 보관 위치 복원
      _selectedLocation = _LastStorage.location;
      _containerIndex = _LastStorage.containerIndex;
    }
    if (widget.initialCategoryName != null) {
      final cat = StockCategory.values.where(
        (c) => c.name == widget.initialCategoryName,
      );
      if (cat.isNotEmpty) {
        _selectedCategory = cat.first;
        _unitController.text = SubCategoryService.getDefaultUnit(cat.first);
        _isUnitAutoSet = true;
      }
    }
    if (widget.itemId != null) _loadExistingItem();
  }

  Future<void> _loadExistingItem() async {
    final repository = await ref.read(stockRepositoryProvider.future);
    final result = await repository.getById(widget.itemId!);
    result.when(
      success: (item) {
        if (mounted) {
          setState(() {
            _existingItem = item;
            _nameController.text = item.name;
            _quantityController.text = item.quantity % 1 == 0
                ? item.quantity.toInt().toString()
                : item.quantity.toString();
            _unitController.text = item.unit;
            _selectedCategory = item.category;
            _selectedSubCategory = item.subCategory;
            _selectedPart = item.itemPart;
            _selectedLocation = item.storageLocation;
            _containerIndex = item.containerIndex;
            _expiryDate = item.expiryDate;
          });
        }
      },
      failure: (_) {
        if (mounted) context.pop();
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _onCategorySelected(StockCategory category) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
      _selectedSubCategory = null;
      _selectedPart = null;
      final unit = SubCategoryService.getDefaultUnit(category);
      _unitController.text = unit;
      _isUnitAutoSet = true;
      if (_isNameAutoSet) {
        _nameController.text = '';
        _isNameAutoSet = false;
      }
    });
  }

  void _onSubCategorySelected(String subCategory) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSubCategory = subCategory;
      _selectedPart = null;
      final unit = SubCategoryService.getDefaultUnit(
        _selectedCategory!,
        subCategory: subCategory,
      );
      _unitController.text = unit;
      _isUnitAutoSet = true;
      _nameController.text = SubCategoryService.buildAutoName(subCategory: subCategory);
      _isNameAutoSet = true;
      if (widget.itemId == null) {
        final qty = SubCategoryService.getDefaultQuantity(
          _selectedCategory!,
          subCategory: subCategory,
        );
        _quantityController.text =
            qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
        // 추천 유통기한 자동 선택 (수정 모드 제외)
        final days = SubCategoryService.getDefaultExpiryDays(
          _selectedCategory!,
          subCategory: subCategory,
        );
        _expiryDate = DateTime.now().add(Duration(days: days));
      }
    });
  }

  void _onPartSelected(String part) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPart = part;
      if (_selectedSubCategory != null) {
        _nameController.text = SubCategoryService.buildAutoName(
          subCategory: _selectedSubCategory!,
          itemPart: part,
        );
        _isNameAutoSet = true;
      }
    });
  }

  void _adjustQuantity(double delta) {
    HapticFeedback.selectionClick();
    final current = double.tryParse(_quantityController.text) ?? 0;
    final step = delta.abs();
    double next;
    if (step >= 10) {
      // 무게·부피 단위(g, ml 등): 배수로 스냅해서 0으로 끝나게 함
      next = delta > 0
          ? ((current / step).floor() + 1) * step
          : ((current / step).ceil() - 1) * step;
    } else {
      next = current + delta;
    }
    next = next.clamp(0.0, 9999.0);
    setState(() {
      _quantityController.text =
          next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(1);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final quantityStr = _quantityController.text.trim();
    final unit = _unitController.text.trim();

    if (_selectedCategory == null) {
      context.showSnackBar('카테고리를 선택해 주세요');
      return;
    }

    final quantity = double.tryParse(quantityStr);
    if (quantity == null) {
      context.showSnackBar('수량을 올바르게 입력해 주세요');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = await ref.read(stockRepositoryProvider.future);

      final item = StockItem(
        id: _existingItem?.id ?? 0,
        name: name,
        category: _selectedCategory!,
        subCategory: _selectedSubCategory,
        itemPart: _selectedPart,
        storageLocation: _selectedLocation,
        containerIndex: _containerIndex,
        quantity: quantity,
        unit: unit,
        expiryDate: _expiryDate,
        addedAt: _existingItem?.addedAt ?? DateTime.now(),
      );

      final result = widget.itemId != null
          ? await repository.update(item)
          : await repository.add(item);

      if (!mounted) return;

      result.when(
        success: (_) {
          HapticFeedback.lightImpact();
          // 마지막 보관 위치 저장
          _LastStorage.location = _selectedLocation;
          _LastStorage.containerIndex = _containerIndex;
          if (widget.itemId == null) {
            handleStockAdded(ref);
            ref.invalidate(stockSummaryProvider);
          }
          context.showCenterToast(
            widget.itemId != null ? '재료가 수정되었어요 ✅' : '재료가 추가되었어요 🎉',
          );
          context.pop();
        },
        failure: (err) {
          context.showSnackBar('저장 실패: ${err.message}');
        },
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.itemId != null;
    final partLabel = _selectedCategory == StockCategory.meat ? '부위' : '종류';
    final unit = _unitController.text;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? '재료 수정' : '재료 추가',
          style: AppTheme.screenTitleStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '저장',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ─── 1. 보관 위치 (최상단) ─────────────────────────────────
            _SectionLabel(label: '보관 위치', required: true),
            const SizedBox(height: 8),
            _LocationSelector(
              selectedLocation: _selectedLocation,
              selectedContainerIndex: _containerIndex,
              onSelected: (loc, containerIndex) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedLocation = loc;
                  _containerIndex = containerIndex;
                });
              },
            ),

            // ─── 2. 카테고리 ────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionLabel(label: '카테고리', required: true),
            const SizedBox(height: 8),
            _CategorySelector(
              selectedCategory: _selectedCategory,
              onSelected: _onCategorySelected,
            ),

            // ─── 3. 서브 카테고리 ─────────────────────────────────────
            if (_selectedCategory != null) ...[
              const SizedBox(height: 20),
              _SectionLabel(label: '종류'),
              const SizedBox(height: 8),
              _SubCategorySelector(
                category: _selectedCategory!,
                selectedSubCategory: _selectedSubCategory,
                onSelected: _onSubCategorySelected,
              ),
            ],

            // ─── 4. 부위/종류 (카테고리에 따라 라벨 변경) ──────────────
            if (_selectedSubCategory != null &&
                SubCategoryService.getParts(_selectedSubCategory!).isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionLabel(label: partLabel),
              const SizedBox(height: 8),
              _PartSelector(
                subCategory: _selectedSubCategory!,
                selectedPart: _selectedPart,
                onSelected: _onPartSelected,
              ),
            ],

            // ─── 5. 재료명 ────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionLabel(label: '재료명', required: true),
            const SizedBox(height: 8),
            _NameField(
              controller: _nameController,
              isAutoSet: _isNameAutoSet,
              onChanged: (val) {
                if (_isNameAutoSet && val != _nameController.text) {
                  setState(() => _isNameAutoSet = false);
                }
              },
            ),

            // ─── 6. 수량 + 단위 ──────────────────────────────────────
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: '수량', required: true),
                      const SizedBox(height: 8),
                      _QuantityWithStepper(
                        controller: _quantityController,
                        unit: unit,
                        onStep: _adjustQuantity,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _SectionLabel(label: '단위'),
                          if (_isUnitAutoSet) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '자동',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      _UnitField(
                        controller: _unitController,
                        onUnitSelected: (u) {
                          setState(() {
                            _unitController.text = u;
                            _isUnitAutoSet = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ─── 7. 유통기한 ─────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionLabel(label: '유통기한 (선택)'),
            const SizedBox(height: 8),
            _ExpiryDatePicker(
              selectedDate: _expiryDate,
              category: _selectedCategory,
              subCategory: _selectedSubCategory,
              onDateSelected: (date) {
                setState(() => _expiryDate = date);
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── 재사용 컴포넌트 ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (required)
          Text(
            ' *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
          ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selectedCategory,
    required this.onSelected,
  });

  final StockCategory? selectedCategory;
  final void Function(StockCategory) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: StockCategory.values.map((cat) {
        final isSelected = selectedCategory == cat;
        return GestureDetector(
          onTap: () => onSelected(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? null
                  : Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 0.5,
                    ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TwemojiIcon(cat.emoji, size: 16),
                const SizedBox(width: 6),
                Text(
                  cat.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SubCategorySelector extends StatelessWidget {
  const _SubCategorySelector({
    required this.category,
    required this.selectedSubCategory,
    required this.onSelected,
  });

  final StockCategory category;
  final String? selectedSubCategory;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    final subCategories = SubCategoryService.getSubCategories(category);
    if (subCategories.isEmpty) {
      return Text(
        '이 카테고리는 추가 분류 없이 직접 입력해 주세요.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: subCategories.map((sub) {
        final isSelected = selectedSubCategory == sub;
        return GestureDetector(
          onTap: () => onSelected(sub),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.secondary
                  : AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? null
                  : Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 0.5,
                    ),
            ),
            child: Text(
              sub,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSecondary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PartSelector extends StatelessWidget {
  const _PartSelector({
    required this.subCategory,
    required this.selectedPart,
    required this.onSelected,
  });

  final String subCategory;
  final String? selectedPart;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    final parts = SubCategoryService.getParts(subCategory);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: parts.map((part) {
        final isSelected = selectedPart == part;
        return GestureDetector(
          onTap: () => onSelected(part),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.tertiary
                  : AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? null
                  : Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 0.5,
                    ),
            ),
            child: Text(
              part,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onTertiary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.isAutoSet,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isAutoSet;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontFamily: 'Pretendard'),
      decoration: InputDecoration(
        hintText: '재료명을 입력하세요',
        suffixIcon: isAutoSet
            ? Tooltip(
                message: '카테고리 선택으로 자동 입력됨. 직접 수정 가능',
                child: Icon(
                  Icons.auto_fix_high_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : null,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '재료명을 입력해 주세요';
        }
        return null;
      },
    );
  }
}

/// 보관 위치 선택 — 동적 슬롯 목록.
class _LocationSelector extends ConsumerWidget {
  const _LocationSelector({
    required this.selectedLocation,
    required this.selectedContainerIndex,
    required this.onSelected,
  });

  final StorageLocation selectedLocation;
  final int selectedContainerIndex;
  final void Function(StorageLocation location, int containerIndex) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(storageContainerSlotsProvider);
    return slotsAsync.when(
      loading: () => const SizedBox(
        height: 64,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => _buildSlotGrid(
        context,
        StorageLocation.values
            .map((l) => StorageContainerSlot(
                location: l, index: 0, totalCount: 1))
            .toList(),
      ),
      data: (slots) => _buildSlotGrid(context, slots),
    );
  }

  Widget _buildSlotGrid(
      BuildContext context, List<StorageContainerSlot> slots) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = selectedLocation == slot.location &&
            selectedContainerIndex == slot.index;
        return GestureDetector(
          onTap: () => onSelected(slot.location, slot.index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    )
                  : Border.all(
                      color:
                          Theme.of(context).colorScheme.outlineVariant,
                      width: 0.5,
                    ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TwemojiIcon(slot.emoji, size: 20),
                const SizedBox(height: 4),
                Text(
                  slot.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 수량 입력 + +/- 스테퍼.
///
/// 단위에 따라 스텝 크기가 달라진다:
/// g→50, kg→0.1, ml→100, L→0.5, 나머지→1
class _QuantityWithStepper extends StatelessWidget {
  const _QuantityWithStepper({
    required this.controller,
    required this.unit,
    required this.onStep,
  });

  final TextEditingController controller;
  final String unit;
  final void Function(double delta) onStep;

  double get _step {
    switch (unit) {
      case 'g':
        return 50;
      case 'kg':
        return 0.1;
      case 'ml':
        return 100;
      case 'L':
        return 0.5;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        // — 버튼
        _StepButton(
          icon: Icons.remove_rounded,
          color: cs.primary,
          onTap: () => onStep(-_step),
        ),
        const SizedBox(width: 8),
        // 직접 입력 필드
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
            decoration: const InputDecoration(
              hintText: '0',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '입력해 주세요';
              }
              if (double.tryParse(value) == null) {
                return '숫자만';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        // + 버튼
        _StepButton(
          icon: Icons.add_rounded,
          color: cs.primary,
          onTap: () => onStep(_step),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _UnitField extends StatelessWidget {
  const _UnitField({
    required this.controller,
    required this.onUnitSelected,
  });

  final TextEditingController controller;
  final void Function(String) onUnitSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontFamily: 'Pretendard'),
            decoration: const InputDecoration(
              hintText: '단위',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onSelected: onUnitSelected,
          itemBuilder: (_) => SubCategoryService.allUnits
              .map(
                (unit) => PopupMenuItem<String>(
                  value: unit,
                  child: Text(
                    unit,
                    style: const TextStyle(fontFamily: 'Pretendard'),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// 유통기한 날짜 선택 + 빠른 선택 칩.
class _ExpiryDatePicker extends StatelessWidget {
  const _ExpiryDatePicker({
    required this.selectedDate,
    required this.category,
    required this.subCategory,
    required this.onDateSelected,
  });

  final DateTime? selectedDate;
  final StockCategory? category;
  final String? subCategory;
  final void Function(DateTime?) onDateSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category != null) ...[
          _ExpiryQuickChips(
            category: category!,
            subCategory: subCategory,
            selectedDate: selectedDate,
            onSelected: (days) {
              onDateSelected(DateTime.now().add(Duration(days: days)));
            },
          ),
          const SizedBox(height: 10),
        ],
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate:
                  DateTime.now().subtract(const Duration(days: 365)),
              lastDate:
                  DateTime.now().add(const Duration(days: 365 * 3)),
            );
            if (picked != null) onDateSelected(picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selectedDate != null
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.4)
                  : null,
              border: Border.all(
                color: selectedDate != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: selectedDate != null ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: selectedDate != null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? _formatDate(selectedDate!)
                        : '직접 날짜 선택',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: selectedDate != null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                          fontWeight: selectedDate != null
                              ? FontWeight.w600
                              : null,
                        ),
                  ),
                ),
                if (selectedDate != null)
                  GestureDetector(
                    onTap: () => onDateSelected(null),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}년 ${date.month}월 ${date.day}일';
}

/// 유통기한 빠른 선택 칩.
///
/// [selectedDate]가 해당 칩의 날짜와 일치하면 primary 색으로 하이라이트.
class _ExpiryQuickChips extends StatelessWidget {
  const _ExpiryQuickChips({
    required this.category,
    required this.subCategory,
    required this.selectedDate,
    required this.onSelected,
  });

  final StockCategory category;
  final String? subCategory;
  final DateTime? selectedDate;
  final void Function(int days) onSelected;

  static const _options = [
    (3, '3일'),
    (7, '1주'),
    (14, '2주'),
    (30, '1개월'),
    (90, '3개월'),
    (180, '6개월'),
  ];

  bool _isChipSelected(int days) {
    if (selectedDate == null) return false;
    final target = DateTime.now().add(Duration(days: days));
    return selectedDate!.year == target.year &&
        selectedDate!.month == target.month &&
        selectedDate!.day == target.day;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final defaultDays = SubCategoryService.getDefaultExpiryDays(
      category,
      subCategory: subCategory,
    );
    final recommendedDays = _options
        .map((o) => o.$1)
        .reduce((a, b) =>
            (a - defaultDays).abs() <= (b - defaultDays).abs() ? a : b);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _options.map((option) {
        final (days, label) = option;
        final isSelected = _isChipSelected(days);
        final isRecommended = days == recommendedDays && !isSelected;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(days);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary
                  : isRecommended
                      ? cs.primaryContainer
                      : AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? null
                  : isRecommended
                      ? Border.all(color: cs.primary, width: 1)
                      : Border.all(
                          color: cs.outlineVariant,
                          width: 0.5,
                        ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: tt.labelMedium?.copyWith(
                    color: isSelected
                        ? cs.onPrimary
                        : isRecommended
                            ? cs.onPrimaryContainer
                            : cs.onSurface,
                    fontWeight: (isSelected || isRecommended)
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                if (isRecommended) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '추천',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
