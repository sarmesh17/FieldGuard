/// Represents a single onboarding page in the domain layer.
/// Pure data — no Flutter or JSON dependencies.
class OnboardingPage {
  final String imageUrl;
  final String title;
  final String subtitle;

  const OnboardingPage({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });
}
