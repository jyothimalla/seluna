import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:design_system/design_system.dart';
import '../models/period.dart';
import '../services/providers.dart';

/// Combined History & Insights screen — period log list with edit/delete
/// (E1) at the top, followed by cycle analysis stats (E4).
class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = KiwiNovasTheme.of(context).colors;
    final service = ref.watch(periodServiceProvider);
    final periods = service.periods.reversed.toList();
    final avgCycle = ref.watch(avgCycleLengthProvider);
    final avgPeriod = ref.watch(avgPeriodLengthProvider);
    final lastCycle = ref.watch(lastCycleLengthProvider);
    final isRegular = ref.watch(isRegularCycleProvider);

    return KiwiNovasScaffold(
      appBar: KiwiNovasAppBar(title: const Text('History & Insights')),
      body: periods.isEmpty
          ? KiwiNovasEmptyState(
              icon: Icons.water_drop_outlined,
              title: 'No periods logged yet',
              message: 'Start logging from the Home screen to see your history and insights here.',
            )
          : CustomScrollView(
              slivers: [
                // ── Cycle Insights ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cycle Insights',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: colors.onBackground,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on ${periods.length} logged period${periods.length == 1 ? '' : 's'}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.placeholder),
                        ),
                        const SizedBox(height: 14),
                        // Regularity banner
                        if (isRegular != null) ...[
                          _regularityBanner(context, colors, isRegular),
                          const SizedBox(height: 12),
                        ],
                        // Stat cards row
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                context, colors,
                                icon: Icons.refresh,
                                label: 'Avg Cycle',
                                value: avgCycle != null
                                    ? '${avgCycle.toStringAsFixed(1)}d'
                                    : '—',
                                hint: 'days between periods',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _statCard(
                                context, colors,
                                icon: Icons.water_drop,
                                label: 'Avg Period',
                                value: avgPeriod != null
                                    ? '${avgPeriod.toStringAsFixed(1)}d'
                                    : '—',
                                hint: 'average period length',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _statCard(
                                context, colors,
                                icon: Icons.history,
                                label: 'Last Cycle',
                                value: lastCycle != null
                                    ? '${lastCycle}d'
                                    : '—',
                                hint: 'most recent cycle',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Section header for log
                        Text(
                          'Period History',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: colors.onBackground,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                // ── Period log list ───────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PeriodTile(period: periods[i]),
                      ),
                      childCount: periods.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _regularityBanner(
      BuildContext context, KiwiNovasColors colors, bool isRegular) {
    final color = isRegular ? colors.primary : colors.accent;
    final icon = isRegular ? Icons.check_circle_outline : Icons.info_outline;
    final text = isRegular ? 'Regular cycles' : 'Irregular cycles';
    final sub = isRegular
        ? 'Lengths are consistent (±7 days).'
        : 'Lengths vary more than 7 days.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        )),
                Text(sub,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    KiwiNovasColors colors, {
    required IconData icon,
    required String label,
    required String value,
    required String hint,
  }) {
    return Card(
      color: colors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colors.placeholder)),
          ],
        ),
      ),
    );
  }
}

// ── Period tile (E1-S1, E1-S2) ────────────────────────────────────────────

class _PeriodTile extends ConsumerWidget {
  final Period period;
  const _PeriodTile({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = KiwiNovasTheme.of(context).colors;
    final fmt = DateFormat('MMM d, yyyy');
    final startLabel = fmt.format(period.startDate);
    final endLabel =
        period.endDate != null ? fmt.format(period.endDate!) : 'Ongoing';
    final lengthLabel = period.endDate != null
        ? '${period.lengthInDays} day${period.lengthInDays == 1 ? '' : 's'}'
        : '';

    return Card(
      color: colors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.water_drop, color: colors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$startLabel → $endLabel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (lengthLabel.isNotEmpty)
                    Text(lengthLabel,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.placeholder,
                                )),
                  if (period.isOngoing)
                    Text('Ongoing',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.accent,
                                )),
                ],
              ),
            ),
            // E1-S1: Edit start date
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  color: colors.placeholder, size: 20),
              tooltip: 'Edit start date',
              onPressed: () => _showEditDialog(context, ref),
            ),
            // E1-S2: Delete log
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: colors.danger, size: 20),
              tooltip: 'Delete log',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: period.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select new start date',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null) return;
    await ref.read(periodServiceProvider).editPeriodStart(period, picked);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Start date updated to ${DateFormat('MMM d, yyyy').format(picked)}.'),
      ));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete period log?'),
        content: const Text(
            'This will remove the log permanently and recalculate predictions.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(periodServiceProvider).deletePeriod(period);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Period log deleted.')));
    }
  }
}
