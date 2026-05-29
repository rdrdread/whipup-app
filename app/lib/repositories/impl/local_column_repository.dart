import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/column_article.dart';
import 'package:whipup/models/column_category.dart';
import 'package:whipup/repositories/column_repository.dart';

/// MVP 구현체: `assets/columns/columns.json`에서 직접 읽는다.
///
/// Isar 캐시 없이 앱 번들 JSON을 1회 로드 후 메모리에 캐싱한다.
/// Phase 2.6 서버 발행 이전까지 사용.
class LocalColumnRepository implements ColumnRepository {
  LocalColumnRepository({this.assetPath = 'assets/columns/columns.json'});

  final String assetPath;

  List<ColumnArticle>? _cache;

  Future<List<ColumnArticle>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as List<dynamic>;
    final list = decoded
        .map((e) => ColumnArticle.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    _cache = list;
    return list;
  }

  @override
  Future<Result<List<ColumnArticle>, AppError>> getAll() async {
    try {
      return Result.success(await _load());
    } catch (e) {
      return Result.failure(AppError.parsing('칼럼을 불러오지 못했어요: $e'));
    }
  }

  @override
  Future<Result<List<ColumnArticle>, AppError>> getByCategory(
    ColumnCategory category,
  ) async {
    try {
      final all = await _load();
      return Result.success(
        all.where((a) => a.category == category).toList(),
      );
    } catch (e) {
      return Result.failure(AppError.parsing('칼럼을 불러오지 못했어요: $e'));
    }
  }

  @override
  Future<Result<ColumnArticle, AppError>> getById(String id) async {
    try {
      final all = await _load();
      ColumnArticle? found;
      for (final article in all) {
        if (article.id == id) {
          found = article;
          break;
        }
      }
      if (found == null) {
        return Result.failure(const AppError.unknown('칼럼을 찾을 수 없어요'));
      }
      return Result.success(found);
    } catch (e) {
      return Result.failure(AppError.parsing('칼럼을 불러오지 못했어요: $e'));
    }
  }
}
