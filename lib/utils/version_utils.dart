/// True if [latest] is a newer version than [current]. Compares dot-separated
/// numeric segments (e.g. "1.10.0" > "1.9.5"); non-numeric segments compare
/// as 0 to fail safe rather than throw.
bool isNewerVersion(String? latest, String current) {
  if (latest == null || latest.isEmpty) return false;

  final a = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final b = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final len = a.length > b.length ? a.length : b.length;

  for (var i = 0; i < len; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x > y) return true;
    if (x < y) return false;
  }
  return false;
}
