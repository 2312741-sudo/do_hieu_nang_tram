import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guest_session_model.dart';
import '../models/guest_measurement_model.dart';
import '../repositories/guest_local_repository.dart';
import 'guest_timer_notifier.dart';

/// Singleton repository
final guestLocalRepositoryProvider = Provider<GuestLocalRepository>((ref) {
  return GuestLocalRepository();
});

/// Whether user is currently in Guest Mode
final isGuestModeProvider = StateProvider<bool>((ref) => false);

/// Active guest session
final guestActiveSessionProvider = StateProvider<GuestSessionModel?>((ref) => null);

/// All measurements for the active guest session
final guestSessionMeasurementsProvider = StateProvider<List<GuestMeasurementModel>>((ref) => []);

/// Guest timer engine
final guestTimerProvider =
    StateNotifierProvider<GuestTimerNotifier, GuestTimerState>((ref) {
  final repo = ref.watch(guestLocalRepositoryProvider);
  return GuestTimerNotifier(repo);
});

/// Guest session history
final guestHistoryProvider = FutureProvider<List<GuestSessionModel>>((ref) async {
  final repo = ref.watch(guestLocalRepositoryProvider);
  return repo.loadHistory();
});
