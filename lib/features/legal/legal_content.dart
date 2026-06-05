// ─────────────────────────────────────────────────────────────────────────────
// Legal content model — the Terms & Conditions and Privacy Policy TEXT now comes
// from the backend (`GET /api/v1/legal/content`); it is no longer bundled in the
// app. This file only defines the node model the screen renders, plus a fallback
// version string for the version provider.
// ─────────────────────────────────────────────────────────────────────────────

/// Fallback legal version. Used only when `GET /api/v1/legal/version` fails, so
/// the consent payload always carries a version and register/login are never
/// blocked by a hiccup on the version endpoint. The real version is the
/// backend's; bump this occasionally to stay close.
const String kLegalLastUpdated = '31 May 2026';

/// A single block inside a legal section — either a paragraph or a bulleted list.
sealed class LegalNode {
  const LegalNode();

  /// Parses one `body[]` node. Unknown `type`s return null so the renderer can
  /// drop them gracefully (forward-compat: the backend may add `heading` etc.).
  static LegalNode? fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'paragraph':
        return LegalParagraph(json['text'] as String? ?? '');
      case 'bullets':
        return LegalBullets(
          (json['items'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
        );
      default:
        return null;
    }
  }
}

/// A run of prose.
class LegalParagraph extends LegalNode {
  final String text;
  const LegalParagraph(this.text);
}

/// A bulleted list of points.
class LegalBullets extends LegalNode {
  final List<String> items;
  const LegalBullets(this.items);
}

/// A titled section of a legal document.
class LegalSection {
  final String title;
  final List<LegalNode> body;
  const LegalSection({required this.title, required this.body});

  factory LegalSection.fromJson(Map<String, dynamic> json) {
    final body = (json['body'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LegalNode.fromJson)
        .whereType<LegalNode>() // drop unknown node types
        .toList();
    return LegalSection(title: json['title'] as String? ?? '', body: body);
  }
}
