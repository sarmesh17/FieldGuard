// Display helpers for phone numbers. The backend stores and returns numbers
// in E.164 (e.g. +9779841123456); these strip the Nepal country code for a
// friendlier local display. For tel: links use the raw E.164 value as-is.

/// Strips a leading `+977` (Nepal) country code for local display, returning
/// the 10-digit local number (e.g. `+9779841123456` → `9841123456`). Any other
/// format — already local, a different country code, or non-standard — is
/// returned unchanged so nothing is silently mangled.
String formatNepaliPhone(String? phone) {
  if (phone == null) return '';
  final trimmed = phone.trim();
  const prefix = '+977';
  if (trimmed.startsWith(prefix)) {
    final local = trimmed.substring(prefix.length);
    // Only strip when what remains is a plain 10-digit local number; otherwise
    // keep the original (could be a short code or unexpected shape).
    if (local.length == 10 && int.tryParse(local) != null) return local;
  }
  return trimmed;
}
