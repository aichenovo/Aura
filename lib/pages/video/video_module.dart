import 'package:aura/pages/video/video_page.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:aura/pages/webview/webview_controller.dart';
import 'package:aura/pages/player/player_controller.dart';

class VideoModule extends Module {
  @override
  void routes(r) {
    r.child("/", child: (_) => const VideoPage());
  }

  @override
  void binds(i) {
    i.addSingleton(PlayerController.new);
    i.addSingleton(WebviewItemControllerFactory.getController);
  }
}
