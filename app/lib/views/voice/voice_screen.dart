import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/models/voice_input_result.dart';
import 'package:whipup/providers/stock_repository_provider.dart';
import 'package:whipup/services/voice_input_service.dart';
import 'package:whipup/services/voice_parser.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';

/// 음성 재료 입력 화면 (Phase 1.3).
///
/// 음성 인식 → 재료 파싱 → 확인 → 재고 추가.
/// 레이아웃: `docs/core/screen_layout.md §2.1`
class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen>
    with SingleTickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();
  final VoiceParser _parser = const VoiceParser();

  String _currentText = '';
  bool _isListening = false;
  bool _isInitialized = false;
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
      if (result.isFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorOrNull?.message ?? '음성 인식 초기화 실패')),
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
      _currentText = '';
      _result = null;
    });

    await _voiceService.startListening(
      onResult: (text) {
        if (mounted) setState(() => _currentText = text);
      },
    );
  }

  Future<void> _stopListening() async {
    await _voiceService.stopListening();
    if (mounted) {
      setState(() => _isListening = false);
      if (_currentText.isNotEmpty) {
        setState(() => _result = _parser.parse(_currentText));
      }
    }
  }

  Future<void> _addToStock() async {
    if (_result == null) return;
    final selected = _result!.candidates.where((c) => c.isSelected).toList();
    if (selected.isEmpty) return;

    final repo = await ref.read(stockRepositoryProvider.future);
    int addedCount = 0;
    for (final candidate in selected) {
      final item = StockItem(
        name: candidate.name,
        category: candidate.category,
        storageLocation: StorageLocation.fridge,
        quantity: double.tryParse(candidate.quantity ?? '1') ?? 1.0,
        unit: candidate.unit ?? '개',
        addedAt: DateTime.now(),
      );
      final result = await repo.add(item);
      if (result.isSuccess) addedCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$addedCount개 재료가 재고에 추가되었습니다!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '음성으로 재료 추가',
          style: AppTheme.screenTitleStyle,
        ),
      ),
      body: Column(
        children: [
          // ─── 음성 입력 영역 ─────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: AppTheme.cardColor,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 마이크 버튼
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: ScaleTransition(
                      scale: _isListening ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? cs.error : cs.primary,
                          boxShadow: _isListening
                              ? [
                                  BoxShadow(
                                    color: cs.error.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 상태 텍스트
                  Text(
                    _isListening ? '듣고 있어요... 탭하면 중지' : '마이크를 탭하여 시작',
                    style: tt.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),

                  // 인식된 텍스트
                  if (_currentText.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '"$_currentText"',
                        style: tt.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  // 안내 텍스트
                  if (!_isListening && _currentText.isEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      '예시: "양파 두 개랑 돼지고기 오백 그램이요"',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ─── 결과 확인 영역 ──────────────────────────────────────────
          if (_result != null)
            Expanded(
              flex: 3,
              child: _VoiceResultList(
                result: _result!,
                onToggle: (index) {
                  setState(() {
                    final updated = List<VoiceIngredientCandidate>.from(
                      _result!.candidates,
                    );
                    updated[index] = updated[index].copyWith(
                      isSelected: !updated[index].isSelected,
                    );
                    _result = _result!.copyWith(candidates: updated);
                  });
                },
              ),
            ),
        ],
      ),

      // 추가 버튼
      bottomNavigationBar: _result != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _addToStock,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      '재고에 추가하기',
                      style: tt.labelLarge?.copyWith(color: cs.onPrimary),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _VoiceResultList extends StatelessWidget {
  const _VoiceResultList({
    required this.result,
    required this.onToggle,
  });

  final VoiceInputResult result;
  final void Function(int) onToggle;

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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          Text(
            '${result.candidates.length}개 재료가 인식되었어요',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...result.candidates.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            return CheckboxListTile(
              value: c.isSelected,
              onChanged: (_) => onToggle(i),
              title: Text(c.name, style: tt.bodyLarge),
              subtitle: c.quantity != null
                  ? Text('${c.quantity}${c.unit ?? ''}', style: tt.bodySmall)
                  : null,
              secondary: TwemojiIcon(c.category.emoji, size: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ],
      ),
    );
  }
}
