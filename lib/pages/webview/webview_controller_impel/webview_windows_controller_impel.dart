import 'dart:async';
import 'package:webview_windows/webview_windows.dart';
import 'package:aura/pages/webview/webview_controller.dart';
import 'package:aura/utils/storage.dart';
import 'package:aura/utils/proxy_utils.dart';
import 'package:aura/utils/logger.dart';

class WebviewWindowsItemControllerImpel
    extends WebviewItemController<WebviewController> {
  final List<StreamSubscription> subscriptions = [];

  @override
  Future<void> init() async {
    await _setupProxy();
    webviewController ??= WebviewController();
    await webviewController!.initialize();
    await webviewController!
        .setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
    initEventController.add(true);
  }

  Future<void> _setupProxy() async {
    final setting = GStorage.setting;
    final bool proxyEnable =
        setting.get(SettingBoxKey.proxyEnable, defaultValue: false);
    if (!proxyEnable) {
      return;
    }

    final String proxyUrl =
        setting.get(SettingBoxKey.proxyUrl, defaultValue: '');
    final formattedProxy = ProxyUtils.getFormattedProxyUrl(proxyUrl);
    if (formattedProxy == null) {
      return;
    }

    try {
      await WebviewController.initializeEnvironment(
        additionalArguments: '--proxy-server=$formattedProxy',
      );
      KazumiLogger().i('WebView: 代理设置成功 $formattedProxy');
    } catch (e) {
      KazumiLogger().e('WebView: 设置代理失败 $e');
    }
  }

  @override
  Future<void> loadUrl(String url, bool useNativePlayer, bool useLegacyParser,
      {int offset = 0}) async {
    await unloadPage();
    count = 0;
    this.offset = offset;
    isIframeLoaded = false;
    isVideoSourceLoaded = false;
    videoLoadingEventController.add(true);
    subscriptions.add(webviewController!.onM3USourceLoaded.listen((data) {
      String url = data['url'] ?? '';
      if (url.isEmpty) {
        return;
      }
      unloadPage();
      isIframeLoaded = true;
      isVideoSourceLoaded = true;
      videoLoadingEventController.add(false);
      logEventController.add('Loading m3u8 source: $url');
      videoParserEventController.add((url, offset));
    }));
    subscriptions.add(webviewController!.onVideoSourceLoaded.listen((data) {
      String url = data['url'] ?? '';
      if (url.isEmpty) {
        return;
      }
      unloadPage();
      isIframeLoaded = true;
      isVideoSourceLoaded = true;
      videoLoadingEventController.add(false);
      logEventController.add('Loading video source: $url');
      videoParserEventController.add((url, offset));
    }));
    await webviewController!.loadUrl(url);
    
    // Handle qqqys fragment parameters after page load
    if (url.contains('qqqys.com') && url.contains('#')) {
      Future.delayed(const Duration(milliseconds: 3000), () async {
        await webviewController!.executeScript('''
          (function() {
            if (window.location.hostname.includes('qqqys.com') && window.location.hash) {
              console.log('[qqqys] Fragment handler loaded: ' + window.location.href);
              console.log('[qqqys] Document ready state: ' + document.readyState);
              
              function handleQqqysFragment() {
                const hash = window.location.hash;
                console.log('[qqqys] Current hash: ' + hash);
                
                if (hash && hash.includes('sid=') && hash.includes('nid=')) {
                  console.log('[qqqys] Processing fragment: ' + hash);
                  
                  const params = new URLSearchParams(hash.substring(1));
                  const sid = params.get('sid');
                  const nid = parseInt(params.get('nid'), 10);
                  
                  console.log('[qqqys] Parsed parameters - sid: ' + sid + ' (type: ' + typeof sid + '), nid: ' + nid + ' (type: ' + typeof nid + ')');
                  
                  // Wait for Alpine.js to initialize the playlist component
                  let attempts = 0;
                  const maxAttempts = 30;
                  console.log('[qqqys] Starting to wait for playlist component...');
                  
                  const checkInterval = setInterval(() => {
                    attempts++;
                    
                    if (typeof window.playlist === 'function') {
                      clearInterval(checkInterval);
                      console.log('[qqqys] Playlist component found after ' + attempts + ' attempts');
                      
                      try {
                        const playlistInstance = window.playlist();
                        console.log('[qqqys] Playlist instance obtained');
                        
                        // sid is now the correct string value (e.g., "BBA", "YYNB") from URL hash
                        // No need to convert to number - use it directly
                        
                        // First select the source (sid)
                        if (playlistInstance.selectSource) {
                          playlistInstance.selectSource(sid);
                          console.log('[qqqys] ✓ Source selected: ' + sid);
                        } else {
                          console.log('[qqqys] ✗ selectSource method not found');
                        }
                        
                        // Then select the episode (nid)
                        if (playlistInstance.selectEpisode) {
                          setTimeout(() => {
                            playlistInstance.selectEpisode(nid);
                            console.log('[qqqys] ✓ Episode selected: ' + nid);
                            console.log('[qqqys] Final URL: ' + window.location.href);
                          }, 200);
                        } else {
                          console.log('[qqqys] ✗ selectEpisode method not found');
                        }
                      } catch (e) {
                        console.log('[qqqys] ✗ Error during selection: ' + e.message);
                        console.log('[qqqys] Error stack: ' + e.stack);
                      }
                    } else if (attempts >= maxAttempts) {
                      clearInterval(checkInterval);
                      console.log('[qqqys] ✗ Timeout: playlist component not found after ' + maxAttempts + ' attempts');
                      console.log('[qqqys] window.playlist type: ' + typeof window.playlist);
                    }
                  }, 100);
                } else {
                  console.log('[qqqys] Hash does not contain required parameters (sid and nid)');
                }
              }
              
              if (document.readyState === 'loading') {
                console.log('[qqqys] Waiting for DOMContentLoaded...');
                document.addEventListener('DOMContentLoaded', handleQqqysFragment);
              } else {
                console.log('[qqqys] Document already loaded, executing immediately');
                handleQqqysFragment();
              }
            } else {
              console.log('[qqqys] Conditions not met - hostname: ' + window.location.hostname + ', hash: ' + window.location.hash);
            }
          })();
        ''');
      });
    }
  }

  @override
  Future<void> unloadPage() async {
    subscriptions.forEach((s) {
      try {
        s.cancel();
      } catch (_) {}
    });
    await redirect2Blank();
  }

  @override
  void dispose() {
    subscriptions.forEach((s) {
      try {
        s.cancel();
      } catch (_) {}
    });
    // It's a custom function to dispose the whole webview environment in Predidit's flutter-webview-windows fork.
    // which allow re-initialization webview environment with different proxy settings.
    // It's difficult to get a dispose finish callback from Microsoft Edge WebView2 SDK,
    // so don't call webviewController.dispose() when we call WebviewController.disposeEnvironment(), WebViewController.disposeEnvironment() already do any necessary clean up internally.
    // ohtherwise, app will crash due to resource conflict.
    if (webviewController != null) {
      WebviewController.disposeEnvironment();
      webviewController = null;
    }
  }

  // The webview_windows package does not have a method to unload the current page. 
  // The loadUrl method opens a new tab, which can lead to memory leaks. 
  // Directly disposing of the webview controller would require reinitialization when switching episodes, which is costly. 
  // Therefore, this method is used to redirect to a blank page instead.
  Future<void> redirect2Blank() async {
    await webviewController!.executeScript('''
      window.location.href = 'about:blank';
    ''');
  }
}
