import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // M1: Env.isConfigured 확인 후 Supabase.initialize 추가 (core/config/env.dart)
  runApp(const ProviderScope(child: ChulseokpingApp()));
}
