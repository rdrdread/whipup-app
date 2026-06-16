import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 요리 완성 사진 등록 바텀시트.
///
/// 반환값: 저장된 이미지 파일 경로 (등록 완료 시) / null (건너뛰기).
class PhotoUploadSheet extends StatefulWidget {
  const PhotoUploadSheet({super.key, required this.recipeTitle});

  final String recipeTitle;

  /// 바텀시트를 표시하고, 등록된 사진 경로 또는 null을 반환한다.
  static Future<String?> show(BuildContext context, String recipeTitle) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoUploadSheet(recipeTitle: recipeTitle),
    );
  }

  @override
  State<PhotoUploadSheet> createState() => _PhotoUploadSheetState();
}

class _PhotoUploadSheetState extends State<PhotoUploadSheet> {
  File? _selectedFile;
  bool _uploading = false;
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    HapticFeedback.lightImpact();
    try {
      final xFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (xFile == null || !mounted) return;
      setState(() => _selectedFile = File(xFile.path));
    } catch (_) {
      // 권한 거부 또는 취소 — 무시
    }
  }

  Future<void> _confirm() async {
    if (_selectedFile == null) return;
    setState(() => _uploading = true);
    HapticFeedback.mediumImpact();

    // 앱 문서 디렉토리에 복사해 영구 보관
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'cooking_photos'));
    await photosDir.create(recursive: true);

    final ext = p.extension(_selectedFile!.path);
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedFile = await _selectedFile!.copy(p.join(photosDir.path, fileName));

    if (mounted) Navigator.of(context).pop(savedFile.path);
  }

  void _skip() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);

    return Container(
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: mq.viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 포인트 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '📸 사진 등록 +30P',
                  style: tt.labelMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                '완성한 요리를 보여주세요!',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.recipeTitle} 완성 사진을 남기면\n30포인트를 드려요',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // 사진 프리뷰
              GestureDetector(
                onTap: () => _pick(ImageSource.gallery),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _selectedFile == null
                        ? cs.surfaceContainerHighest
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedFile == null
                          ? cs.outlineVariant
                          : cs.primary,
                      width: _selectedFile == null ? 1.5 : 2.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _selectedFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 48, color: cs.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text(
                              '탭해서 사진 선택',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_selectedFile!, fit: BoxFit.cover),
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.refresh,
                                        color: Colors.white, size: 18),
                                    onPressed: () => _pick(ImageSource.gallery),
                                    tooltip: '다시 선택',
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // 촬영 / 갤러리 버튼 행
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('카메라'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('갤러리'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 등록 / 건너뛰기
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed:
                      (_selectedFile != null && !_uploading) ? _confirm : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _uploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('등록하고 30P 받기',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),

              TextButton(
                onPressed: _skip,
                child: Text(
                  '건너뛰기',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
