import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:aura/modules/search/plugin_search_module.dart';
import 'package:aura/modules/roads/road_module.dart';
import 'package:aura/request/request.dart';
import 'package:html/parser.dart';
import 'package:aura/request/api.dart';
import 'package:aura/utils/logger.dart';
import 'package:aura/utils/webview_html_fetcher.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:aura/utils/utils.dart';

class Plugin {
  String api;
  String type;
  String name;
  String version;
  bool muliSources;
  bool useWebview;
  bool useWebviewForPages;
  bool useNativePlayer;
  bool usePost;
  bool useLegacyParser;
  bool adBlocker;
  String userAgent;
  String baseUrl;
  String searchURL;
  String searchList;
  String searchName;
  String searchResult;
  String chapterRoads;
  String chapterResult;
  String referer;

  Plugin({
    required this.api,
    required this.type,
    required this.name,
    required this.version,
    required this.muliSources,
    required this.useWebview,
    required this.useWebviewForPages,
    required this.useNativePlayer,
    required this.usePost,
    required this.useLegacyParser,
    required this.adBlocker,
    required this.userAgent,
    required this.baseUrl,
    required this.searchURL,
    required this.searchList,
    required this.searchName,
    required this.searchResult,
    required this.chapterRoads,
    required this.chapterResult,
    required this.referer,
  });

  factory Plugin.fromJson(Map<String, dynamic> json) {
    return Plugin(
        api: json['api'],
        type: json['type'],
        name: json['name'],
        version: json['version'],
        muliSources: json['muliSources'],
        useWebview: json['useWebview'],
        useWebviewForPages: json['useWebviewForPages'] ?? false,
        useNativePlayer: json['useNativePlayer'],
        usePost: json['usePost'] ?? false,
        useLegacyParser: json['useLegacyParser'] ?? false,
        adBlocker: json['adBlocker'] ?? false,
        userAgent: json['userAgent'],
        baseUrl: json['baseURL'],
        searchURL: json['searchURL'],
        searchList: json['searchList'],
        searchName: json['searchName'],
        searchResult: json['searchResult'],
        chapterRoads: json['chapterRoads'],
        chapterResult: json['chapterResult'],
        referer: json['referer'] ?? '');
  }

  factory Plugin.fromTemplate() {
    return Plugin(
        api: Api.apiLevel.toString(),
        type: 'anime',
        name: '',
        version: '',
        muliSources: true,
        useWebview: true,
        useWebviewForPages: false,
        useNativePlayer: true,
        usePost: false,
        useLegacyParser: false,
        adBlocker: false,
        userAgent: '',
        baseUrl: '',
        searchURL: '',
        searchList: '',
        searchName: '',
        searchResult: '',
        chapterRoads: '',
        chapterResult: '',
        referer: '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['api'] = api;
    data['type'] = type;
    data['name'] = name;
    data['version'] = version;
    data['muliSources'] = muliSources;
    data['useWebview'] = useWebview;
    data['useWebviewForPages'] = useWebviewForPages;
    data['useNativePlayer'] = useNativePlayer;
    data['usePost'] = usePost;
    data['useLegacyParser'] = useLegacyParser;
    data['adBlocker'] = adBlocker;
    data['userAgent'] = userAgent;
    data['baseURL'] = baseUrl;
    data['searchURL'] = searchURL;
    data['searchList'] = searchList;
    data['searchName'] = searchName;
    data['searchResult'] = searchResult;
    data['chapterRoads'] = chapterRoads;
    data['chapterResult'] = chapterResult;
    data['referer'] = referer;
    return data;
  }

  Map<String, dynamic>? _extractDooplayVuePlayerData(String html) {
    final ifsrcMatch =
        RegExp(r"ifsrc\s*:\s*'([^']+)'", caseSensitive: false).firstMatch(html) ??
            RegExp(r'ifsrc\s*:\s*"([^"]+)"', caseSensitive: false)
                .firstMatch(html);
    final videoMatch = RegExp(
      r'videourls\s*:\s*(\[\[[\s\S]*?\]\])\s*,\s*tables\s*:',
      caseSensitive: false,
    ).firstMatch(html);
    if (ifsrcMatch == null || videoMatch == null) return null;

    final ifsrc = ifsrcMatch.group(1)?.trim() ?? '';
    if (ifsrc.isEmpty) return null;

    try {
      final videourls = jsonDecode(videoMatch.group(1)!);
      if (videourls is! List) return null;
      return {
        'ifsrc': ifsrc,
        'videourls': videourls,
      };
    } catch (_) {
      return null;
    }
  }

  List<Road> _roadsFromDooplayVuePlayerData(
    Map<String, dynamic> data, {
    String? namePrefix,
  }) {
    final ifsrc = (data['ifsrc'] ?? '').toString();
    final videourls = data['videourls'];
    if (ifsrc.isEmpty || videourls is! List) return [];

    final roads = <Road>[];
    final String sep = ifsrc.contains('?') ? '&' : '?';
    for (int sourceIndex = 0; sourceIndex < videourls.length; sourceIndex++) {
      final dynamic episodes = videourls[sourceIndex];
      if (episodes is! List) continue;

      final urlList = <String>[];
      final nameList = <String>[];
      for (int i = 0; i < episodes.length; i++) {
        final dynamic p = episodes[i];
        final dynamic rawName = (p is Map) ? p['name'] : i + 1;
        final dynamic rawEp = (p is Map) ? (p['url'] ?? i) : i;

        final String n = rawName.toString().trim();
        final int ep = int.tryParse(rawEp.toString()) ?? i;
        nameList.add(n.isEmpty ? '${i + 1}' : n);
        urlList.add('$ifsrc${sep}source=$sourceIndex&ep=$ep');
      }

      if (urlList.isEmpty) continue;
      final String roadName = namePrefix == null
          ? (videourls.length > 1 ? '线路${sourceIndex + 1}' : '播放列表1')
          : (videourls.length > 1
              ? '$namePrefix·线路${sourceIndex + 1}'
              : namePrefix);
      roads.add(Road(name: roadName, data: urlList, identifier: nameList));
    }
    return roads;
  }

  String _toAbsoluteUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return baseUrl + url;
  }

  Future<String> _fetchHtml(
    String url, {
    bool shouldRethrow = false,
    CancelToken? cancelToken,
  }) async {
    if (useWebviewForPages &&
        (Platform.isWindows || Platform.isAndroid || Platform.isIOS) &&
        !usePost) {
      try {
        return await WebviewHtmlFetcher().fetchHtml(
          url,
          userAgent: userAgent.isNotEmpty ? userAgent : null,
        );
      } catch (e) {
        if (shouldRethrow) rethrow;
        return '';
      }
    }

    final httpHeaders = {
      'referer': '$baseUrl/',
      'Accept-Language': Utils.getRandomAcceptedLanguage(),
      'Connection': 'keep-alive',
    };

    try {
      final resp = await Request().get(
        url,
        options: Options(headers: httpHeaders),
        shouldRethrow: shouldRethrow,
        extra: {'customError': '', 'resType': ResponseType.plain},
        cancelToken: cancelToken,
      );
      return resp.data.toString();
    } catch (e) {
      if (shouldRethrow) rethrow;
      return '';
    }
  }

  Future<List<Road>> _queryDooplaySeasons(
    String htmlString, {
    required Map<String, String> httpHeaders,
    CancelToken? cancelToken,
  }) async {
    final matches = RegExp(
      r"""<a[^>]+href="([^"]+/seasons/[^"]+)"[^>]*>\s*<span[^>]*class=['"]se-t[^'"]*['"][^>]*>\s*([0-9]+)\s*</span>""",
      caseSensitive: false,
    ).allMatches(htmlString);
    final seasonMap = <String, String>{};
    for (final m in matches) {
      final href = (m.group(1) ?? '').trim();
      final no = (m.group(2) ?? '').trim();
      if (href.isEmpty) continue;
      seasonMap[href] = no;
    }
    if (seasonMap.length < 2) return [];

    final roads = <Road>[];
    for (final entry in seasonMap.entries) {
      final href = entry.key;
      final seasonNo = entry.value;
      final prefix = seasonNo.isEmpty ? null : '第$seasonNo季';
      final seasonUrl = _toAbsoluteUrl(href);
      final resp = await Request().get(
        seasonUrl,
        options: Options(headers: httpHeaders),
        extra: {'customError': '', 'resType': ResponseType.plain},
        cancelToken: cancelToken,
      );
      final htmlString = resp.data.toString();
      final data = _extractDooplayVuePlayerData(htmlString);
      if (data == null) continue;
      roads.addAll(_roadsFromDooplayVuePlayerData(data, namePrefix: prefix));
    }
    return roads;
  }

  Future<PluginSearchResponse> queryBangumi(String keyword,
      {bool shouldRethrow = false}) async {
    final encodedKeyword = Uri.encodeComponent(keyword);
    String queryURL = searchURL.replaceAll('@keyword', encodedKeyword);
    List<SearchItem> searchItems = [];
    String htmlString = '';
    if (usePost) {
      Uri uri = Uri.parse(queryURL);
      Map<String, String> queryParams = uri.queryParameters;
      Uri postUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        path: uri.path,
      );
      var httpHeaders = {
        'referer': '$baseUrl/',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept-Language': Utils.getRandomAcceptedLanguage(),
        'Connection': 'keep-alive',
      };
      final resp = await Request().post(
        postUri.toString(),
        options: Options(headers: httpHeaders),
        extra: {'customError': '', 'resType': ResponseType.plain},
        data: queryParams,
        shouldRethrow: shouldRethrow,
      );
      htmlString = resp.data.toString();
    } else {
      htmlString = await _fetchHtml(queryURL, shouldRethrow: shouldRethrow);
    }
    if (htmlString.isEmpty) {
      return PluginSearchResponse(pluginName: name, data: searchItems);
    }
    var htmlElement = parse(htmlString).documentElement!;

    htmlElement.queryXPath(searchList).nodes.forEach((element) {
      try {
        SearchItem searchItem = SearchItem(
          name: element.queryXPath(searchName).node!.text?.trim() ?? '',
          src: element.queryXPath(searchResult).node!.attributes['href'] ?? '',
        );
        searchItems.add(searchItem);
        KazumiLogger().i(
            'Plugin: $name ${element.queryXPath(searchName).node!.text ?? ''} $baseUrl${element.queryXPath(searchResult).node!.attributes['href'] ?? ''}');
      } catch (_) {}
    });
    PluginSearchResponse pluginSearchResponse =
    PluginSearchResponse(pluginName: name, data: searchItems);
    return pluginSearchResponse;
  }

  Future<List<Road>> querychapterRoads(String url, {CancelToken? cancelToken}) async {
    List<Road> roadList = [];
    // 预处理
    if (!url.contains('https')) {
      url = url.replaceAll('http', 'https');
    }
    String queryURL = '';
    if (url.contains(baseUrl)) {
      queryURL = url;
    } else {
      queryURL = baseUrl + url;
    }
    try {
      final htmlString = await _fetchHtml(
        queryURL,
        cancelToken: cancelToken,
      );
      if (htmlString.isEmpty) return roadList;

      final qqqysRoads = _queryQqqysPlaylistData(htmlString, queryURL);
      if (qqqysRoads.isNotEmpty) {
        return qqqysRoads;
      }

      var htmlElement = parse(htmlString).documentElement!;

      final seasonRoads = await _queryDooplaySeasons(
        htmlString,
        httpHeaders: {
          'referer': '$baseUrl/',
          'Accept-Language': Utils.getRandomAcceptedLanguage(),
          'Connection': 'keep-alive',
        },
        cancelToken: cancelToken,
      );
      if (seasonRoads.isNotEmpty) {
        return seasonRoads;
      }

      final dooplayData = _extractDooplayVuePlayerData(htmlString);
      if (dooplayData != null) {
        final roads = _roadsFromDooplayVuePlayerData(dooplayData);
        if (roads.isNotEmpty) {
          return roads;
        }
      }

      int count = 1;
      htmlElement.queryXPath(chapterRoads).nodes.forEach((element) {
        try {
          List<String> chapterUrlList = [];
          List<String> chapterNameList = [];
          element.queryXPath(chapterResult).nodes.forEach((item) {
            String itemUrl = item.node.attributes['href'] ?? '';
            String itemName = item.node.text ?? '';
            chapterUrlList.add(itemUrl);
            chapterNameList.add(itemName.replaceAll(RegExp(r'\s+'), ''));
          });
          if (chapterUrlList.isNotEmpty && chapterNameList.isNotEmpty) {
            Road road = Road(
                name: '播放列表$count',
                data: chapterUrlList,
                identifier: chapterNameList);
            roadList.add(road);
            count++;
          }
        } catch (_) {}
      });
    } catch (_) {}
    return roadList;
  }

  List<Road> _queryQqqysPlaylistData(String htmlString, String queryURL) {
    if (!htmlString.contains('window.PLAYLIST_DATA')) return [];
    final vodIdMatch = RegExp(r'/v[db]/(\d+)\.html', caseSensitive: false)
        .firstMatch(queryURL);
    final vodId = vodIdMatch?.group(1);
    if (vodId == null || vodId.isEmpty) return [];

    final data = _extractWindowAssignedJson(htmlString, 'window.PLAYLIST_DATA');
    if (data is! Map) return [];

    final playPath = '/vb/$vodId.html';
    final roads = <Road>[];

    for (final entry in data.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final sidRaw = value['sid'] ?? entry.key;
      final sid = int.tryParse(sidRaw.toString());
      if (sid == null) continue;

      final playerInfo = value['player_info'];
      String roadName = '线路$sid';
      if (playerInfo is Map && playerInfo['show'] != null) {
        roadName = playerInfo['show'].toString();
      } else if (value['show'] != null) {
        roadName = value['show'].toString();
      }

      // 提取 from 值用于 Alpine.js API
      // 优先级: player_info['from'] > player_info['id'] > value['from'] > 数字sid
      String fromValue = sid.toString();
      if (playerInfo is Map) {
        fromValue = (playerInfo['from'] ?? playerInfo['id'] ?? fromValue).toString();
      } else if (value['from'] != null) {
        fromValue = value['from'].toString();
      }

      final urls = value['urls'];
      if (urls is! Map) continue;

      final episodes = <({int nid, String name})>[];
      for (final e in urls.entries) {
        final ev = e.value;
        if (ev is! Map) continue;
        final nid = int.tryParse('${ev['nid'] ?? e.key}');
        if (nid == null) continue;
        final name = (ev['name'] ?? '').toString().trim();
        episodes.add((nid: nid, name: name));
      }
      episodes.sort((a, b) => a.nid.compareTo(b.nid));
      if (episodes.isEmpty) continue;

      final chapterUrlList = <String>[];
      final chapterNameList = <String>[];
      for (final ep in episodes) {
        // 使用 fromValue (例如 "BBA", "YYNB") 而不是数字 sid
        chapterUrlList.add('$playPath#sid=$fromValue&nid=${ep.nid}');
        final label = ep.name.isEmpty ? '${ep.nid}' : ep.name;
        final display = int.tryParse(label) != null ? '第$label集' : label;
        chapterNameList.add(display);
      }

      roads.add(Road(name: roadName, data: chapterUrlList, identifier: chapterNameList));
    }

    return roads;
  }

  dynamic _extractWindowAssignedJson(String htmlString, String variableName) {
    final idx = htmlString.indexOf(variableName);
    if (idx < 0) return null;
    var i = htmlString.indexOf('=', idx);
    if (i < 0) return null;
    final start = htmlString.indexOf('{', i);
    if (start < 0) return null;

    var depth = 0;
    var inString = false;
    var escape = false;
    for (var p = start; p < htmlString.length; p++) {
      final ch = htmlString.codeUnitAt(p);
      if (inString) {
        if (escape) {
          escape = false;
          continue;
        }
        if (ch == 92) {
          escape = true;
          continue;
        }
        if (ch == 34) {
          inString = false;
        }
        continue;
      }

      if (ch == 34) {
        inString = true;
        continue;
      }
      if (ch == 123) {
        depth++;
        continue;
      }
      if (ch == 125) {
        depth--;
        if (depth == 0) {
          final jsonText = htmlString.substring(start, p + 1);
          try {
            return jsonDecode(jsonText);
          } catch (_) {
            return null;
          }
        }
      }
    }
    return null;
  }

  Future<String> testSearchRequest(String keyword,
      {bool shouldRethrow = false,CancelToken? cancelToken}) async {
    final encodedKeyword = Uri.encodeComponent(keyword);
    String queryURL = searchURL.replaceAll('@keyword', encodedKeyword);
    if (usePost) {
      Uri uri = Uri.parse(queryURL);
      Map<String, String> queryParams = uri.queryParameters;
      Uri postUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        path: uri.path,
      );
      var httpHeaders = {
        'referer': '$baseUrl/',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept-Language': Utils.getRandomAcceptedLanguage(),
        'Connection': 'keep-alive',
      };
      final resp = await Request().post(postUri.toString(),
          options: Options(headers: httpHeaders),
          extra: {'customError': ''},
          data: queryParams,
          shouldRethrow: shouldRethrow,
          cancelToken: cancelToken);
      return resp.data.toString();
    } else {
      return await _fetchHtml(
        queryURL,
        shouldRethrow: shouldRethrow,
        cancelToken: cancelToken,
      );
    }
  }

  PluginSearchResponse testQueryBangumi(String htmlString) {
    List<SearchItem> searchItems = [];
    var htmlElement = parse(htmlString).documentElement!;
    htmlElement.queryXPath(searchList).nodes.forEach((element) {
      try {
        SearchItem searchItem = SearchItem(
          name: element.queryXPath(searchName).node!.text?.trim() ?? '',
          src: element.queryXPath(searchResult).node!.attributes['href'] ?? '',
        );
        searchItems.add(searchItem);
        KazumiLogger().i(
            'Plugin: $name ${element.queryXPath(searchName).node!.text ?? ''} $baseUrl${element.queryXPath(searchResult).node!.attributes['href'] ?? ''}');
      } catch (_) {}
    });
    PluginSearchResponse pluginSearchResponse =
    PluginSearchResponse(pluginName: name, data: searchItems);
    return pluginSearchResponse;
  }
}
