import 'dart:io';

void main() {
  final s = File('tool/qqqys_v49464.js').readAsStringSync();
  final needles = ['vod', 'search', 'wd=', 'vodsearch', 'autocomplete', 'api'];
  for (final n in needles) {
    var idx = 0;
    var printed = 0;
    while (printed < 5) {
      final i = s.toLowerCase().indexOf(n.toLowerCase(), idx);
      if (i < 0) break;
      final start = (i - 120).clamp(0, s.length);
      final end = (i + 200).clamp(0, s.length);
      stdout.writeln('--- $n @ $i ---');
      stdout.writeln(s.substring(start, end).replaceAll('\n', ' '));
      idx = i + 1;
      printed++;
    }
  }
}

