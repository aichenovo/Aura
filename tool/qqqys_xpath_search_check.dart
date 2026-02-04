import 'dart:io';

import 'package:html/parser.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

void main() {
  stdout.writeln('start');
  final html = File('tool/qqqys_search.request.html').readAsStringSync();
  final docEl = parse(html).documentElement!;

  const listXp = "//main//div[contains(@class,'grid')]/div[contains(@class,'p-2')]";
  const nameXp = ".//div[contains(@class,'ml-[105px]')]//strong";
  const resultXp = ".//a[starts-with(@href,'/vd/')]";

  final list = docEl.queryXPath(listXp).nodes;
  stdout.writeln('list=${list.length}');
  if (list.isNotEmpty) {
    final first = list.first;
    final nameNode = first.queryXPath(nameXp).node;
    final hrefNode = first.queryXPath(resultXp).node;
    stdout.writeln('name=${nameNode?.text}');
    stdout.writeln('href=${hrefNode?.attributes['href']}');
  }
}
