import 'dart:io';

import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:aura/utils/webview_html_fetcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _ProbeApp());
}

class _ProbeApp extends StatefulWidget {
  const _ProbeApp();

  @override
  State<_ProbeApp> createState() => _ProbeAppState();
}

class _ProbeAppState extends State<_ProbeApp> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final html = await WebviewHtmlFetcher().fetchHtml('https://www.ziziys.org/');
      print('html_len=${html.length}');
      final doc = parse(html);
      print('title=${doc.querySelector("title")?.text.trim() ?? ""}');
      print(html.substring(0, html.length > 800 ? 800 : html.length));
    } catch (e, st) {
      print('error=$e');
      print(st);
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SizedBox.shrink());
  }
}

