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
    final url =
        'https://www.czzymovie.com/boss1O1?q=${Uri.encodeQueryComponent('怪奇物语')}';
    try {
      final html = await WebviewHtmlFetcher().fetchHtml(url);
      await File('tool/czzymovie_search2.html').writeAsString(html);
      await File('tool/czzymovie_search2.len.txt')
          .writeAsString('${html.length}');
      await File('tool/czzymovie_search2.url.txt').writeAsString(url);
    } catch (e) {
      await File('tool/czzymovie_search2.webview.error.txt')
          .writeAsString(e.toString());
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

