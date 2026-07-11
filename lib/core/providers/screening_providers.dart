import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/screening_result.dart';
import 'repository_providers.dart';

final screeningStatusProvider =
    StreamProvider.family<ScreeningStatus, String>((ref, userId) {
  return ref.watch(screeningRepositoryProvider).watchStatus(userId);
});

/// Holds in-progress wizard answers and the latest computed result.
class ScreeningSessionState {
  const ScreeningSessionState({
    this.answers,
    this.result,
    this.isRescreen = false,
  });

  final ScreeningAnswers? answers;
  final ScreeningResult? result;
  final bool isRescreen;

  ScreeningSessionState copyWith({
    ScreeningAnswers? answers,
    ScreeningResult? result,
    bool? isRescreen,
  }) {
    return ScreeningSessionState(
      answers: answers ?? this.answers,
      result: result ?? this.result,
      isRescreen: isRescreen ?? this.isRescreen,
    );
  }
}

class ScreeningSessionNotifier extends StateNotifier<ScreeningSessionState> {
  ScreeningSessionNotifier() : super(const ScreeningSessionState());

  void setAnswers(ScreeningAnswers answers) {
    state = state.copyWith(answers: answers);
  }

  void setResult(ScreeningResult result) {
    state = state.copyWith(result: result);
  }

  void setRescreen(bool value) {
    state = ScreeningSessionState(isRescreen: value);
  }

  void clear() {
    state = const ScreeningSessionState();
  }
}

final screeningSessionProvider =
    StateNotifierProvider<ScreeningSessionNotifier, ScreeningSessionState>(
  (ref) => ScreeningSessionNotifier(),
);
