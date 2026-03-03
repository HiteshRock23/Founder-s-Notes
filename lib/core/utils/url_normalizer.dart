class UrlNormalizer {
  /// Safely extracts the first valid URL from a block of text.
  /// Converts schemeless URLs (e.g., example.com) to https://example.com.
  static String? extractUrl(String text) {
    if (text.trim().isEmpty) return null;

    final urlRegex = RegExp(
      r'((?:https?:\/\/)?(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{2,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&//=]*))',
      caseSensitive: false,
    );

    final match = urlRegex.firstMatch(text);
    if (match != null) {
      String url = match.group(0)!;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      return url;
    }

    return null;
  }
}
