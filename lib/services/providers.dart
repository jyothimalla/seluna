import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'period_service.dart';
import 'notification_service.dart';

// ── Auth ─────────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Stream of Firebase auth state — null means signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── Period data ───────────────────────────────────────────────────────────────

/// Created once per signed-in user; auto-recreated when userId changes.
final periodServiceProvider = ChangeNotifierProvider<PeriodService>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid ?? '';
  final service = PeriodService(userId: userId);
  ref.onDispose(service.dispose);
  return service;
});

// ── Derived providers ─────────────────────────────────────────────────────────

final themeModeProvider = Provider((ref) {
  final isDark = ref.watch(periodServiceProvider).profile.isDarkMode;
  return isDark ? ThemeMode.dark : ThemeMode.light;
});

final nextPredictedDateProvider = Provider<DateTime?>((ref) {
  return ref.watch(periodServiceProvider).nextPredictedDate;
});

final avgCycleLengthProvider = Provider<double?>((ref) {
  return ref.watch(periodServiceProvider).averageCycleLength;
});

final avgPeriodLengthProvider = Provider<double?>((ref) {
  return ref.watch(periodServiceProvider).averagePeriodLength;
});

final lastCycleLengthProvider = Provider<int?>((ref) {
  return ref.watch(periodServiceProvider).lastCycleLengthDays;
});

final isRegularCycleProvider = Provider<bool?>((ref) {
  return ref.watch(periodServiceProvider).isRegularCycle;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(periodServiceProvider).profile.notificationsEnabled;
});

final yearPredictedDatesProvider = Provider<Set<DateTime>>((ref) {
  return ref.watch(periodServiceProvider).yearPredictedDates;
});

// ── Notification service ──────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError(
      'notificationServiceProvider must be overridden in main');
});
