import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Env.isConfigured) {
    runApp(const ConfigMissingApp());
    return;
  }
  // publishableKey 자리에 anon key를 넘긴다 — 둘 다 apikey 헤더로 전송되는 공개 키.
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: ChulseokpingApp()));
}

/// --dart-define 미설정 시 안내 (키 하드코딩 금지 — AGENTS.md §6).
class ConfigMissingApp extends StatelessWidget {
  const ConfigMissingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '환경변수가 없어요.\n\n'
              'flutter run --dart-define=SUPABASE_URL=... '
              '--dart-define=SUPABASE_ANON_KEY=...\n\n'
              '(.env.example 참고)',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
