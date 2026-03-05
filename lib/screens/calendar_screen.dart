import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:design_system/design_system.dart';
import '../models/period.dart';
import '../services/providers.dart';
import 'profile_screen.dart' show buildProfileAvatar, ProfileScreen;
import 'chatbot_screen.dart';

// ── Soft rose palette ─────────────────────────────────────────────────────────
// Classic feminine rose: deep rose → medium rose → soft blush
const _kHibiscusDeep   = Color(0xFF880E4F); // deep rose
const _kHibiscusMid    = Color(0xFFE91E63); // medium rose / primary
const _kPeriodPink     = Color(0xFFF48FB1); // soft blush / light pink

/// Home screen: rich gradient header · status card · quick stats ·
/// monthly calendar · legend · reserved space for future additions.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _focusedDay = DateTime.now();

  // ── Greeting helper ──────────────────────────────────────────────────────
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(periodServiceProvider);
    final periodDates = service.allPeriodDates;
    final predictedDates = service.predictedPeriodDates;
    final profile = service.profile;
    final nextDate = service.nextPredictedDate;
    final hasOngoing = service.ongoingPeriod != null;
    final ongoingDay = hasOngoing
        ? DateTime.now()
                .difference(service.ongoingPeriod!.startDate)
                .inDays +
            1
        : null;
    final isOverdue = service.hasForgottenPeriod;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF1A0508) : const Color(0xFFFCE4EC);

    final name = (profile.name != null && profile.name!.isNotEmpty)
        ? profile.name!
        : 'there';

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. HEADER ──────────────────────────────────────────────────
            _buildHeader(context, name, profile, nextDate, hasOngoing, ongoingDay),

            // ── 2. BODY ────────────────────────────────────────────────────
            _buildBody(
                context, service, nextDate, hasOngoing, isOverdue, isDark),

            const SizedBox(height: 8),

            // ── 3. CALENDAR ────────────────────────────────────────────────
            _buildCalendarSection(
                context, periodDates, predictedDates, isDark),

            const SizedBox(height: 20),

            // ── 4. INSIGHTS ────────────────────────────────────────────────
            _buildFutureSection(context, service, isDark),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String name, dynamic profile,
      DateTime? nextDate, bool hasOngoing, int? ongoingDay) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kHibiscusDeep, _kHibiscusMid, _kPeriodPink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Hibiscus flower image — faded in the bottom-right corner
            Positioned(
              right: -30,
              bottom: -20,
              width: 180,
              height: 180,
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/hibiscus.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            // Foreground content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: greeting + name + date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('🌸 ', style: TextStyle(fontSize: 14)),
                              Text(
                                _greeting(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  color: Colors.white54, size: 13),
                              const SizedBox(width: 5),
                              Text(
                                DateFormat('EEEE, MMM d').format(DateTime.now()),
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right: FAQ + avatar + status badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // FAQ / chatbot button
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const ChatbotScreen()),
                              ),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withAlpha(25),
                                  border: Border.all(
                                      color: Colors.white.withAlpha(100),
                                      width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.help_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Profile avatar
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const ProfileScreen()),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(40),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: buildProfileAvatar(
                                  photoPath: profile.photoPath,
                                  avatarIndex: profile.avatarIndex,
                                  radius: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (hasOngoing)
                          _runningBadge(context, ongoingDay ?? 1)
                        else if (nextDate != null)
                          _daysUntilBadge(context, nextDate),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. BODY — status card + quick stats
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBody(
    BuildContext context,
    dynamic service,
    DateTime? nextDate,
    bool hasOngoing,
    bool isOverdue,
    bool isDark,
  ) {
    final colors = KiwiNovasTheme.of(context).colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        children: [
          // Status card (pulled up to overlap header bottom curve)
          Transform.translate(
            offset: const Offset(0, -22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildStatusCard(context, colors, service, nextDate,
                      hasOngoing, isOverdue),
                  if (isOverdue) ...[
                    const SizedBox(height: 8),
                    _overdueBanner(context, colors, service),
                  ],
                ],
              ),
            ),
          ),

          // Quick stats row (adjust top margin to account for transform)
          Transform.translate(
            offset: Offset(
                0, isOverdue || hasOngoing || nextDate != null ? 0 : -16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: _buildQuickStats(context, service, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
      BuildContext context, dynamic service, bool isDark) {
    final cardColor = isDark ? const Color(0xFF2A0A14) : Colors.white;

    // Cycle day: days since last period started
    int? cycleDay;
    final periods = service.periods as List;
    if (periods.isNotEmpty) {
      cycleDay =
          DateTime.now().difference(periods.last.startDate as DateTime).inDays + 1;
    }

    // Days until next predicted period
    final nextDate = service.nextPredictedDate as DateTime?;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final daysUntilNext = nextDate?.difference(today).inDays;

    // Last period date label
    String lastLabel = '—';
    if (periods.isNotEmpty) {
      final last = periods.last.startDate as DateTime;
      lastLabel =
          '${DateTime.now().difference(last).inDays}d ago';
    }

    return Row(
      children: [
        _quickStatCard(
          context,
          icon: Icons.history_rounded,
          iconColor: _kHibiscusMid,
          label: 'Last Period',
          value: lastLabel,
          cardColor: cardColor,
        ),
        const SizedBox(width: 10),
        _quickStatCard(
          context,
          icon: Icons.today_outlined,
          iconColor: _kHibiscusDeep,
          label: 'Cycle Day',
          value: cycleDay != null ? '#$cycleDay' : '—',
          cardColor: cardColor,
        ),
        const SizedBox(width: 10),
        _quickStatCard(
          context,
          icon: Icons.arrow_forward_rounded,
          iconColor: _kPeriodPink,
          label: 'Next In',
          value: daysUntilNext != null
              ? (daysUntilNext <= 0 ? 'Today!' : '${daysUntilNext}d')
              : '—',
          cardColor: cardColor,
        ),
      ],
    );
  }

  Widget _quickStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color cardColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: iconColor.withAlpha(30),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: iconColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. CALENDAR SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCalendarSection(BuildContext context, Set<DateTime> periodDates,
      Set<DateTime> predictedDates, bool isDark) {
    final cardColor = isDark ? const Color(0xFF2A0A14) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          _sectionLabel(context, 'Calendar', Icons.calendar_month_outlined,
              _kHibiscusMid),
          const SizedBox(height: 10),

          // Calendar card
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _kPeriodPink.withAlpha(20),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              sixWeekMonthsEnforced: true,
              rowHeight: 44,
              selectedDayPredicate: (_) => false,
              onPageChanged: (day) => setState(() => _focusedDay = day),
              onDaySelected: (selected, focused) {
                setState(() => _focusedDay = focused);
                final service = ref.read(periodServiceProvider);
                _onDayTapped(context, selected, service);
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  border: Border.fromBorderSide(
                      BorderSide(color: _kPeriodPink, width: 2)),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: _kPeriodPink,
                  fontWeight: FontWeight.bold,
                ),
                outsideDaysVisible: false,
                rowDecoration: BoxDecoration(),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(fontWeight: FontWeight.w700),
                leftChevronIcon: const Icon(Icons.chevron_left,
                    color: _kPeriodPink, size: 20),
                rightChevronIcon: const Icon(Icons.chevron_right,
                    color: _kPeriodPink, size: 20),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                    color: _kPeriodPink, fontWeight: FontWeight.w600),
                weekendStyle: TextStyle(
                    color: Color(0xFFAD1457), fontWeight: FontWeight.w600),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (ctx, day, focused) {
                  final norm = DateTime(day.year, day.month, day.day);
                  if (periodDates.contains(norm)) {
                    return _periodCell(ctx, day, periodDates: periodDates);
                  }
                  if (predictedDates.contains(norm)) {
                    return _predictedCell(ctx, day);
                  }
                  return null;
                },
                todayBuilder: (ctx, day, focused) {
                  final norm = DateTime(day.year, day.month, day.day);
                  if (periodDates.contains(norm)) {
                    return _periodCell(ctx, day,
                        periodDates: periodDates, isToday: true);
                  }
                  if (predictedDates.contains(norm)) {
                    return _predictedCell(ctx, day, isToday: true);
                  }
                  return _todayCell(ctx, day);
                },
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                      color: _kPeriodPink, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('Period',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 16),
                const Icon(Icons.water_drop, color: _kPeriodPink, size: 12),
                const SizedBox(width: 6),
                Text('Predicted',
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text(
                  'Tap a date to log',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. INSIGHTS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFutureSection(
      BuildContext context, dynamic service, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'Insights', Icons.auto_awesome_outlined,
              _kHibiscusMid),
          const SizedBox(height: 10),
          _buildInsightStats(context, service, isDark),
          const SizedBox(height: 12),
          _buildRegularityCard(context, service, isDark),
          const SizedBox(height: 12),
          _buildCycleTip(context, service, isDark),
        ],
      ),
    );
  }

  // ── Insight stat cards ────────────────────────────────────────────────────
  Widget _buildInsightStats(
      BuildContext context, dynamic service, bool isDark) {
    final cardColor = isDark ? const Color(0xFF2A0A14) : Colors.white;
    final avgCycle = service.averageCycleLength as double?;
    final avgPeriod = service.averagePeriodLength as double?;
    final count = (service.periods as List).length;

    return Row(
      children: [
        _insightStatCard(
          context,
          cardColor: cardColor,
          icon: Icons.loop_rounded,
          iconColor: _kHibiscusMid,
          label: 'Avg Cycle',
          value: avgCycle != null ? '${avgCycle.round()}d' : '—',
          sub: avgCycle != null ? 'days per cycle' : 'log more periods',
        ),
        const SizedBox(width: 10),
        _insightStatCard(
          context,
          cardColor: cardColor,
          icon: Icons.water_drop_outlined,
          iconColor: _kPeriodPink,
          label: 'Avg Period',
          value: avgPeriod != null ? '${avgPeriod.round()}d' : '—',
          sub: avgPeriod != null ? 'days of flow' : 'log more periods',
        ),
        const SizedBox(width: 10),
        _insightStatCard(
          context,
          cardColor: cardColor,
          icon: Icons.event_note_outlined,
          iconColor: _kHibiscusDeep,
          label: 'Logged',
          value: '$count',
          sub: count == 1 ? 'period tracked' : 'periods tracked',
        ),
      ],
    );
  }

  Widget _insightStatCard(
    BuildContext context, {
    required Color cardColor,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: iconColor.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: iconColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Regularity card ───────────────────────────────────────────────────────
  Widget _buildRegularityCard(
      BuildContext context, dynamic service, bool isDark) {
    final isRegular = service.isRegularCycle as bool?;
    final cardColor = isDark ? const Color(0xFF2A0A14) : Colors.white;

    if (isRegular == null) {
      // Not enough data yet
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.hourglass_empty_rounded,
                  color: Colors.grey.shade400, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cycle Regularity',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Log at least 3 periods to see your regularity pattern.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final accent = isRegular ? const Color(0xFF43A047) : Colors.orange.shade700;
    final bgAccent = isRegular
        ? const Color(0xFF43A047).withAlpha(12)
        : Colors.orange.withAlpha(12);
    final icon = isRegular ? Icons.check_circle_outline : Icons.sync_problem_outlined;
    final title = isRegular ? 'Regular Cycle ✓' : 'Irregular Cycle';
    final message = isRegular
        ? 'Your cycles are consistent — great for predicting your next period accurately!'
        : 'Your cycles vary by more than 7 days. This is common and usually nothing to worry about.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A0A14) : bgAccent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withAlpha(22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cycle tip ─────────────────────────────────────────────────────────────
  Widget _buildCycleTip(BuildContext context, dynamic service, bool isDark) {
    final periods = service.periods as List;
    final profile = service.profile;
    final cycleLen = profile.cycleLength as int;
    final periodLen = profile.periodLength as int;

    // Work out cycle day
    int? cycleDay;
    DateTime? lastStart;
    if (periods.isNotEmpty) {
      lastStart = periods.last.startDate as DateTime;
      cycleDay = DateTime.now().difference(lastStart).inDays + 1;
    }

    final String tipEmoji;
    final String tipTitle;
    final String tipBody;
    final Color tipColor;

    if (cycleDay == null) {
      tipEmoji = '🌸';
      tipTitle = 'Start tracking';
      tipBody =
          'Tap any past date on the calendar to log your first period. The more you track, the more accurate your predictions become!';
      tipColor = _kHibiscusMid;
    } else if (cycleDay <= periodLen) {
      // During period
      tipEmoji = '🌡️';
      tipTitle = 'During your period';
      tipBody =
          'Stay hydrated and consider a warm heating pad for cramps. Light movement like walking can help ease discomfort.';
      tipColor = _kPeriodPink;
    } else if (cycleDay <= 13) {
      // Follicular phase
      tipEmoji = '⚡';
      tipTitle = 'Energy rising!';
      tipBody =
          'Estrogen is climbing — you may feel more focused and energetic. Great time for activities you enjoy!';
      tipColor = const Color(0xFF1976D2);
    } else if (cycleDay <= 16) {
      // Ovulation window
      tipEmoji = '🌟';
      tipTitle = 'Peak energy phase';
      tipBody =
          'You\'re likely at your most energetic. Social activities, sport, or creative projects may feel effortless right now.';
      tipColor = const Color(0xFFFF7043);
    } else if (cycleDay <= cycleLen - 4) {
      // Luteal phase
      tipEmoji = '🍓';
      tipTitle = 'Luteal phase';
      tipBody =
          'Your body is preparing. Eating iron-rich foods (spinach, lentils, red meat) and reducing caffeine can help manage PMS symptoms.';
      tipColor = const Color(0xFF7B1FA2);
    } else {
      // Pre-period
      tipEmoji = '🌸';
      tipTitle = 'Period approaching';
      tipBody =
          'Your next period is coming soon. Keep pain relief handy and make sure you have your period supplies ready!';
      tipColor = _kHibiscusMid;
    }

    final cardBg = isDark ? const Color(0xFF2A0A14) : tipColor.withAlpha(10);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tipColor.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: tipColor.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tipColor.withAlpha(22),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(tipEmoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tipTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: tipColor,
                      ),
                    ),
                    if (cycleDay != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tipColor.withAlpha(18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Day $cycleDay',
                          style: TextStyle(
                            color: tipColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tipBody,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared section label ──────────────────────────────────────────────────
  Widget _sectionLabel(
      BuildContext context, String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withAlpha(22),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
      ],
    );
  }

  // ── Cycle timeline bar ────────────────────────────────────────────────────
  /// Segmented bar: dark rose = period phase, semi-transparent = rest of cycle,
  /// with a white marker at the current day position.
  Widget _cyclePeriodBar(int dayNum, int periodLen, int cycleLen) {
    return LayoutBuilder(builder: (context, constraints) {
      final totalWidth = constraints.maxWidth;
      final dayWidth = totalWidth / cycleLen;
      // Zone: expected period length (lighter)
      final periodWidth = (periodLen * dayWidth).clamp(0.0, totalWidth);
      // Progress: actual days so far today (bright)
      final progressWidth = (dayNum * dayWidth).clamp(0.0, totalWidth);
      // Marker line at today's position
      final markerX = ((dayNum - 1) * dayWidth).clamp(0.0, totalWidth - 3);

      return SizedBox(
        height: 10,
        child: Stack(
          children: [
            // Background track (full cycle) — faintest
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(color: Colors.white.withAlpha(25)),
              ),
            ),
            // Period zone (first periodLen days) — medium
            Positioned(
              left: 0, top: 0, bottom: 0, width: periodWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(color: Colors.white.withAlpha(70)),
              ),
            ),
            // Today's progress (Day 1 → dayNum) — brightest
            Positioned(
              left: 0, top: 0, bottom: 0, width: progressWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(color: Colors.white.withAlpha(220)),
              ),
            ),
            // Today marker
            Positioned(
              left: markerX, top: 0, bottom: 0, width: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: _kHibiscusDeep,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Header badges ──────────────────────────────────────────────────────────
  Widget _runningBadge(BuildContext context, int dayNum) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_kHibiscusMid, _kPeriodPink]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPeriodPink.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '🩸 Period Day $dayNum',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Widget _daysUntilBadge(BuildContext context, DateTime nextDate) {
    final diff = _daysUntil(nextDate);
    final label = diff == 0
        ? 'Today!'
        : diff < 0
            ? '${diff.abs()}d late'
            : 'in ${diff}d';
    final isUrgent = diff <= 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent
            ? _kPeriodPink.withAlpha(28)
            : Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent
              ? _kPeriodPink.withAlpha(140)
              : Colors.white.withAlpha(80),
          width: 1.5,
        ),
      ),
      child: Text(
        '🌸 $label',
        style: TextStyle(
          color: isUrgent ? _kPeriodPink : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  // ── Status card ───────────────────────────────────────────────────────────
  Widget _buildStatusCard(
    BuildContext context,
    KiwiNovasColors colors,
    dynamic service,
    DateTime? nextDate,
    bool hasOngoing,
    bool isOverdue,
  ) {
    if (isOverdue) return const SizedBox.shrink();

    if (hasOngoing) {
      final Period ongoing = service.ongoingPeriod as Period;
      final dayNum =
          DateTime.now().difference(ongoing.startDate).inDays + 1;
      final periodLen = service.profile.periodLength;

      final cycleLen = service.profile.cycleLength;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kHibiscusDeep, _kHibiscusMid, _kPeriodPink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E8C).withAlpha(110),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                const Text('🩸 ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Period Day $dayNum',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18),
                      ),
                      Text(
                        'Expected to last ~$periodLen days',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Day badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white54, width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$dayNum / $periodLen',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14),
                      ),
                      const Text(
                        'period days',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Cycle timeline bar
            _cyclePeriodBar(dayNum, periodLen, cycleLen),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Day 1',
                    style:
                        TextStyle(color: Colors.white60, fontSize: 10)),
                Text('Day $dayNum ← today',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.w600)),
                Text('Day $cycleLen',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 10)),
              ],
            ),
          ],
        ),
      );
    }

    if (nextDate != null) {
      final diff = _daysUntil(nextDate);


      if (diff >= 0 && diff <= 2) {
        final msg = diff == 0
            ? 'Your period may start today!'
            : diff == 1
                ? 'Your period may start tomorrow!'
                : 'Your period may start in 2 days!';
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kHibiscusMid, _kPeriodPink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _kPeriodPink.withAlpha(90),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(30),
                  border: Border.all(color: Colors.white54, width: 2),
                ),
                child: const Center(
                    child: Text('🌸', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Period coming soon!',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(msg,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      if (diff < 0) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade700, Colors.amber.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withAlpha(80),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(30),
                  border: Border.all(color: Colors.white54, width: 2),
                ),
                child: const Center(
                    child: Text('⏰', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Period may be late',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${diff.abs()} ${diff.abs() == 1 ? 'day' : 'days'} overdue — tap a date to log',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  // ── Day cell builders ─────────────────────────────────────────────────────
  Widget _periodCell(BuildContext context, DateTime day,
      {required Set<DateTime> periodDates, bool isToday = false}) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _kHibiscusMid,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: Colors.white, width: 2.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: _kHibiscusMid.withAlpha(70),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _predictedCell(BuildContext context, DateTime day,
      {bool isToday = false}) {
    return Center(
      child: SizedBox(
        width: 34,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.water_drop,
              color: isToday
                  ? _kHibiscusMid
                  : _kPeriodPink.withAlpha(isToday ? 255 : 150),
              size: 36,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isToday ? Colors.white : _kHibiscusMid,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayCell(BuildContext context, DateTime day) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          border: Border.all(color: _kPeriodPink, width: 2),
          shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: const TextStyle(
            color: _kPeriodPink, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── Overdue banner ────────────────────────────────────────────────────────
  Widget _overdueBanner(
      BuildContext context, KiwiNovasColors colors, dynamic service) {
    final Period ongoing = service.ongoingPeriod as Period;
    final days = DateTime.now().difference(ongoing.startDate).inDays;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Period running for $days days — did you forget to end it?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade900,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _showEndDialog(context, service),
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Update',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Smart dialogs ─────────────────────────────────────────────────────────
  Future<void> _showEndDialog(BuildContext context, dynamic service) async {
    final Period? ongoing = service.ongoingPeriod as Period?;
    if (ongoing == null) return;

    final profile = service.profile;
    final isOverdue = service.hasForgottenPeriod as bool;
    final today = DateTime.now();

    final suggestedEnd = isOverdue
        ? ongoing.startDate.add(Duration(days: profile.periodLength - 1))
        : today;
    final initialDate =
        suggestedEnd.isAfter(today) ? today : suggestedEnd;
    final firstDate = DateTime(ongoing.startDate.year,
        ongoing.startDate.month, ongoing.startDate.day);

    if (isOverdue && context.mounted) {
      final days = today.difference(ongoing.startDate).inDays;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Period has been running $days days — longer than your usual '
            '${profile.periodLength} days. Pick the actual end date.'),
        backgroundColor: Colors.amber.shade700,
        duration: const Duration(seconds: 4),
      ));
    }

    if (!context.mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: today,
      helpText: 'When did your period end?',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null || !context.mounted) return;
    await ref.read(periodServiceProvider).endPeriod(picked);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Period ended on ${DateFormat('MMM d').format(picked)}'),
      ));
    }
  }

  // ── Day tap ───────────────────────────────────────────────────────────────
  Future<void> _onDayTapped(
      BuildContext context, DateTime day, dynamic service) async {
    final today = DateTime.now();
    final norm = DateTime(day.year, day.month, day.day);
    final todayNorm = DateTime(today.year, today.month, today.day);

    if (norm.isAfter(todayNorm)) return;

    final ongoingPeriod = service.ongoingPeriod;

    if (ongoingPeriod != null) {
      final ongoingStart = DateTime(
        ongoingPeriod.startDate.year,
        ongoingPeriod.startDate.month,
        ongoingPeriod.startDate.day,
      );

      if (norm.isBefore(ongoingStart)) {
        final existing = service.periodForDate(day);
        if (existing != null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('This day is already logged as a period.'),
              duration: Duration(seconds: 2),
            ));
          }
        } else {
          await _editOngoingStartDate(context, ongoingPeriod, day);
        }
      } else {
        await _showEndDialogForDate(context, service, day);
      }
    } else {
      final period = service.periodForDate(day);
      if (period != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('This day is already logged as a period.'),
            duration: Duration(seconds: 2),
          ));
        }
      } else {
        await _startPeriodOnDate(context, day);
      }
    }
  }

  Future<void> _editOngoingStartDate(
      BuildContext context, dynamic ongoingPeriod, DateTime newStart) async {
    final newLabel = DateFormat('MMM d').format(newStart);
    final oldLabel = DateFormat('MMM d').format(ongoingPeriod.startDate);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Period Start'),
        content: Text(
          'Change your period start from $oldLabel to $newLabel?\n\n'
          'Any period logged between $newLabel and $oldLabel will be removed.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kPeriodPink),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Change',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final svc = ref.read(periodServiceProvider);
    final ongoingStart = DateTime(
      ongoingPeriod.startDate.year,
      ongoingPeriod.startDate.month,
      ongoingPeriod.startDate.day,
    );
    final newStartNorm =
        DateTime(newStart.year, newStart.month, newStart.day);

    final conflicting = svc.periods.where((p) {
      if (p.isOngoing) return false;
      final pStart =
          DateTime(p.startDate.year, p.startDate.month, p.startDate.day);
      return !pStart.isBefore(newStartNorm) && pStart.isBefore(ongoingStart);
    }).toList();

    for (final p in conflicting) {
      await svc.deletePeriod(p);
    }

    await svc.editPeriodStart(ongoingPeriod, newStart);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Period start changed to $newLabel')));
    }
  }

  Future<void> _startPeriodOnDate(
      BuildContext context, DateTime day) async {
    final label = DateFormat('MMM d').format(day);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Period'),
        content: Text('Start your period on $label?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kPeriodPink),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Start', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(periodServiceProvider).startPeriod(day);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Period started on $label')));
    }
  }

  Future<void> _showEndDialogForDate(
      BuildContext context, dynamic service, DateTime endDay) async {
    final label = DateFormat('MMM d').format(endDay);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Period'),
        content: Text('End your current period on $label?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kPeriodPink),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(periodServiceProvider).endPeriod(endDay);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Period ended on $label')));
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  int _daysUntil(DateTime nextDate) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final next = DateTime(nextDate.year, nextDate.month, nextDate.day);
    return next.difference(today).inDays;
  }
}
