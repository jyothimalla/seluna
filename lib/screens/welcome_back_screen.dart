import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/providers.dart';
import 'main_screen.dart';
import 'profile_screen.dart';

class WelcomeBackScreen extends ConsumerStatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  ConsumerState<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends ConsumerState<WelcomeBackScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  static const _rose     = Color(0xFFE91E63);
  static const _roseDeep = Color(0xFF880E4F);
  static const _roseSoft = Color(0xFFF48FB1);
  static const _cream    = Color(0xFFFFF8F0);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), _goHome);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => const MainScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(periodServiceProvider);
    final profile = service.profile;
    final name = (profile.name != null && profile.name!.isNotEmpty)
        ? profile.name!
        : 'there';

    final nextDate = service.nextPredictedDate;
    final hasOngoing = service.ongoingPeriod != null;

    String statusText;
    IconData statusIcon;
    Color statusColor;

    if (hasOngoing) {
      final days =
          DateTime.now().difference(service.ongoingPeriod!.startDate).inDays + 1;
      statusText = 'Period day $days';
      statusIcon = Icons.favorite_rounded;
      statusColor = _rose;
    } else if (nextDate != null) {
      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final diff = nextDate.difference(today).inDays;
      if (diff < 0) {
        statusText = '${diff.abs()} days late';
        statusIcon = Icons.schedule_rounded;
        statusColor = Colors.orange.shade700;
      } else if (diff == 0) {
        statusText = 'Expected today';
        statusIcon = Icons.calendar_today_rounded;
        statusColor = _rose;
      } else {
        statusText =
            'Next in $diff ${diff == 1 ? 'day' : 'days'} · ${DateFormat('MMM d').format(nextDate)}';
        statusIcon = Icons.calendar_month_rounded;
        statusColor = _roseDeep;
      }
    } else {
      statusText = 'Log your first period';
      statusIcon = Icons.add_circle_outline_rounded;
      statusColor = _roseSoft;
    }

    return GestureDetector(
      onTap: _goHome,
      child: Scaffold(
        backgroundColor: _cream,
        body: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Stack(
              children: [
                // ── Full-screen hibiscus background ──────────────────────────
                Positioned.fill(
                  child: Image.asset(
                    'assets/hibiscus.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, _, _) => const ColoredBox(color: _cream),
                  ),
                ),

                // ── Gradient overlay — fades image into cream at the bottom ──
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.45, 0.75, 1.0],
                        colors: [
                          Colors.white.withAlpha(30),   // almost clear at top
                          Colors.white.withAlpha(80),   // soft mid-blend
                          _cream.withAlpha(210),        // fades to cream
                          _cream,                       // solid cream at bottom
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Content ───────────────────────────────────────────────────
                SafeArea(
                  child: Column(
                    children: [
                      // KiwiNovas chip top-left
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: _rose.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: _rose.withAlpha(60)),
                              ),
                              child: const Text(
                                'KiwiNovas',
                                style: TextStyle(
                                  color: _roseDeep,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // ── Bottom info panel ─────────────────────────────────
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar + name row
                            Row(
                              children: [
                                buildProfileAvatar(
                                  photoPath: profile.photoPath,
                                  avatarIndex: profile.avatarIndex,
                                  radius: 28,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _greeting(),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: _roseDeep,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Status card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: _rose.withAlpha(18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(20),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(statusIcon,
                                        color: statusColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Cycle Status',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          statusText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Continue button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _goHome,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _rose,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Let's go",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                'or tap anywhere to continue',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
