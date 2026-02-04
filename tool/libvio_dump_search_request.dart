import 'dart:io';

import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Referer': 'https://www.libvio.site/',
      },
      responseType: ResponseType.plain,
      validateStatus: (c) => c != null && c >= 200 && c < 400,
    ),
  );

  final url =
      'https://www.libvio.site/search/-------------.html?wd=${Uri.encodeQueryComponent('怪奇物语')}';
  final resp = await dio.get(url);
  final text = resp.data.toString();
  await File('tool/libvio_search.html').writeAsString(text);
  await File('tool/libvio_search.len.txt').writeAsString('${text.length}');
  await File('tool/libvio_search.url.txt').writeAsString(url);
}

