import 'dart:io';

import 'package:flutter/material.dart';
import 'package:aura/utils/webview_html_fetcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _DumpApp());
}

class _DumpApp extends StatefulWidget {
  const _DumpApp();

  @override
  State<_DumpApp> createState() => _DumpAppState();
}

class _DumpAppState extends State<_DumpApp> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    const keyword = '怪奇物语';
    final url =
        'https://qqqys.com/vodsearch/${Uri.encodeComponent(keyword)}--.html?direct=1';
    try {
      final html = await WebviewHtmlFetcher().fetchHtml(url);
      await File('tool/qqqys_search.html').writeAsString(html);
      await File('tool/qqqys_search.url.txt').writeAsString(url);
      await File('tool/qqqys_search.len.txt').writeAsString('${html.length}');
    } catch (e) {
      await File('tool/qqqys_search.error.txt').writeAsString(e.toString());
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

