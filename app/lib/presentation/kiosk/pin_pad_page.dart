import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/result/result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// PIN 입력 단계: 학번 → PIN (design.md PinPad — 특대, 오입력 피드백).
enum _PinStep { studentNumber, pin }

/// KO-4: 키오스크 PIN 체크인. 성공/실패 특대 피드백 후 자동 초기화(다음 학생).
class PinPadPage extends ConsumerStatefulWidget {
  const PinPadPage({
    super.key,
    required this.sessionId,
    required this.deviceToken,
  });

  final String sessionId;
  final String deviceToken;

  @override
  ConsumerState<PinPadPage> createState() => _PinPadPageState();
}

class _PinPadPageState extends ConsumerState<PinPadPage> {
  _PinStep _step = _PinStep.studentNumber;
  String _studentNumber = '';
  String _pin = '';
  bool _submitting = false;
  String? _resultMessage;
  bool _resultSuccess = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _append(String digit) {
    if (_submitting || _resultMessage != null) return;
    setState(() {
      if (_step == _PinStep.studentNumber && _studentNumber.length < 10) {
        _studentNumber += digit;
      } else if (_step == _PinStep.pin && _pin.length < 8) {
        _pin += digit;
      }
    });
  }

  void _backspace() {
    if (_submitting || _resultMessage != null) return;
    setState(() {
      if (_step == _PinStep.studentNumber && _studentNumber.isNotEmpty) {
        _studentNumber = _studentNumber.substring(0, _studentNumber.length - 1);
      } else if (_step == _PinStep.pin && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _next() async {
    if (_step == _PinStep.studentNumber) {
      if (_studentNumber.isEmpty) return;
      setState(() => _step = _PinStep.pin);
      return;
    }
    setState(() => _submitting = true);
    final result = await ref
        .read(checkInByPinProvider)
        .call(
          deviceToken: widget.deviceToken,
          sessionId: widget.sessionId,
          studentNumber: _studentNumber,
          pin: _pin,
        );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _showResult(
          true,
          '출석되었어요!  (${value.checkInTime.hour}시 ${value.checkInTime.minute}분)',
        );
      case Err(:final failure):
        _showResult(false, failure.message);
    }
  }

  void _showResult(bool success, String message) {
    setState(() {
      _submitting = false;
      _resultSuccess = success;
      _resultMessage = message;
    });
    // 다음 학생을 위해 자동 초기화
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _step = _PinStep.studentNumber;
        _studentNumber = '';
        _pin = '';
        _resultMessage = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = _step == _PinStep.studentNumber ? '학번을 입력하세요' : 'PIN을 입력하세요';
    final display = _step == _PinStep.pin ? '●' * _pin.length : _studentNumber;

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      appBar: AppBar(title: const Text('학번 + PIN 출석')),
      body: SafeArea(
        child: _resultMessage != null
            ? _ResultView(success: _resultSuccess, message: _resultMessage!)
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: AppTypography.display.copyWith(
                            fontSize:
                                AppTypography.display.fontSize! *
                                AppTypography.kioskScale,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl,
                            vertical: AppSpacing.lg,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgBase,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(color: AppColors.borderDefault),
                          ),
                          child: Text(
                            display.isEmpty ? ' ' : display,
                            style: AppTypography.mono.copyWith(fontSize: 40),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: _NumPad(
                        onDigit: _append,
                        onBackspace: _backspace,
                        onNext: _submitting ? null : _next,
                        nextLabel: _step == _PinStep.studentNumber
                            ? '다음'
                            : '출석',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  const _NumPad({
    required this.onDigit,
    required this.onBackspace,
    required this.onNext,
    required this.nextLabel,
  });

  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, Color? color}) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: SizedBox(
          height: AppSpacing.touchTargetKiosk,
          child: ElevatedButton(
            onPressed: onTap ?? () => onDigit(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: color ?? AppColors.bgBase,
              foregroundColor: color == null
                  ? AppColors.textPrimary
                  : AppColors.bgBase,
              textStyle: AppTypography.h1,
            ),
            child: Text(label),
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(children: [for (final d in row) Expanded(child: key(d))]),
        Row(
          children: [
            Expanded(child: key('←', onTap: onBackspace)),
            Expanded(child: key('0')),
            Expanded(
              child: key(nextLabel, onTap: onNext, color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.success, required this.message});

  final bool success;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.danger;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error_outline,
            size: 120,
            color: color,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            message,
            style: AppTypography.display.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
