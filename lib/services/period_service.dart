import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/period.dart';
import '../models/user_profile.dart';

class PeriodService extends ChangeNotifier {
  final String userId;
  final FirebaseFirestore _db;

  List<Period> _periods = [];
  UserProfile _profile = const UserProfile();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _periodsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  PeriodService({required this.userId})
      : _db = FirebaseFirestore.instance {
    if (userId.isNotEmpty) _initListeners();
  }

  // ── Firestore refs ────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _periodsRef =>
      _db.collection('users').doc(userId).collection('periods');

  DocumentReference<Map<String, dynamic>> get _profileRef =>
      _db.collection('users').doc(userId).collection('profile').doc('current');

  // ── Real-time listeners ───────────────────────────────────────────────────

  void _initListeners() {
    _periodsSub = _periodsRef.snapshots().listen((snap) {
      _periods = snap.docs
          .map((d) => Period.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      notifyListeners();
    });

    _profileSub = _profileRef.snapshots().listen((snap) {
      if (snap.exists && snap.data() != null) {
        _profile = UserProfile.fromMap(snap.data()!);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _periodsSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  // ── Periods ───────────────────────────────────────────────────────────────

  List<Period> get periods => _periods;

  Period? get ongoingPeriod {
    try {
      return _periods.firstWhere((p) => p.isOngoing);
    } catch (_) {
      return null;
    }
  }

  Future<void> startPeriod(DateTime date) async {
    if (ongoingPeriod != null) await endPeriod(date);
    final id = date.millisecondsSinceEpoch.toString();
    final period = Period(
      id: id,
      startDate: DateTime(date.year, date.month, date.day),
    );
    await _periodsRef.doc(id).set(period.toMap());
  }

  Future<void> endPeriod(DateTime date) async {
    final ongoing = ongoingPeriod;
    if (ongoing == null) return;
    final updated =
        ongoing.copyWith(endDate: DateTime(date.year, date.month, date.day));
    await _periodsRef.doc(ongoing.id).update(updated.toMap());
  }

  Future<void> editPeriodStart(Period period, DateTime newStartDate) async {
    final updated = period.copyWith(
      startDate: DateTime(newStartDate.year, newStartDate.month, newStartDate.day),
    );
    await _periodsRef.doc(period.id).update(updated.toMap());
  }

  Future<void> deletePeriod(Period period) async {
    await _periodsRef.doc(period.id).delete();
  }

  Future<void> togglePeriodDay(DateTime date) async {
    final existing = periodForDate(date);
    if (existing != null && existing.isOngoing) {
      await endPeriod(date);
    } else if (ongoingPeriod != null) {
      await endPeriod(date);
    } else {
      await startPeriod(date);
    }
  }

  Period? periodForDate(DateTime date) {
    try {
      return _periods.firstWhere((p) => p.containsDate(date));
    } catch (_) {
      return null;
    }
  }

  /// All calendar dates covered by logged periods.
  Set<DateTime> get allPeriodDates {
    final today = DateTime.now();
    final dates = <DateTime>{};
    for (final p in _periods) {
      final end = p.endDate ?? DateTime(today.year, today.month, today.day);
      var current =
          DateTime(p.startDate.year, p.startDate.month, p.startDate.day);
      final endNorm = DateTime(end.year, end.month, end.day);
      while (!current.isAfter(endNorm)) {
        dates.add(current);
        current = current.add(const Duration(days: 1));
      }
    }
    return dates;
  }

  // ── Predictions ───────────────────────────────────────────────────────────

  double? get averageCycleLength {
    final completed = _periods.where((p) => !p.isOngoing).toList();
    if (completed.length < 2) return null;
    final lengths = <int>[];
    for (int i = 1; i < completed.length; i++) {
      lengths.add(
          completed[i].startDate.difference(completed[i - 1].startDate).inDays);
    }
    if (lengths.isEmpty) return null;
    final recent =
        lengths.length > 6 ? lengths.sublist(lengths.length - 6) : lengths;
    return recent.reduce((a, b) => a + b) / recent.length;
  }

  DateTime? get nextPredictedDate {
    final avg = averageCycleLength;
    final cycleLen = avg?.round() ?? profile.cycleLength;
    final ongoing = ongoingPeriod;
    if (ongoing != null) {
      return ongoing.startDate.add(Duration(days: cycleLen));
    }
    final completed = _periods.where((p) => !p.isOngoing).toList();
    if (completed.isNotEmpty) {
      return completed.last.startDate.add(Duration(days: cycleLen));
    }
    return null;
  }

  Set<DateTime> get predictedPeriodDates {
    final firstStart = nextPredictedDate;
    if (firstStart == null) return {};
    final avgCycle =
        (averageCycleLength?.round() ?? profile.cycleLength).clamp(20, 45);
    final periodLen = profile.periodLength.clamp(1, 15);
    final cutoff = DateTime.now().add(const Duration(days: 365));
    final existing = allPeriodDates;
    final dates = <DateTime>{};
    var cycleStart =
        DateTime(firstStart.year, firstStart.month, firstStart.day);
    while (!cycleStart.isAfter(cutoff)) {
      for (int i = 0; i < periodLen; i++) {
        final d = cycleStart.add(Duration(days: i));
        if (!d.isAfter(cutoff) && !existing.contains(d)) dates.add(d);
      }
      cycleStart = cycleStart.add(Duration(days: avgCycle));
    }
    return dates;
  }

  // ── Analysis ──────────────────────────────────────────────────────────────

  double? get averagePeriodLength {
    final completed = _periods.where((p) => !p.isOngoing).toList();
    if (completed.isEmpty) return null;
    final total = completed.fold<int>(0, (s, p) => s + p.lengthInDays);
    return total / completed.length;
  }

  int? get lastCycleLengthDays {
    final completed = _periods.where((p) => !p.isOngoing).toList();
    if (completed.length < 2) return null;
    return completed.last.startDate
        .difference(completed[completed.length - 2].startDate)
        .inDays;
  }

  bool? get isRegularCycle {
    final completed = _periods.where((p) => !p.isOngoing).toList();
    if (completed.length < 3) return null;
    final lengths = <int>[];
    for (int i = 1; i < completed.length; i++) {
      lengths.add(completed[i].startDate
          .difference(completed[i - 1].startDate)
          .inDays);
    }
    final mean = lengths.reduce((a, b) => a + b) / lengths.length;
    final variance =
        lengths.fold<double>(0, (s, v) => s + (v - mean) * (v - mean)) /
            lengths.length;
    return variance.abs() <= 49;
  }

  Set<DateTime> get yearPredictedDates {
    final nextStart = nextPredictedDate;
    if (nextStart == null) return {};
    final avgCycle =
        (averageCycleLength?.round() ?? profile.cycleLength).clamp(20, 45);
    final periodLen = profile.periodLength.clamp(1, 15);
    final yearEnd = DateTime(DateTime.now().year, 12, 31);
    final dates = <DateTime>{};
    var cycleStart =
        DateTime(nextStart.year, nextStart.month, nextStart.day);
    while (!cycleStart.isAfter(yearEnd)) {
      for (int i = 0; i < periodLen; i++) {
        final date = cycleStart.add(Duration(days: i));
        if (!date.isAfter(yearEnd)) dates.add(date);
      }
      cycleStart = cycleStart.add(Duration(days: avgCycle));
    }
    return dates;
  }

  bool get hasForgottenPeriod {
    final ongoing = ongoingPeriod;
    if (ongoing == null) return false;
    return DateTime.now().difference(ongoing.startDate).inDays >
        profile.periodLength + 3;
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  UserProfile get profile => _profile;

  Future<void> _saveProfile(UserProfile updated) async {
    _profile = updated;
    notifyListeners();
    await _profileRef.set(updated.toMap(), SetOptions(merge: true));
  }

  Future<void> updateName(String? name) =>
      _saveProfile(name == null
          ? profile.copyWith(clearName: true)
          : profile.copyWith(name: name));

  Future<void> updateAge(int? age) =>
      _saveProfile(age == null
          ? profile.copyWith(clearAge: true)
          : profile.copyWith(age: age));

  Future<void> updateWeight(double? weightKg) =>
      _saveProfile(weightKg == null
          ? profile.copyWith(clearWeight: true)
          : profile.copyWith(weightKg: weightKg));

  Future<void> updateHeight(double? heightCm) =>
      _saveProfile(heightCm == null
          ? profile.copyWith(clearHeight: true)
          : profile.copyWith(heightCm: heightCm));

  Future<void> setDarkMode(bool isDark) =>
      _saveProfile(profile.copyWith(isDarkMode: isDark));

  Future<void> updateAvatar(int index) =>
      _saveProfile(profile.copyWith(avatarIndex: index, clearPhoto: true));

  Future<void> updatePhotoPath(String? path) =>
      _saveProfile(path == null
          ? profile.copyWith(clearPhoto: true)
          : profile.copyWith(photoPath: path));

  Future<void> setNotificationsEnabled(bool enabled) =>
      _saveProfile(profile.copyWith(notificationsEnabled: enabled));

  // ── Onboarding ────────────────────────────────────────────────────────────

  Future<void> completeOnboarding({
    required int periodLength,
    required int cycleLength,
    int? age,
    DateTime? lastPeriodStart,
    DateTime? lastPeriodEnd,
  }) async {
    await _saveProfile(profile.copyWith(
      periodLength: periodLength,
      cycleLength: cycleLength,
      age: age,
      hasCompletedOnboarding: true,
    ));
    if (lastPeriodStart != null) {
      await seedHistoricalPeriods(
        lastPeriodStart: lastPeriodStart,
        periodLength: periodLength,
        cycleLength: cycleLength,
        latestPeriodEnd: lastPeriodEnd,
      );
    }
  }

  Future<void> seedHistoricalPeriods({
    required DateTime lastPeriodStart,
    required int periodLength,
    required int cycleLength,
    DateTime? latestPeriodEnd,
  }) async {
    final seed = DateTime(
        lastPeriodStart.year, lastPeriodStart.month, lastPeriodStart.day);
    final cyclesBack = (183 / cycleLength).ceil();
    final batch = _db.batch();
    for (int n = 0; n <= cyclesBack; n++) {
      final start = seed.subtract(Duration(days: n * cycleLength));
      if (start.isAfter(DateTime.now())) continue;
      final id = start.millisecondsSinceEpoch.toString();
      if (_periods.any((p) => p.id == id)) continue;
      if (_periods.any((p) => p.containsDate(start))) continue;
      final DateTime? end = n == 0
          ? latestPeriodEnd
          : start.add(Duration(days: periodLength - 1));
      batch.set(_periodsRef.doc(id),
          Period(id: id, startDate: start, endDate: end).toMap());
    }
    await batch.commit();
  }

  Future<void> deleteAllData() async {
    final batch = _db.batch();
    for (final p in _periods) {
      batch.delete(_periodsRef.doc(p.id));
    }
    batch.delete(_profileRef);
    await batch.commit();
    _periods = [];
    _profile = const UserProfile();
    notifyListeners();
  }
}
