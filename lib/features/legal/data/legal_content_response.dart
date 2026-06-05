import 'package:fieldguard/features/legal/legal_content.dart';

/// Response for `GET /api/v1/legal/content`. The full Terms & Privacy text,
/// rendered verbatim. [version] here is always identical to the one returned by
/// `/legal/version`.
class LegalContentResponse {
  final String version;
  final String lastUpdated;
  final LegalDocument terms;
  final LegalDocument privacy;

  const LegalContentResponse({
    required this.version,
    required this.lastUpdated,
    required this.terms,
    required this.privacy,
  });

  factory LegalContentResponse.fromJson(Map<String, dynamic> json) {
    final docs = json['documents'] as Map<String, dynamic>? ?? const {};
    return LegalContentResponse(
      version: json['version'] as String? ?? '',
      lastUpdated: json['lastUpdated'] as String? ?? '',
      terms: LegalDocument.fromJson(
        docs['terms'] as Map<String, dynamic>? ?? const {},
      ),
      privacy: LegalDocument.fromJson(
        docs['privacy'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

/// One document (Terms or Privacy): a screen [title] + ordered [sections].
class LegalDocument {
  final String title;
  final List<LegalSection> sections;

  const LegalDocument({required this.title, required this.sections});

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      title: json['title'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LegalSection.fromJson)
          .toList(),
    );
  }
}
