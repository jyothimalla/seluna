import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:design_system/design_system.dart';
import '../models/period.dart';
import '../services/providers.dart';
import '../widgets/cycle_ring.dart';

/// Home dashboard — cycle ring + quick log.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = KiwiNovasTheme.of(context).colors;
    final service = ref.watch(periodServiceProvider);
    final nextDate = ref.watch(nextPredictedDateProvider);
    final today = DateTime.now();
    final ongoing = service.ongoingPeriod;
    final profile = service.profile;
    final periods = service.periods;

    // Calculate current cycle day from last period start
    final cycleStart = periods.isNotEmpty ? periods.last.startDate : null;
    final rawDay = cycleStart != null
        ? DateTime(today.year, today.month, today.day)
                .difference(DateTime(
                    cycleStart.year, cycleStart.month, cycleStart.day))
                .inDays +
            1
        : 1;
    final cycleDay = rawDay.clamp(1, profile.cycleLength * 2);

    return KiwiNovasScaffold(
      appBar: KiwiNovasAppBar(title: const Text('Seluna')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _greetingRow(context, colors, today, profile.name),
            const SizedBox(height: 24),

            // ── Cycle ring card ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE91E63).withAlpha(18),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CycleRingWidget(
                    cycleDay: cycleDay,
                    cycleLength: profile.cycleLength,
                    periodLength: profile.periodLength,
                    nextPeriodDate: nextDate,
                    today: today,
                    isOngoingPeriod: ongoing != null,
                  ),
                  if (cycleStart != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Cycle started ${DateFormat('MMM d').format(cycleStart)}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Quick log card ────────────────────────────────────────────
            _quickLogCard(context, colors, ongoing, today, ref),
          ],
        ),
      ),
    );
  }

  Widget _greetingRow(BuildContext context, KiwiNovasColors colors,
      DateTime today, String? name) {
    final hour = today.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final displayName = name != null && name.isNotEmpty ? ', $name' : '';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting$displayName',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE, MMMM d').format(today),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.placeholder,
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFCE4EC),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite, color: Color(0xFFE91E63), size: 22),
        ),
      ],
    );
  }

  Widget _quickLogCard(
    BuildContext context,
    KiwiNovasColors colors,
    Period? ongoing,
    DateTime today,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Log',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: KiwiNovasGradientButton(
              text: ongoing != null ? 'End Period Today' : 'Start Period Today',
              onPressed: () => _quickLog(context, ref, ongoing != null, today),
            ),
          ),
          if (ongoing != null) ...[
            const SizedBox(height: 8),
            Text(
              'Ongoing since ${DateFormat('MMM d').format(ongoing.startDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.placeholder,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _quickLog(BuildContext context, WidgetRef ref,
      bool isOngoing, DateTime today) async {
    final service = ref.read(periodServiceProvider);
    if (isOngoing) {
      await service.endPeriod(today);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Period ended. Feel better soon!')),
        );
      }
    } else {
      await service.startPeriod(today);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Period logged successfully.')),
        );
      }
    }
  }
}
