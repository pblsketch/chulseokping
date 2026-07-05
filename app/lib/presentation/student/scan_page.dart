import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/di/providers.dart';
import '../../core/result/result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// ST-4: 회전 QR 스캔 → check_in_qr 제출. 만료(422)면 "다시 스캔" 안내.
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  bool _processing = false;
  String? _message;
  bool _success = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _success) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    String? sessionId;
    String? code;
    try {
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      sessionId = payload['sid'] as String?;
      code = payload['c'] as String?;
    } catch (_) {
      setState(() => _message = '출석 QR이 아니에요');
      return;
    }
    if (sessionId == null || code == null) {
      setState(() => _message = '출석 QR이 아니에요');
      return;
    }
    if (sessionId != widget.sessionId) {
      setState(() => _message = '지금 진행 중인 세션의 QR이 아니에요');
      return;
    }

    setState(() {
      _processing = true;
      _message = null;
    });
    final result = await ref
        .read(checkInByQrProvider)
        .call(sessionId: sessionId, code: code);
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() {
          _processing = false;
          _success = true;
          _message = '출석되었어요!';
        });
      case Err(:final failure):
        setState(() {
          _processing = false;
          _message = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR 스캔')),
      body: Column(
        children: [
          Expanded(
            child: _success
                ? const _SuccessView()
                : MobileScanner(onDetect: _onDetect),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                if (_processing) const CircularProgressIndicator(),
                if (_message != null)
                  Text(
                    _message!,
                    style: AppTypography.title.copyWith(
                      color: _success ? AppColors.success : AppColors.danger,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (_success) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('확인'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.check_circle, size: 96, color: AppColors.success),
    );
  }
}
