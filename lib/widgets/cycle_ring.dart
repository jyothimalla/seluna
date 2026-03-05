import 'dart:math';
import 'package:flutter/material.dart';

/// Flo-style cycle ring widget showing period/fertile phases and current
/// position in the cycle via a CustomPainter arc track.
class CycleRingWidget extends StatelessWidget {
  final int cycleDay;
  final int cycleLength;
  final int periodLength;
  final DateTime? nextPeriodDate;
  final DateTime today;
  final bool isOngoingPeriod;

  const CycleRingWidget({
    super.key,
    required this.cycleDay,
    required this.cycleLength,
    required this.periodLength,
    this.nextPeriodDate,
    required this.today,
    this.isOngoingPeriod = false,
  });

  static const _deep = Color(0xFF880E4F);
  static const _mid = Color(0xFFE91E63);
  static const _teal = Color(0xFF26A69A);
  static const _bg = Color(0xFFFCE4EC);

  String get _phaseLabel {
    if (isOngoingPeriod || cycleDay <= periodLength) return 'Menstruation';
    final ovulation = cycleLength - 14;
    if (cycleDay >= ovulation - 5 && cycleDay <= ovulation + 1) {
      return 'Fertile Window';
    }
    if (cycleDay == ovulation + 2 || cycleDay == ovulation) {
      return 'Ovulation';
    }
    if (cycleDay < ovulation - 5) return 'Follicular Phase';
    return 'Luteal Phase';
  }

  Color get _phaseColor {
    if (isOngoingPeriod || cycleDay <= periodLength) return _mid;
    final ovulation = cycleLength - 14;
    if (cycleDay >= ovulation - 5 && cycleDay <= ovulation + 1) return _teal;
    return _deep;
  }

  String get _countdownText {
    if (nextPeriodDate == null) return 'Log 2+ periods to predict';
    final diff = nextPeriodDate!
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (diff < -1) return '${diff.abs()} days late';
    if (diff == -1) return 'Period was yesterday';
    if (diff == 0) return 'Period expected today';
    if (diff == 1) return 'Period tomorrow';
    return '$diff days until period';
  }

  @override
  Widget build(BuildContext context) {
    final clampedDay = cycleDay.clamp(1, cycleLength);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(260, 260),
                painter: _CycleRingPainter(
                  cycleDay: clampedDay,
                  cycleLength: cycleLength,
                  periodLength: periodLength,
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Day $cycleDay',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: _deep,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'of $cycleLength',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _phaseColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _phaseLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _phaseColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 140),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _countdownText,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _deep,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(_mid),
            const SizedBox(width: 4),
            Text('Period',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(width: 16),
            _legendDot(_teal),
            const SizedBox(width: 4),
            Text('Fertile',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(width: 16),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _deep, width: 2),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Text('Today',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CycleRingPainter extends CustomPainter {
  final int cycleDay;
  final int cycleLength;
  final int periodLength;

  const _CycleRingPainter({
    required this.cycleDay,
    required this.cycleLength,
    required this.periodLength,
  });

  static const _periodColor = Color(0xFFE91E63);
  static const _fertileColor = Color(0xFF26A69A);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 28.0;
    const strokeWidth = 18.0;

    // ── Background track ─────────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFF3E5F5).withAlpha(120)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final dayAngle = 2 * pi / cycleLength;
    const top = -pi / 2; // day 1 is at the top

    // ── Period arc (days 1..periodLength) ────────────────────────────────────
    _arc(canvas, center, radius, strokeWidth,
        top, periodLength * dayAngle, _periodColor);

    // ── Fertile window arc ───────────────────────────────────────────────────
    final ovulation = cycleLength - 14;
    final fStart = (ovulation - 5).clamp(periodLength + 1, cycleLength - 1);
    final fEnd = (ovulation + 1).clamp(fStart, cycleLength);
    _arc(canvas, center, radius, strokeWidth,
        top + (fStart - 1) * dayAngle,
        (fEnd - fStart + 1) * dayAngle,
        _fertileColor);

    // ── Day tick marks ────────────────────────────────────────────────────────
    final tickPaint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..style = PaintingStyle.fill;
    for (int d = 1; d <= cycleLength; d++) {
      final a = top + (d - 1) * dayAngle;
      canvas.drawCircle(
        Offset(center.dx + radius * cos(a), center.dy + radius * sin(a)),
        2.5,
        tickPaint,
      );
    }

    // ── Current day marker ───────────────────────────────────────────────────
    final curAngle = top + (cycleDay - 1) * dayAngle;
    final mp = Offset(
      center.dx + radius * cos(curAngle),
      center.dy + radius * sin(curAngle),
    );
    // Shadow
    canvas.drawCircle(
        mp,
        13,
        Paint()
          ..color = Colors.black.withAlpha(30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // White fill
    canvas.drawCircle(mp, 11,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    // Border
    canvas.drawCircle(
        mp,
        11,
        Paint()
          ..color = const Color(0xFF880E4F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    // Inner dot
    canvas.drawCircle(mp, 4,
        Paint()
          ..color = const Color(0xFF880E4F)
          ..style = PaintingStyle.fill);
  }

  void _arc(Canvas canvas, Offset center, double radius, double strokeWidth,
      double startAngle, double sweepAngle, Color color) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(_CycleRingPainter old) =>
      old.cycleDay != cycleDay ||
      old.cycleLength != cycleLength ||
      old.periodLength != periodLength;
}
