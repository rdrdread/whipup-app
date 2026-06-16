import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:whipup/repositories/impl/isar_achievement.dart';
import 'package:whipup/repositories/impl/isar_cached_recipe.dart';
import 'package:whipup/repositories/impl/isar_reward_stats.dart';
import 'package:whipup/repositories/impl/isar_stock_item.dart';
import 'package:whipup/router/app_router.dart';
import 'package:whipup/theme/app_theme.dart';

// ─── Entry Point ──────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp();
  }

  // 데스크탑에서만 창 크기를 모바일 비율로 고정한다.
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(390, 844),
        minimumSize: Size(390, 844),
        center: true,
        title: 'WhipUp',
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  await _initIsar();

  runApp(
    const ProviderScope(
      child: WhipUpApp(),
    ),
  );
}

Future<void> _initIsar() async {
  if (Isar.instanceNames.isEmpty) {
    final dir = await getApplicationDocumentsDirectory();
    await Isar.open(
      [
        IsarStockItemSchema,
        IsarCachedRecipeSchema,
        IsarAchievementSchema,
        IsarRewardStatsSchema,
      ],
      directory: dir.path,
      name: 'whipup_db',
    );
  }
}

// ─── Root App ─────────────────────────────────────────────────────────────────

/// WhipUp 앱의 루트 위젯.
///
/// [ProviderScope]를 통해 Riverpod 상태를 주입하며,
/// [GoRouter]를 사용한 선언적 라우팅을 구성한다.
class WhipUpApp extends StatelessWidget {
  const WhipUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WhipUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.12),
        ),
        child: child!,
      ),
    );
  }
}
