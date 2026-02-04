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
    try {
      final html = await WebviewHtmlFetcher().fetchHtml('https://www.ziziys.org/');
      final out = File('tool/ziziys_home.html');
      await out.writeAsString(html);
      final marker = File('tool/ziziys_home.len.txt');
      await marker.writeAsString('${html.length}');
    } catch (e) {
      final marker = File('tool/ziziys_home.error.txt');
      await marker.writeAsString(e.toString());
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

