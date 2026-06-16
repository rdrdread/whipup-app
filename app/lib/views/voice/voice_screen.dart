import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/models/voice_input_result.dart';
import 'package:whipup/providers/reward_providers.dart';
import 'package:whipup/providers/stock_providers.dart';
import 'package:whipup/providers/stock_repository_provider.dart';
import 'package:whipup/providers/voice_provider.dart';
import 'package:whipup/services/sub_category_service.dart';
import 'package:whipup/services/voice_input_service.dart';
import 'package:whipup/theme/app_theme.dart';

/// 음성 재료 일괄 입력 화면 (Phase 1.3).
///
/// 음성 인식 → Gemini 파싱 → 후보 확인/수정 → 재고 일괄 추가.
/// 유통기한은 SubCategoryService 추천값 자동 적용.
class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen>
    with SingleTickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();

  String _currentText = '';
  // 이전 녹음 세션(stop 후 재시작)에서 확정된 텍스트
  String _accumulatedText = '';
  // 현재 세션 안에서 확정된 utterance 누적
  String _committedText = '';
  // 마지막으로 commit된 utterance의 recognizedWords (dedup용)
  String? _lastCommittedWords;
  // 현재 utterance에서 관측된 최장 partial (utterance 경계 감지용)
  String _sessionPartial = '';
  bool _isListening = false;
  // stopListening() 호출 후 최종 콜백이 도착하는 짧은 구간 동안 결과 무시
  bool _isStopping = false;
  // 마이크 입력 레벨 (0.0 ~ 1.0, 사운드 링 표시용)
  double _soundLevel = 0.0;
  bool _isInitialized = false;
  bool _isParsing = false;
  bool _isSaving = false;
  VoiceInputResult? _result;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initVoice();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _initVoice() async {
    final result = await _voiceService.initialize();
    if (mounted) {
      setState(() => _isInitialized = result.isSuccess);
      if (result.isFailure && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorOrNull?.message ?? '음성 인식 초기화 실패'),
          ),
        );
      }
    }
  }

  Future<void> _startListening() async {
    if (!_isInitialized) {
      await _initVoice();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isListening = true;
      _result = null;
      _isParsing = false;
      _committedText = '';
      _lastCommittedWords = null;
      _sessionPartial = '';
    });

    await _voiceService.startListening(
      onResult: _onVoiceResult,
      onSoundLevel: (level) {
        if (!mounted) return;
        // speech_to_text는 약 -160 ~ 10 dB 범위로 레벨을 전달
        final normalized = ((level + 50) / 50).clamp(0.0, 1.0);
        setState(() => _soundLevel = normalized);
      },
    );
  }

  /// 음성 인식 결과 콜백.
  ///
  /// Android가 utterance 경계에서 recognizedWords를 초기화할 때
  /// (text가 _sessionPartial보다 크게 짧아짐) 이전 utterance를 commit한다.
  /// speech_to_text의 내부 자동 재시작과 충돌하지 않도록 수동 restart를 사용하지 않는다.
  void _onVoiceResult(String text, {required bool isFinal}) {
    if (!mounted) return;
    if (_isStopping) return;
    if (_lastCommittedWords != null && text == _lastCommittedWords) return;

    // 새 utterance 감지: text가 관측 최장값의 60% 미만으로 줄어들면 새 발화 시작
    final isNewUtterance = !isFinal &&
        _sessionPartial.length > 4 &&
        text.length < _sessionPartial.length * 0.6;

    if (isNewUtterance) {
      // 이전 utterance의 최장 partial을 commit
      if (_sessionPartial != _lastCommittedWords) {
        _committedText = _committedText.isEmpty
            ? _sessionPartial
            : '$_committedText $_sessionPartial';
        _lastCommittedWords = _sessionPartial;
      }
      _sessionPartial = text;
    } else {
      if (text.length > _sessionPartial.length) _sessionPartial = text;
    }

    final parts = <String>[];
    if (_accumulatedText.isNotEmpty) parts.add(_accumulatedText);
    if (_committedText.isNotEmpty) parts.add(_committedText);
    parts.add(text);

    setState(() {
      _currentText = parts.join(' ');
      if (isFinal) {
        if (text != _lastCommittedWords) {
          _committedText =
              _committedText.isEmpty ? text : '$_committedText $text';
          _lastCommittedWords = text;
        }
        _sessionPartial = '';
      }
    });
  }

  Future<void> _stopListening() async {
    setState(() {
      _isListening = false;
      _soundLevel = 0.0;
    });
    _isStopping = true;
    await _voiceService.stopListening();
    // stopListening()이 isFinal 콜백을 발생시킬 수 있으므로 처리 후 텍스트 캡처
    await Future.delayed(const Duration(milliseconds: 150));
    _isStopping = false;
    if (!mounted) return;

    final textToParse = _currentText;
    _accumulatedText = textToParse;
    setState(() => _isParsing = textToParse.isNotEmpty);

    if (textToParse.isEmpty) return;

    final parser = ref.read(voiceGeminiParserProvider);
    final parseResult = await parser.parse(textToParse);

    if (!mounted) return;
    setState(() => _isParsing = false);

    parseResult.when(
      success: (result) => setState(() => _result = result),
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 파싱 실패: ${error.message}')),
        );
      },
    );
  }

  void _toggleCandidate(int index) {
    if (_result == null) return;
    final updated = List<VoiceIngredientCandidate>.from(_result!.candidates);
    updated[index] = updated[index].copyWith(
      isSelected: !updated[index].isSelected,
    );
    setState(() => _result = _result!.copyWith(candidates: updated));
  }

  void _changeStorageLocation(int index, StorageLocation location) {
    if (_result == null) return;
    HapticFeedback.selectionClick();
    final updated = List<VoiceIngredientCandidate>.from(_result!.candidates);
    updated[index] = updated[index].copyWith(storageLocation: location);
    setState(() => _result = _result!.copyWith(candidates: updated));
  }

  Future<void> _addToStock() async {
    if (_result == null) return;
    final selected =
        _result!.candidates.where((c) => c.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isSaving = true);

    final repo = await ref.read(stockRepositoryProvider.future);
    int addedCount = 0;

    for (final candidate in selected) {
      final item = StockItem(
        name: candidate.name,
        category: candidate.category,
        subCategory: candidate.subCategory,
        storageLocation: candidate.storageLocation,
        quantity:
            double.tryParse(candidate.quantity ?? '1') ?? 1.0,
        unit: candidate.unit ??
            SubCategoryService.getDefaultUnit(
              candidate.category,
              subCategory: candidate.subCategory,
            ),
        expiryDate: candidate.expiryDate,
        addedAt: DateTime.now(),
      );
      final result = await repo.add(item);
      if (result.isSuccess) addedCount++;
    }

    if (addedCount > 0 && mounted) {
      await handleStockAdded(ref);
      ref.invalidate(stockSummaryProvider);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$addedCount개 재료가 추가되었어요! 🎉'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final selectedCount =
        _result?.candidates.where((c) => c.isSelected).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('음성으로 재료 추가', style: AppTheme.screenTitleStyle),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // ─── 음성 입력 영역 ─────────────────────────────────────────
          Container(
            width: double.infinity,
            color: cs.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 마이크 버튼 (사운드 레벨 링 포함)
                GestureDetector(
                  onTap: (_isParsing || _isSaving)
                      ? null
                      : (_isListening ? _stopListening : _startListening),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 사운드 레벨 링 (청취 중일 때만)
                      if (_isListening)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          width: 88 + _soundLevel * 36,
                          height: 88 + _soundLevel * 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.error.withValues(
                              alpha: 0.12 + _soundLevel * 0.18,
                            ),
                          ),
                        ),
                      ScaleTransition(
                        scale: _isListening
                            ? _pulseAnim
                            : const AlwaysStoppedAnimation(1.0),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening ? cs.error : cs.primary,
                            boxShadow: _isListening
                                ? [
                                    BoxShadow(
                                      color: cs.error.withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color:
                                          cs.primary.withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                          ),
                          child: _isParsing
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: CircularProgressIndicator(
                                    color: cs.onPrimary,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Icon(
                                  _isListening
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 상태 텍스트
                Text(
                  _isParsing
                      ? 'AI가 재료를 분석 중이에요...'
                      : _isListening
                          ? '듣고 있어요... 탭하면 중지'
                          : (_currentText.isNotEmpty
                              ? '재료를 더 추가하려면 마이크를 탭하세요'
                              : '마이크를 탭하여 시작'),
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),

                // 인식된 텍스트 표시
                if (_currentText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      '"$_currentText"',
                      style: tt.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (!_isListening && !_isParsing)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _accumulatedText = '';
                        _committedText = '';
                        _lastCommittedWords = null;
                        _sessionPartial = '';
                        _currentText = '';
                        _result = null;
                      }),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('다시 시작'),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onSurfaceVariant,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                ],

                // 힌트
                if (!_isListening &&
                    _currentText.isEmpty &&
                    _result == null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '예) "돼지고기 삼백 그램이랑 달걀 한 판, 우유 1개"',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          // ─── 재료 후보 목록 ──────────────────────────────────────────
          if (_result != null)
            _CandidateList(
              result: _result!,
              onToggle: _toggleCandidate,
              onChangeLocation: _changeStorageLocation,
            ),
        ],
        ),
      ),

      // ─── 추가 버튼 ────────────────────────────────────────────────────
      bottomNavigationBar: _result != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        (_isSaving || selectedCount == 0) ? null : _addToStock,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            selectedCount > 0
                                ? '$selectedCount개 재고에 추가하기'
                                : '재료를 선택해 주세요',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                ),
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ─── 재료 후보 목록 위젯 ────────────────────────────────────────────────────────

class _CandidateList extends StatelessWidget {
  const _CandidateList({
    required this.result,
    required this.onToggle,
    required this.onChangeLocation,
  });

  final VoiceInputResult result;
  final void Function(int index) onToggle;
  final void Function(int index, StorageLocation location) onChangeLocation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Text(
                  '${result.candidates.length}개 재료 인식됨',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text(
                  '• 보관 위치와 유통기한을 확인해 주세요',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: result.candidates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _CandidateCard(
                candidate: result.candidates[i],
                onToggle: () => onToggle(i),
                onChangeLocation: (loc) => onChangeLocation(i, loc),
              ),
          ),
        ],
      ),
    );
  }
}

// ─── 개별 재료 카드 ─────────────────────────────────────────────────────────────

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.onToggle,
    required this.onChangeLocation,
  });

  final VoiceIngredientCandidate candidate;
  final VoidCallback onToggle;
  final void Function(StorageLocation) onChangeLocation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final qty = candidate.quantity ?? '1';
    final unit = candidate.unit ?? '';
    final expiryDate = candidate.expiryDate;
    final daysLeft = expiryDate != null
        ? expiryDate.difference(DateTime.now()).inDays
        : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: candidate.isSelected
            ? cs.primaryContainer.withValues(alpha: 0.35)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: candidate.isSelected
              ? cs.primary.withValues(alpha: 0.4)
              : cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 상단: 체크박스 + 이모지 + 이름 + 수량 ───────────────
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: candidate.isSelected,
                      onChanged: (_) => onToggle(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    candidate.category.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      candidate.name,
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: candidate.isSelected
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    '$qty$unit',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ─── 보관 위치 칩 ──────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: StorageLocation.values.map((loc) {
                    final selected = candidate.storageLocation == loc;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => onChangeLocation(loc),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? cs.secondaryContainer
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? cs.secondary
                                  : cs.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                loc.emoji,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                loc.label,
                                style: tt.labelSmall?.copyWith(
                                  color: selected
                                      ? cs.onSecondaryContainer
                                      : cs.onSurfaceVariant,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ─── 유통기한 정보 ─────────────────────────────────────────
              if (daysLeft != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: _expiryColor(cs, daysLeft),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expiryLabel(daysLeft, expiryDate!),
                      style: tt.labelSmall?.copyWith(
                        color: _expiryColor(cs, daysLeft),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _expiryLabel(int daysLeft, DateTime expiryDate) {
    final dateStr =
        '${expiryDate.month}/${expiryDate.day}';
    if (daysLeft <= 0) return '오늘까지 ($dateStr)';
    if (daysLeft == 1) return '내일까지 ($dateStr)';
    return '$daysLeft일 보관 권장 (~$dateStr)';
  }

  Color _expiryColor(ColorScheme cs, int daysLeft) {
    if (daysLeft <= 3) return cs.error;
    if (daysLeft <= 7) return cs.tertiary;
    return cs.onSurfaceVariant;
  }
}
