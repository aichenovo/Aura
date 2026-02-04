import 'dart:convert';
import 'package:aura/utils/logger.dart';
import 'package:aura/request/api.dart';
import 'package:aura/request/request.dart';
import 'package:aura/plugins/plugins.dart';
import 'package:aura/modules/plugin/plugin_http_module.dart';

class PluginHTTP {
  static Future<List<PluginHTTPItem>> getPluginList() async {
    List<PluginHTTPItem> pluginHTTPItemList = [];
    try {
      var res = await Request().get('${Api.pluginShop}index.json');
      final jsonData = json.decode(res.data);
      for (dynamic pluginJsonItem in jsonData) {
        try {
          PluginHTTPItem pluginHTTPItem = PluginHTTPItem.fromJson(pluginJsonItem);
          pluginHTTPItemList.add(pluginHTTPItem);
        } catch (_) {}
      }
    } catch (e) {
      KazumiLogger().e('Plugin: getPluginList error: ${e.toString()}');
    }
    return pluginHTTPItemList;
  }

  static Future<Plugin?> getPlugin(String name) async {
    Plugin? plugin;
    try {
      var res = await Request().get('${Api.pluginShop}$name.json');
      final jsonData = json.decode(res.data);
      plugin = Plugin.fromJson(jsonData);
    } catch(e) {
      KazumiLogger().e('Plugin: getPlugin error: ${e.toString()}');
    }
    return plugin;
  }
}