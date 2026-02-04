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
    const url = 'https://www.ziziys.org/video/5706-1-1.html';
    try {
      final html = await WebviewHtmlFetcher().fetchHtml(url);
      await File('tool/ziziys_play.html').writeAsString(html);
    } catch (e) {
      await File('tool/ziziys_play.error.txt').writeAsString(e.toString());
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

