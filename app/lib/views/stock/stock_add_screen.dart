import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/core/extensions/build_context_extensions.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/providers/reward_providers.dart';
import 'package:whipup/providers/stock_repository_provider.dart';
import 'package:whipup/services/sub_category_service.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';

/// 재료 추가/수정 화면.
///
/// - 카테고리 → 서브 카테고리 → 부위 캐스케이딩 선택 (US-6)
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
  });

  /// null이면 추가 모드, 값이 있으면 수정 모드
  final int? itemId;

  /// 초기 보관 위치 (StockScreen FAB에서 진입 시 전달)
  final String? initialStorageLocationName;

  /// 초기 재고함 인덱스 (StockScreen FAB에서 진입 시 전달)
  final int initialContainerIndex;

  @override
  ConsumerState<StockAddScreen> createState() => _StockAddScreenState();
}

class _StockAddScreenState extends ConsumerState<StockAddScreen> {
  // ─── 폼 상태 ───────────────────────────────────────────────────────────────
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

  // 수정 모드에서 기존 아이템 보관
  StockItem? _existingItem;

  @override
  void initState() {
    super.initState();
    // 초기 보관 위치 및 재고함 인덱스 설정
    if (widget.initialStorageLocationName != null) {
      final loc = StorageLocation.values.where(
        (l) => l.name == widget.initialStorageLocationName,
      );
      if (loc.isNotEmpty) {
        _selectedLocation = loc.first;
      }
    }
    _containerIndex = widget.initialContainerIndex;
    // 수정 모드: 기존 데이터 로드
    if (widget.itemId != null) {
      _loadExistingItem();
    }
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

  // ─── 카테고리 선택 ──────────────────────────────────────────────────────────

  void _onCategorySelected(StockCategory category) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
      _selectedSubCategory = null;
      _selectedPart = null;
      // 단위 자동 설정
      final unit = SubCategoryService.getDefaultUnit(category);
      _unitController.text = unit;
      _isUnitAutoSet = true;
      // 재료명 초기화
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
      // 단위 자동 갱신
      final unit = SubCategoryService.getDefaultUnit(
        _selectedCategory!,
        subCategory: subCategory,
      );
      _unitController.text = unit;
      _isUnitAutoSet = true;
      // 재료명 자동 입력
      _nameController.text = SubCategoryService.buildAutoName(
        subCategory: subCategory,
      );
      _isNameAutoSet = true;
      // 수량 자동 입력 (추가 모드만)
      if (widget.itemId == null) {
        final qty = SubCategoryService.getDefaultQuantity(
          _selectedCategory!,
          subCategory: subCategory,
        );
        _quantityController.text =
            qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
      }
    });
  }

  void _onPartSelected(String part) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPart = part;
      // 재료명 자동 갱신 (부위 포함)
      if (_selectedSubCategory != null) {
        _nameController.text = SubCategoryService.buildAutoName(
          subCategory: _selectedSubCategory!,
          itemPart: part,
        );
        _isNameAutoSet = true;
      }
    });
  }

  // ─── 저장 ──────────────────────────────────────────────────────────────────

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
          // 재고 추가 시 리워드 트리거 (fire-and-forget)
          if (widget.itemId == null) {
            handleStockAdded(ref);
          }
          context.pop();
          context.showSnackBar(
            widget.itemId != null ? '재료가 수정되었어요 ✅' : '재료가 추가되었어요 🎉',
          );
        },
        failure: (err) {
          context.showSnackBar('저장 실패: ${err.message}');
        },
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── 빌드 ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.itemId != null;

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
          // 저장 버튼
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
            // ─── 1. 카테고리 ────────────────────────────────────────────
            _SectionLabel(
              label: '카테고리',
              required: true,
            ),
            const SizedBox(height: 8),
            _CategorySelector(
              selectedCategory: _selectedCategory,
              onSelected: _onCategorySelected,
            ),

            // ─── 2. 서브 카테고리 ─────────────────────────────────────
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

            // ─── 3. 부위 ─────────────────────────────────────────────
            if (_selectedSubCategory != null &&
                SubCategoryService.getParts(_selectedSubCategory!).isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionLabel(label: '부위'),
              const SizedBox(height: 8),
              _PartSelector(
                subCategory: _selectedSubCategory!,
                selectedPart: _selectedPart,
                onSelected: _onPartSelected,
              ),
            ],

            // ─── 4. 재료명 ────────────────────────────────────────────
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

            // ─── 5. 보관 위치 ────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionLabel(label: '보관 위치', required: true),
            const SizedBox(height: 8),
            _LocationSelector(
              selectedLocation: _selectedLocation,
              onSelected: (loc) {
                HapticFeedback.selectionClick();
                setState(() => _selectedLocation = loc);
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
                      _QuantityField(controller: _quantityController),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: '단위'),
                      if (_isUnitAutoSet)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
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
                      const SizedBox(height: 8),
                      _UnitField(
                        controller: _unitController,
                        onUnitSelected: (unit) {
                          setState(() {
                            _unitController.text = unit;
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

// ─── 재사용 컴포넌트들 ──────────────────────────────────────────────────────────

/// 섹션 라벨
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

/// 카테고리 선택 그리드 (2행 수평 스크롤)
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? null
                  : Border.all(
                      color:
                          Theme.of(context).colorScheme.outlineVariant,
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
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
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

/// 서브 카테고리 선택 칩
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
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? null
                  : Border.all(
                      color:
                          Theme.of(context).colorScheme.outlineVariant,
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

/// 부위/종류 선택 칩
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? null
                  : Border.all(
                      color:
                          Theme.of(context).colorScheme.outlineVariant,
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

/// 재료명 입력 필드
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

/// 보관 위치 선택
class _LocationSelector extends StatelessWidget {
  const _LocationSelector({
    required this.selectedLocation,
    required this.onSelected,
  });

  final StorageLocation selectedLocation;
  final void Function(StorageLocation) onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: StorageLocation.values.map((loc) {
        final isSelected = selectedLocation == loc;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelected(loc),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
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
                  children: [
                    TwemojiIcon(loc.emoji, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      loc.label,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                              ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 수량 입력 필드
class _QuantityField extends StatelessWidget {
  const _QuantityField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: const TextStyle(fontFamily: 'Pretendard'),
      decoration: const InputDecoration(
        hintText: '0',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '수량을 입력해 주세요';
        }
        if (double.tryParse(value) == null) {
          return '올바른 숫자를 입력해 주세요';
        }
        return null;
      },
    );
  }
}

/// 단위 입력 + 드롭다운 선택
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // 단위 드롭다운 버튼
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

/// 유통기한 날짜 선택 + 빠른 선택 칩
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
        // 빠른 선택 칩 (카테고리 선택 시 노출)
        if (category != null) ...[
          _ExpiryQuickChips(
            category: category!,
            subCategory: subCategory,
            onSelected: (days) {
              onDateSelected(DateTime.now().add(Duration(days: days)));
            },
          ),
          const SizedBox(height: 10),
        ],
        // 날짜 직접 선택 행
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? _formatDate(selectedDate!)
                        : '직접 날짜 선택',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: selectedDate != null
                              ? null
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                if (selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => onDateSelected(null),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}

/// 유통기한 빠른 선택 칩 목록
class _ExpiryQuickChips extends StatelessWidget {
  const _ExpiryQuickChips({
    required this.category,
    required this.subCategory,
    required this.onSelected,
  });

  final StockCategory category;
  final String? subCategory;
  final void Function(int days) onSelected;

  static const _options = [
    (3, '3일'),
    (7, '1주'),
    (14, '2주'),
    (30, '1개월'),
    (90, '3개월'),
    (180, '6개월'),
  ];

  @override
  Widget build(BuildContext context) {
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
        final isRecommended = days == recommendedDays;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(days);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isRecommended
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: isRecommended
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    )
                  : Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 0.5,
                    ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isRecommended
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isRecommended
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                ),
                if (isRecommended) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '추천',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
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
