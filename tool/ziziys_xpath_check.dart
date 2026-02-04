import 'dart:io';

import 'package:html/parser.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

void main() {
  final html = File('tool/ziziys_detail.html').readAsStringSync();
  final docEl = parse(html).documentElement!;

  final probes = <String>[
    "//div[contains(@class,'module-list') and contains(@class,'module-player-list')]",
    "//div[contains(@class,'module-player-list')]",
    "//div[@id='glist-1']",
  ];

  for (final xp in probes) {
    final nodes = docEl.queryXPath(xp).nodes;
    stdout.writeln('$xp => ${nodes.length}');
  }

  final road = docEl
      .queryXPath("//div[contains(@class,'module-player-list')]")
      .nodes
      .firstOrNull;
  if (road != null) {
    final candidates = <String>[
      ".//a",
      "//a",
      "//div[@class='module-blocklist']/div[@class='sort-item']/a",
      "//div[@class='module-blocklist scroll-box scroll-box-y']/div[@class='scroll-content']/a",
      "//div[@class='module-blocklist scroll-box scroll-box-y']//a",
      "//div[@class='module-blocklist']//a",
    ];
    for (final xp in candidates) {
      final nodes = road.queryXPath(xp).nodes;
      stdout.writeln('$xp => ${nodes.length}');
    }
  }
}
