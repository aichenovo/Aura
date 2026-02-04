import 'package:aura/pages/index_page.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:aura/pages/router.dart';
import 'package:aura/pages/init_page.dart';
import 'package:flutter/material.dart';
import 'package:aura/pages/popular/popular_controller.dart';
import 'package:aura/plugins/plugins_controller.dart';
import 'package:aura/pages/video/video_controller.dart';
import 'package:aura/pages/timeline/timeline_controller.dart';
import 'package:aura/pages/collect/collect_controller.dart';
import 'package:aura/pages/my/my_controller.dart';
import 'package:aura/pages/history/history_controller.dart';
import 'package:aura/pages/video/video_module.dart';
import 'package:aura/pages/info/info_module.dart';
import 'package:aura/pages/settings/settings_module.dart';
import 'package:aura/shaders/shaders_controller.dart';
import 'package:aura/pages/search/search_module.dart';
import 'package:aura/repositories/collect_repository.dart';
import 'package:aura/repositories/search_history_repository.dart';
import 'package:aura/repositories/collect_crud_repository.dart';
import 'package:aura/repositories/history_repository.dart';

class IndexModule extends Module {
  @override
  List<Module> get imports => menu.moduleList;

  @override
  void binds(i) {
    // Repository层
    i.addSingleton<ICollectRepository>(CollectRepository.new);
    i.addSingleton<ISearchHistoryRepository>(SearchHistoryRepository.new);
    i.addSingleton<ICollectCrudRepository>(CollectCrudRepository.new);
    i.addSingleton<IHistoryRepository>(HistoryRepository.new);

    // Controller层
    i.addSingleton(PopularController.new);
    i.addSingleton(PluginsController.new);
    i.addSingleton(VideoPageController.new);
    i.addSingleton(TimelineController.new);
    i.addSingleton(CollectController.new);
    i.addSingleton(HistoryController.new);
    i.addSingleton(MyController.new);
    i.addSingleton(ShadersController.new);
  }

  @override
  void routes(r) {
    r.child("/",
        child: (_) => const InitPage(),
        children: [
          ChildRoute(
            "/error",
            child: (_) => Scaffold(
              appBar: AppBar(title: const Text("Aura")),
              body: const Center(child: Text("初始化失败")),
            ),
          ),
        ],
        transition: TransitionType.noTransition);
    r.child(
      "/tab",
      child: (_) {
        return const IndexPage();
      },
      children: menu.routes,
      transition: TransitionType.fadeIn,
      duration: Duration(milliseconds: 70),
    );
    r.module("/video", module: VideoModule());
    /// The route need [ BangumiItem ] as argument.
    r.module("/info", module: InfoModule());
    r.module("/settings", module: SettingsModule());
    r.module("/search", module: SearchModule());
  }
}
