import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_providers.dart';
import '../../domain/entities/onboarding_page.dart';
import '../../domain/usecases/get_onboarding_pages_usecase.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class OnboardingState {
  final List<OnboardingPage> pages;
  final int currentIndex;

  const OnboardingState({
    required this.pages,
    this.currentIndex = 0,
  });

  bool get isLastPage => currentIndex == pages.length - 1;

  OnboardingState copyWith({int? currentIndex}) {
    return OnboardingState(
      pages: pages,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class OnboardingNotifier extends Notifier<OnboardingState> {
  late final GetOnboardingPagesUseCase _getPagesUseCase;

  @override
  OnboardingState build() {
    _getPagesUseCase = ref.read(getOnboardingPagesUseCaseProvider);
    return OnboardingState(pages: _getPagesUseCase());
  }

  void updateIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
