import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:aura/plugins/plugins.dart';
import 'package:aura/request/request.dart';
import 'package:aura/utils/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _VerifyApp());
}

class _VerifyApp extends StatefulWidget {
  const _VerifyApp();

  @override
  State<_VerifyApp> createState() => _VerifyAppState();
}

class _VerifyAppState extends State<_VerifyApp> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final dir = await Directory.systemTemp
          .createTemp('kazumi_ziziys_verify_${DateTime.now().millisecondsSinceEpoch}_');
      Hive.init(dir.path);
      await GStorage.init();
      Request();
      Request.setOptionsHeaders();

      final plugin = Plugin(
        api: '5',
        type: 'tv',
        name: '子子影视',
        version: '1.0',
        muliSources: true,
        useWebview: true,
        useWebviewForPages: true,
        useNativePlayer: true,
        usePost: false,
        useLegacyParser: false,
        adBlocker: false,
        userAgent: '',
        referer: 'https://www.ziziys.org/',
        baseUrl: 'https://www.ziziys.org',
        searchURL: 'https://www.ziziys.org/vsearch/@keyword--.html',
        searchList:
            "//div[contains(@class,'module-items')]/div[contains(@class,'module-search-item')]",
        searchName: './/h3/a',
        searchResult: './/h3/a',
        chapterRoads:
            "//div[contains(@class,'module-list') and contains(@class,'module-player-list')]",
        chapterResult: "//div[@class='module-blocklist']/div[@class='sort-item']/a",
      );

      final search = await plugin.queryBangumi('怪奇物语');
      final buf = StringBuffer();
      buf.writeln('search_items=${search.data.length}');
      for (final (i, item) in search.data.indexed.take(5)) {
        buf.writeln('  [$i] ${item.name} => ${item.src}');
      }

      if (search.data.isNotEmpty) {
        final detail = search.data.first.src;
        final roads = await plugin.querychapterRoads(detail);
        buf.writeln('roads=${roads.length}');
        for (final (i, r) in roads.indexed.take(3)) {
          buf.writeln('  road[$i]=${r.name} episodes=${r.data.length}');
          if (r.data.isNotEmpty) {
            buf.writeln('    ep1=${r.identifier.first} => ${r.data.first}');
          }
          if (r.data.length >= 2) {
            buf.writeln('    ep2=${r.identifier[1]} => ${r.data[1]}');
          }
        }
      }

      await File('tool/ziziys_verify.txt').writeAsString(buf.toString());
    } catch (e, st) {
      await File('tool/ziziys_verify.error.txt')
          .writeAsString('$e\n$st');
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
