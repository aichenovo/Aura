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

  const url = 'https://www.libvio.site/play/714893180-1-1.html';
  final resp = await dio.get(url);
  final text = resp.data.toString();
  await File('tool/libvio_play.html').writeAsString(text);
  await File('tool/libvio_play.len.txt').writeAsString('${text.length}');
  await File('tool/libvio_play.url.txt').writeAsString(url);
}

