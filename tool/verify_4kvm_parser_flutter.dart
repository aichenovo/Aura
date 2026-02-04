import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:aura/plugins/plugins.dart';
import 'package:aura/request/request.dart';
import 'package:aura/utils/storage.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter('${(await getApplicationSupportDirectory()).path}/hive');
  await GStorage.init();

  Request();
  Request.setOptionsHeaders();

  final plugin = Plugin(
    api: '6',
    type: 'tv',
    name: 'verify-4kvm',
    version: '1.0',
    muliSources: true,
    useWebview: true,
    useWebviewForPages: false,
    useNativePlayer: false,
    usePost: false,
    useLegacyParser: false,
    adBlocker: false,
    userAgent: '',
    baseUrl: 'https://www.4kvm.org',
    searchURL: 'https://www.4kvm.org/xssearch?s=@keyword',
    searchList: "//div[contains(@class,'result-item')]",
    searchName: ".//div[@class='title']/a",
    searchResult: ".//div[@class='title']/a",
    chapterRoads: "//div[@id='seasons']",
    chapterResult: ".//a",
    referer: 'https://www.4kvm.org/',
  );

  final roads =
      await plugin.querychapterRoads('https://www.4kvm.org/tvshows/gqwy');

  stdout.writeln('roads=${roads.length}');
  for (final (i, r) in roads.indexed.take(6)) {
    stdout.writeln('road[$i]=${r.name} episodes=${r.data.length}');
    if (r.data.isNotEmpty) {
      stdout.writeln('  ep1=${r.identifier.first} => ${r.data.first}');
    }
    if (r.data.length >= 2) {
      stdout.writeln('  ep2=${r.identifier[1]} => ${r.data[1]}');
    }
  }

  exit(0);
}
