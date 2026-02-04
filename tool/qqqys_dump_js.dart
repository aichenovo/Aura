import 'dart:io';

import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://qqqys.com/',
      },
      responseType: ResponseType.plain,
      validateStatus: (code) => code != null && code >= 200 && code < 400,
    ),
  );

  const url = 'https://qqqys.com/template/dist/asset/js/v49464.js';
  final resp = await dio.get(url);
  await File('tool/qqqys_v49464.js').writeAsString(resp.data.toString());
  await File('tool/qqqys_v49464.len.txt').writeAsString('${resp.data.toString().length}');
}

