import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:design_system/design_system.dart';
import '../models/period.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/providers.dart';
import 'auth_screen.dart';
import 'main_screen.dart';

/// Onboarding wizard — 6 steps for new users.
/// Step 0 — Name, Step 1 — Period length, Step 2 — Cycle length,
/// Step 3 — Age, Step 4 — Log recent period, Step 5 — Create account
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;

  final TextEditingController _nameController = TextEditingController();
  int _periodLength = 5;
  int _cycleLength = 28;
  final TextEditingController _ageController = TextEditingController();
  DateTime? _lastPeriodStart;
  bool? _periodIsOngoing;
  DateTime? _lastPeriodEnd;

  // Step 5 — registration
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _regError;

  bool _isSaving = false;

  static const _pink = Color(0xFFE91E63);

  bool get _canProceed {
    if (_step == 0) return _nameController.text.trim().isNotEmpty;
    if (_step == 5) {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text;
      return email.contains('@') && pass.length >= 6 && pass == _confirmPassCtrl.text;
    }
    return true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_step < 5) {
      setState(() { _step++; _regError = null; });
    } else {
      _finish();
    }
  }

  void _onSkip() {
    if (_step == 0 || _step == 5) return;
    _onNext();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodStart ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() {
        _lastPeriodStart = picked;
        if (_lastPeriodEnd != null && !_lastPeriodEnd!.isAfter(picked)) _lastPeriodEnd = null;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final min = _lastPeriodStart ?? DateTime.now().subtract(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodEnd ?? DateTime.now(),
      firstDate: min,
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) setState(() => _lastPeriodEnd = picked);
  }

  Future<void> _finish() async {
    setState(() { _isSaving = true; _regError = null; });
    try {
      // 1. Register with Firebase Auth
      final credential = await ref.read(authServiceProvider).registerWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        username: _nameController.text.trim(),
      );
      final uid = credential.user!.uid;
      final db = FirebaseFirestore.instance;

      // 2. Save profile (hasCompletedOnboarding = true) before auth state triggers _RootRouter
      await db.collection('users').doc(uid).collection('profile').doc('current').set(
        UserProfile(
          name: _nameController.text.trim(),
          periodLength: _periodLength,
          cycleLength: _cycleLength,
          age: int.tryParse(_ageController.text.trim()),
          hasCompletedOnboarding: true,
          notificationsEnabled: true,
        ).toMap(),
      );

      // 3. Seed historical periods if provided
      if (_lastPeriodStart != null) {
        final today = DateTime.now();
        final rawEnd = _lastPeriodStart!.add(Duration(days: _periodLength - 1));
        final cappedEnd = rawEnd.isAfter(today) ? today : rawEnd;
        final DateTime? effectiveEnd = _periodIsOngoing == true
            ? null
            : _lastPeriodEnd ?? cappedEnd;
        final seed = DateTime(_lastPeriodStart!.year, _lastPeriodStart!.month, _lastPeriodStart!.day);
        final cyclesBack = (183 / _cycleLength).ceil();
        final batch = db.batch();
        final periodsRef = db.collection('users').doc(uid).collection('periods');
        for (int n = 0; n <= cyclesBack; n++) {
          final start = seed.subtract(Duration(days: n * _cycleLength));
          if (start.isAfter(DateTime.now())) continue;
          final id = start.millisecondsSinceEpoch.toString();
          final end = n == 0 ? effectiveEnd : start.add(Duration(days: _periodLength - 1));
          batch.set(periodsRef.doc(id), Period(id: id, startDate: start, endDate: end).toMap());
        }
        await batch.commit();
      }

      // 4. Navigate to main, clearing stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) setState(() { _regError = e.toString(); _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = KiwiNovasTheme.of(context).colors;
    return KiwiNovasScaffold(
      body: Column(
        children: [
          KiwiNovasProgressBar(currentStep: _step + 1, totalSteps: 6),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                _buildNameStep(colors),
                _buildPeriodLengthStep(colors),
                _buildCycleLengthStep(colors),
                _buildAgeStep(colors),
                _buildLastPeriodStep(colors),
                _buildRegisterStep(colors),
              ],
            ),
          ),
          _buildBottomBar(colors),
        ],
      ),
    );
  }

  Widget _buildNameStep(KiwiNovasColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_rounded, size: 72, color: colors.primary),
          const SizedBox(height: 24),
          Text('Welcome!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.onSurface, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('This app is for everyone who gets a\nmenstrual cycle. What\'s your name?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.placeholder),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          KiwiNovasTextField(
            controller: _nameController,
            labelText: 'Your name',
            hintText: 'e.g. Sarah',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen())),
            child: const Text('Already have an account? Log in',
                style: TextStyle(color: _pink, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodLengthStep(KiwiNovasColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.water_drop_outlined, size: 72, color: colors.primary),
          const SizedBox(height: 24),
          Text('How many days does your\nperiod usually last?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.onSurface, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Text('$_periodLength days',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: colors.primary, fontWeight: FontWeight.bold)),
          Slider(
            value: _periodLength.toDouble(), min: 1, max: 30, divisions: 29,
            activeColor: colors.primary,
            onChanged: (v) => setState(() => _periodLength = v.round()),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('1 day', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.placeholder)),
            Text('30 days', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.placeholder)),
          ]),
        ],
      ),
    );
  }

  Widget _buildCycleLengthStep(KiwiNovasColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, size: 72, color: colors.primary),
          const SizedBox(height: 24),
          Text('How many days between\nyour periods?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.onSurface, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Days from the start of one period\nto the start of the next.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.placeholder),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text('$_cycleLength days',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: colors.primary, fontWeight: FontWeight.bold)),
          Slider(
            value: _cycleLength.toDouble(), min: 20, max: 45, divisions: 25,
            activeColor: colors.primary,
            onChanged: (v) => setState(() => _cycleLength = v.round()),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('20 days', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.placeholder)),
            Text('45 days', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.placeholder)),
          ]),
        ],
      ),
    );
  }

  Widget _buildAgeStep(KiwiNovasColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 72, color: colors.primary),
          const SizedBox(height: 24),
          Text('How old are you?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.onSurface, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Optional — helps personalise your experience.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.placeholder),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          KiwiNovasTextField(
            controller: _ageController,
            labelText: 'Your age (optional)',
            hintText: 'e.g. 28',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildLastPeriodStep(KiwiNovasColors colors) {
    final fmt = DateFormat('MMMM d, yyyy');
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Column(children: [
            Icon(Icons.water_drop, size: 56, color: colors.primary),
            const SizedBox(height: 16),
            Text('Log your most recent period',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onSurface, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('We\'ll use this to fill in the past 6 months\nautomatically. Everything here is optional.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.placeholder),
                textAlign: TextAlign.center),
          ])),
          const SizedBox(height: 28),
          _sectionLabel('When was your last period?', colors),
          const SizedBox(height: 8),
          _dateTile(
            icon: Icons.play_circle_rounded, iconColor: colors.primary,
            label: _lastPeriodStart != null ? fmt.format(_lastPeriodStart!) : 'Choose start date',
            isSet: _lastPeriodStart != null, onTap: _pickStartDate, colors: colors,
          ),
          if (_lastPeriodStart != null) ...[
            const SizedBox(height: 24),
            _sectionLabel('Is it still going?', colors),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _statusCard(
                icon: Icons.water_drop, label: 'Still on\nmy period',
                selected: _periodIsOngoing == true, selectedColor: colors.primary,
                onTap: () => setState(() { _periodIsOngoing = true; _lastPeriodEnd = null; }),
                colors: colors,
              )),
              const SizedBox(width: 12),
              Expanded(child: _statusCard(
                icon: Icons.check_circle_rounded, label: 'Period\nhas ended',
                selected: _periodIsOngoing == false, selectedColor: colors.accent,
                onTap: () => setState(() => _periodIsOngoing = false),
                colors: colors,
              )),
            ]),
            if (_periodIsOngoing == false) ...[
              const SizedBox(height: 24),
              _sectionLabel('When did it end?', colors),
              const SizedBox(height: 8),
              _dateTile(
                icon: Icons.stop_circle_rounded, iconColor: colors.accent,
                label: _lastPeriodEnd != null ? fmt.format(_lastPeriodEnd!) : 'Choose end date (optional)',
                isSet: _lastPeriodEnd != null, onTap: _pickEndDate, colors: colors,
              ),
              if (_lastPeriodEnd == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text('If left empty we\'ll estimate from your period length.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.placeholder, fontStyle: FontStyle.italic)),
                ),
            ],
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRegisterStep(KiwiNovasColors colors) {
    const deep = Color(0xFF880E4F);
    const mid = Color(0xFFE91E63);
    const light = Color(0xFFF48FB1);
    const bg = Color(0xFFFCE4EC);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Gradient hero header ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [deep, mid, light],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
            child: Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withAlpha(100), width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/hibiscus.png', fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.local_florist, color: Colors.white, size: 36)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Create Account',
                  style: TextStyle(color: Colors.white, fontSize: 24,
                      fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your data is private & securely stored.',
                  style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 13),
                ),
              ],
            ),
          ),

          // ── Form card ───────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            transform: Matrix4.translationValues(0, -20, 0),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Email
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: const Icon(Icons.email_outlined, color: mid, size: 20),
                    filled: true, fillColor: bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: mid, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                // Password
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: 'At least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline, color: mid, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: mid, size: 20),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    filled: true, fillColor: bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: mid, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                // Confirm password
                TextField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: mid, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: mid, size: 20),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    errorText: _confirmPassCtrl.text.isNotEmpty && _confirmPassCtrl.text != _passCtrl.text ? 'Passwords do not match' : null,
                    filled: true, fillColor: bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: mid, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),

                if (_regError != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(_regError!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                            textAlign: TextAlign.center),
                        if (_regError!.contains('email-already-in-use') ||
                            _regError!.contains('already exists')) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.login_rounded, size: 16),
                            label: const Text('Log In Instead',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: mid,
                              side: BorderSide(color: mid, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AuthScreen()),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, KiwiNovasColors colors) => Text(text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colors.placeholder, fontWeight: FontWeight.w600, letterSpacing: 0.4));

  Widget _dateTile({required IconData icon, required Color iconColor, required String label,
      required bool isSet, required VoidCallback onTap, required KiwiNovasColors colors}) {
    return Material(
      color: colors.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14), onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withAlpha(24), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSet ? colors.onSurface : colors.placeholder,
                    fontWeight: isSet ? FontWeight.w600 : FontWeight.normal))),
            Icon(Icons.chevron_right, color: colors.placeholder, size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _statusCard({required IconData icon, required String label, required bool selected,
      required Color selectedColor, required VoidCallback onTap, required KiwiNovasColors colors}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withAlpha(28) : colors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? selectedColor : colors.cardBg, width: 2),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? selectedColor : colors.placeholder, size: 30),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? selectedColor : colors.placeholder,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }

  Widget _buildBottomBar(KiwiNovasColors colors) {
    final isLastStep = _step == 5;
    final showSkip = _step > 0 && _step < 5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Row(children: [
        if (showSkip) ...[
          Expanded(child: KiwiNovasButton(
            text: _step == 4 ? 'Skip & Next' : 'Skip',
            variant: KiwiNovasButtonVariant.text,
            onPressed: _isSaving ? null : _onSkip,
          )),
          const SizedBox(width: 16),
        ],
        Expanded(
          flex: showSkip ? 2 : 1,
          child: KiwiNovasGradientButton(
            text: isLastStep ? 'Create Account' : 'Next',
            isLoading: _isSaving,
            onPressed: (_isSaving || !_canProceed) ? null : _onNext,
          ),
        ),
      ]),
    );
  }
}
