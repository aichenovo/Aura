import 'dart:io';

import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept-Language': 'zh-CN,zh;q=0.9',
      },
      responseType: ResponseType.plain,
      followRedirects: true,
      validateStatus: (c) => c != null && c >= 200 && c < 400,
    ),
  );

  final targets = <({String name, String url})>[
    (name: 'czzymovie_home', url: 'https://www.czzymovie.com/'),
    (name: 'libvio_home', url: 'https://www.libvio.site/'),
    (name: 'czzymovie_search', url: 'https://www.czzymovie.com/?s=%E6%80%AA%E5%A5%87%E7%89%A9%E8%AF%AD'),
    (name: 'libvio_search', url: 'https://www.libvio.site/vodsearch/%E6%80%AA%E5%A5%87%E7%89%A9%E8%AF%AD-------------.html'),
  ];

  for (final t in targets) {
    try {
      final resp = await dio.get(t.url);
      final text = resp.data.toString();
      await File('tool/${t.name}.html').writeAsString(text);
      await File('tool/${t.name}.len.txt').writeAsString('${text.length}');
      await File('tool/${t.name}.url.txt').writeAsString(t.url);
    } catch (e) {
      await File('tool/${t.name}.error.txt').writeAsString(e.toString());
    }
  }
}

