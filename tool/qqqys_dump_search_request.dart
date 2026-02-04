import 'dart:io';

import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://qqqys.com/',
        'Accept-Language': 'zh-CN,zh;q=0.9',
      },
      responseType: ResponseType.plain,
      validateStatus: (c) => c != null && c >= 200 && c < 400,
    ),
  );

  final url =
      'https://qqqys.com/vodsearch/${Uri.encodeComponent('怪奇物语')}--.html?direct=1';
  final resp = await dio.get(url);
  final text = resp.data.toString();
  await File('tool/qqqys_search.request.html').writeAsString(text);
  await File('tool/qqqys_search.request.len.txt').writeAsString('${text.length}');
}

