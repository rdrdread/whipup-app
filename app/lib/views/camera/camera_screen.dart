import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/ocr_result.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/providers/stock_repository_provider.dart';
import 'package:whipup/services/ocr_service.dart';
import 'package:whipup/services/receipt_parser.dart';

/// 카메라 OCR 영수증 인식 화면 (Phase 1.2).
///
/// 영수증 촬영 → ML Kit 텍스트 인식 → 재료 후보 확인 → 재고 추가.
/// 레이아웃: `docs/core/screen_layout.md §2.1`
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  OcrResult? _ocrResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(controller.description);
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      await _initCameraController(_cameras.first);
    } catch (e) {
      debugPrint('카메라 초기화 실패: $e');
    }
  }

  Future<void> _initCameraController(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;
    await controller.initialize();
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final image = await _controller!.takePicture();
      final ocrService = OcrService();
      final textResult = await ocrService.recognizeText(image.path);
      ocrService.dispose();

      textResult.when(
        success: (text) {
          final parser = const ReceiptParser();
          final result = parser.parse(text);
          setState(() {
            _ocrResult = result;
            _isProcessing = false;
          });
        },
        failure: (error) {
          setState(() => _isProcessing = false);
          _showError(error.message);
        },
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('처리 중 오류가 발생했습니다.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_ocrResult != null) {
      return _OcrResultView(
        ocrResult: _ocrResult!,
        onBack: () => setState(() => _ocrResult = null),
        onConfirm: (candidates) => context.pop(candidates),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          '영수증 촬영',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 카메라 프리뷰
          if (_isInitialized && _controller != null)
            CameraPreview(_controller!)
          else
            const Center(
              child: Text(
                '카메라를 초기화하는 중...',
                style: TextStyle(color: Colors.white),
              ),
            ),

          // 안내 오버레이
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '영수증을 화면 가득 채워서 촬영하세요',
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // 처리 중 오버레이
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      '영수증을 분석하는 중...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // 촬영 버튼
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isInitialized && !_isProcessing
          ? GestureDetector(
              onTap: _captureAndProcess,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ─── OCR 결과 확인 화면 ─────────────────────────────────────────────────────────

class _OcrResultView extends ConsumerStatefulWidget {
  const _OcrResultView({
    required this.ocrResult,
    required this.onBack,
    required this.onConfirm,
  });

  final OcrResult ocrResult;
  final VoidCallback onBack;
  final void Function(List<OcrIngredientCandidate>) onConfirm;

  @override
  ConsumerState<_OcrResultView> createState() => _OcrResultViewState();
}

class _OcrResultViewState extends ConsumerState<_OcrResultView> {
  late List<OcrIngredientCandidate> _candidates;

  @override
  void initState() {
    super.initState();
    _candidates = List.from(widget.ocrResult.candidates);
  }

  void _toggleCandidate(int index) {
    setState(() {
      _candidates[index] = _candidates[index].copyWith(
        isSelected: !_candidates[index].isSelected,
      );
    });
  }

  Future<void> _addToStock() async {
    final selected = _candidates.where((c) => c.isSelected).toList();
    if (selected.isEmpty) return;

    final stockNotifier = ref.read(stockRepositoryProvider);
    final repo = await stockNotifier.whenOrNull(data: (r) async => r);
    if (repo == null) return;

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
    final selectedCount = _candidates.where((c) => c.isSelected).length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack,
        ),
        title: const Text('인식 결과 확인'),
      ),
      body: _candidates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😕', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    '재료를 인식하지 못했어요.',
                    style: tt.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.onBack,
                    child: const Text('다시 촬영'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${_candidates.length}개 재료가 인식되었어요',
                  style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                ..._candidates.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  return CheckboxListTile(
                    value: c.isSelected,
                    onChanged: (_) => _toggleCandidate(i),
                    title: Text(c.name, style: tt.bodyLarge),
                    subtitle: c.quantity != null
                        ? Text('${c.quantity}${c.unit ?? ''}',
                            style: tt.bodySmall)
                        : null,
                    secondary: Text(
                      c.category.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: selectedCount > 0 ? _addToStock : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                '$selectedCount개 재료 재고에 추가',
                style: tt.labelLarge?.copyWith(color: cs.onPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
