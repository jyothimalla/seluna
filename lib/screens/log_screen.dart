import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:design_system/design_system.dart';
import '../models/period.dart';
import '../services/providers.dart';

/// E1: Period log list — edit start date (E1-S1), delete log (E1-S2),
/// confirmation SnackBars (E1-S3).
class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(periodServiceProvider);
    final periods = service.periods.reversed.toList();

    return KiwiNovasScaffold(
      appBar: KiwiNovasAppBar(title: const Text('Period Log')),
      body: periods.isEmpty
          ? KiwiNovasEmptyState(
              icon: Icons.water_drop_outlined,
              title: 'No periods logged yet',
              message: 'Go to Home or Calendar to start logging.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: periods.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _PeriodTile(period: periods[i]),
            ),
    );
  }
}

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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.water_drop, color: colors.primary, size: 20),
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
                    Text(
                      lengthLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.placeholder,
                          ),
                    ),
                  if (period.isOngoing)
                    Text(
                      'Ongoing',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.accent,
                          ),
                    ),
                ],
              ),
            ),
            // E1-S1: Edit button
            IconButton(
              icon: Icon(Icons.edit_outlined, color: colors.placeholder),
              tooltip: 'Edit start date',
              onPressed: () => _showEditDialog(context, ref),
            ),
            // E1-S2: Delete button
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.danger),
              tooltip: 'Delete log',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  // ── E1-S1: Edit period start date ────────────────────────────────────────
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Start date updated to ${DateFormat('MMM d, yyyy').format(picked)}.',
          ),
        ),
      );
    }
  }

  // ── E1-S2: Delete period log with confirmation ───────────────────────────
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete period log?'),
        content: const Text(
          'This will remove the log permanently and recalculate predictions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(periodServiceProvider).deletePeriod(period);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Period log deleted.')),
      );
    }
  }
}
