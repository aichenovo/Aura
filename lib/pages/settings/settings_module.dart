import 'package:aura/pages/settings/danmaku/danmaku_module.dart';
import 'package:aura/pages/about/about_module.dart';
import 'package:aura/pages/plugin_editor/plugin_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:aura/pages/history/history_module.dart';
import 'package:aura/pages/settings/theme_settings_page.dart';
import 'package:aura/pages/settings/player_settings.dart';
import 'package:aura/pages/settings/displaymode_settings.dart';
import 'package:aura/pages/settings/decoder_settings.dart';
import 'package:aura/pages/settings/super_resolution_settings.dart';
import 'package:aura/pages/settings/proxy/proxy_module.dart';
import 'package:aura/pages/webdav_editor/webdav_module.dart';
import 'package:aura/pages/settings/keyboard_settings.dart';

class SettingsModule extends Module {
  @override
  void routes(r) {
    r.child("/theme", child: (_) => const ThemeSettingsPage());
    r.child(
      "/theme/display",
      child: (_) => const SetDisplayMode(),
    );
    r.child("/keyboard", child: (_) => const KeyboardSettingsPage());
    r.child("/player", child: (_) => const PlayerSettingsPage());
    r.child("/player/decoder", child: (_) => const DecoderSettings());
    r.module("/proxy", module: ProxyModule());
    r.child("/player/super", child: (_) => const SuperResolutionSettings());
    r.module("/webdav", module: WebDavModule());
    r.module("/about", module: AboutModule());
    r.module("/plugin", module: PluginModule());
    r.module("/history", module: HistoryModule());
    r.module("/danmaku", module: DanmakuModule());
  }
}
