/// Санҷиши ҷавобҳои навишташуда (саволҳои "пӯшида").
///
/// Ҳарфҳои махсуси тоҷикӣ ба ҳарфҳои муқаррарӣ табдил меёбанд,
/// то корбар бо клавиатураи русӣ ҳам ҷавоб дода тавонад
/// (масалан "Душанбе", "Ӯзбекистон" = "Узбекистон").
String normalizeAnswer(String input) {
  var t = input.toLowerCase();
  t = t.replaceAll(RegExp(r'\([^)]*\)'), ' '); // "(а)" ва ғайра
  const map = {
    'ӣ': 'и',
    'ӯ': 'у',
    'ғ': 'г',
    'қ': 'к',
    'ҳ': 'х',
    'ҷ': 'ч',
    'ё': 'е',
    'ъ': '',
    'ь': '',
    "'": '',
    '’': '',
    'ʼ': '',
    '`': '',
  };
  map.forEach((k, v) => t = t.replaceAll(k, v));
  t = t.replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ');
  return t.trim().replaceAll(RegExp(r'\s+'), ' ');
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0);
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var best = prev[j] + 1;
      if (cur[j - 1] + 1 < best) best = cur[j - 1] + 1;
      if (prev[j - 1] + cost < best) best = prev[j - 1] + cost;
      cur[j] = best;
    }
    prev = cur;
  }
  return prev[b.length];
}

/// true, агар [input] бо яке аз ҷавобҳои қобили қабул мувофиқ бошад.
/// Барои калимаҳои дароз (7+ ҳарф) як хатои имлоӣ, барои 12+ ду хато бахшида мешавад.
bool isTextCorrect(String input, List<String> accepted) {
  final a = normalizeAnswer(input);
  if (a.isEmpty) return false;
  for (final acc in accepted) {
    final b = normalizeAnswer(acc);
    if (b.isEmpty) continue;
    if (a == b) return true;
    if (b.length >= 7 && !RegExp(r'^\d+$').hasMatch(b)) {
      final tol = b.length >= 12 ? 2 : 1;
      if ((a.length - b.length).abs() <= tol && _levenshtein(a, b) <= tol) {
        return true;
      }
    }
  }
  return false;
}
