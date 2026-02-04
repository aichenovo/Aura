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
      final dir = await Directory.systemTemp.createTemp(
          'kazumi_czzymovie_verify_${DateTime.now().millisecondsSinceEpoch}_');
      Hive.init(dir.path);
      await GStorage.init();
      Request();
      Request.setOptionsHeaders();

      final plugin = Plugin(
        api: '5',
        type: 'tv',
        name: '厂长资源',
        version: '1.0',
        muliSources: true,
        useWebview: true,
        useWebviewForPages: true,
        useNativePlayer: true,
        usePost: false,
        useLegacyParser: false,
        adBlocker: false,
        userAgent: '',
        referer: 'https://www.czzymovie.com/',
        baseUrl: 'https://www.czzymovie.com',
        searchURL: 'https://www.czzymovie.com/boss1O1?q=@keyword',
        searchList: "//div[contains(@class,'search_list')]//ul/li",
        searchName: ".//h3[contains(@class,'dytit')]/a",
        searchResult: ".//h3[contains(@class,'dytit')]/a",
        chapterRoads: "//div[contains(@class,'paly_list_btn')]",
        chapterResult: './/a',
      );

      final search = await plugin.queryBangumi('怪奇物语');
      final buf = StringBuffer();
      buf.writeln('search_items=${search.data.length}');
      for (final (i, item) in search.data.indexed.take(6)) {
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
        }
      }

      await File('tool/czzymovie_verify.txt').writeAsString(buf.toString());
    } catch (e, st) {
      await File('tool/czzymovie_verify.error.txt').writeAsString('$e\n$st');
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

