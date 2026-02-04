import 'dart:async';
import 'package:aura/pages/webview/webview_controller.dart';
import 'package:aura/utils/utils.dart';
import 'package:aura/utils/storage.dart';
import 'package:aura/utils/proxy_utils.dart';
import 'package:aura/utils/logger.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';

class WebviewLinuxItemControllerImpel extends WebviewItemController<Webview> {
  bool bridgeInited = false;

  @override
  Future<void> init() async {
    final proxyConfig = _getProxyConfiguration();
    webviewController ??= await WebviewWindow.create(
      configuration: CreateConfiguration(
        headless: true,
        proxy: proxyConfig,
        userScripts: const [
          UserScript(
              source: blobScript,
              injectionTime: UserScriptInjectionTime.documentStart,
              forAllFrames: true),
          UserScript(
              source: iframeScript,
              injectionTime: UserScriptInjectionTime.documentEnd,
              forAllFrames: true),
          UserScript(
              source: videoScript,
              injectionTime: UserScriptInjectionTime.documentEnd,
              forAllFrames: true),
          UserScript(
              source: qqqysFragmentScript,
              injectionTime: UserScriptInjectionTime.documentEnd,
              forAllFrames: false)
        ],
      ),
    );
    bridgeInited = false;
    initEventController.add(true);
  }

  ProxyConfiguration? _getProxyConfiguration() {
    final setting = GStorage.setting;
    final bool proxyEnable =
        setting.get(SettingBoxKey.proxyEnable, defaultValue: false);
    if (!proxyEnable) {
      return null;
    }

    final String proxyUrl =
        setting.get(SettingBoxKey.proxyUrl, defaultValue: '');
    final parsed = ProxyUtils.parseProxyUrl(proxyUrl);
    if (parsed == null) {
      return null;
    }

    final (host, port) = parsed;
    KazumiLogger().i('WebView: 代理设置成功 $host:$port');
    return ProxyConfiguration(host: host, port: port);
  }

  Future<void> initBridge(bool useNativePlayer, bool useLegacyParser) async {
    await initJSBridge(useNativePlayer, useLegacyParser);
    bridgeInited = true;
  }

  @override
  Future<void> loadUrl(String url, bool useNativePlayer, bool useLegacyParser,
      {int offset = 0}) async {
    await unloadPage();
    if (!bridgeInited) {
      await initBridge(useNativePlayer, useLegacyParser);
    }
    count = 0;
    this.offset = offset;
    isIframeLoaded = false;
    isVideoSourceLoaded = false;
    videoLoadingEventController.add(true);
    webviewController!.launch(url);
  }

  @override
  Future<void> unloadPage() async {
    await redirect2Blank();
  }

  @override
  void dispose() {
    webviewController!.close();
    bridgeInited = false;
  }

  Future<void> initJSBridge(bool useNativePlayer, bool useLegacyParser) async {
    webviewController!.addOnWebMessageReceivedCallback((message) async {
      if (message.contains('iframeMessage:')) {
        String messageItem =
            Uri.encodeFull(message.replaceFirst('iframeMessage:', ''));
        logEventController
            .add('Callback received: [iframe] ${Uri.decodeFull(messageItem)}');
        if ((messageItem.contains('http') || messageItem.startsWith('//')) &&
            !messageItem.contains('googleads') &&
            !messageItem.contains('googlesyndication.com') &&
            !messageItem.contains('prestrain.html') &&
            !messageItem.contains('prestrain%2Ehtml') &&
            !messageItem.contains('adtrafficquality')) {
          if (Utils.decodeVideoSource(messageItem) !=
                  Uri.encodeFull(messageItem) &&
              useNativePlayer &&
              useLegacyParser) {
            logEventController.add('Parsing video source $messageItem');
            isIframeLoaded = true;
            isVideoSourceLoaded = true;
            videoLoadingEventController.add(false);
            logEventController.add(
                'Loading video source ${Utils.decodeVideoSource(messageItem)}');
            unloadPage();
            videoParserEventController
                .add((Utils.decodeVideoSource(messageItem), offset));
          }
        }
      }
      if (message.contains('videoMessage:')) {
        String messageItem =
            Uri.encodeFull(message.replaceFirst('videoMessage:', ''));
        logEventController
            .add('Callback received: [video] ${Uri.decodeFull(messageItem)}');
        if (messageItem.contains('http')) {
          String videoUrl = Uri.decodeFull(messageItem);
          logEventController.add('Loading video source: $videoUrl');
          isIframeLoaded = true;
          isVideoSourceLoaded = true;
          videoLoadingEventController.add(false);
          if (useNativePlayer) {
            unloadPage();
            videoParserEventController.add((videoUrl, offset));
          }
        }
      }
    });
  }

  static const String iframeScript = """
    var iframes = document.getElementsByTagName('iframe');
    for (var i = 0; i < iframes.length; i++) {
        var iframe = iframes[i];
        var src = iframe.getAttribute('src');
        if (src) {
          window.webkit.messageHandlers.msgToNative.postMessage('iframeMessage:' + src);
        }
    }
  """;

  static const String videoScript = """
    function processVideoElement(video) {
      let src = video.getAttribute('src');
      if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.includes('googleads')) {
        window.webkit.messageHandlers.msgToNative.postMessage('videoMessage:' + src);
        return;
      }
      const sources = video.getElementsByTagName('source');
      for (let source of sources) {
        src = source.getAttribute('src');
        if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.includes('googleads')) {
          window.webkit.messageHandlers.msgToNative.postMessage('videoMessage:' + src);
          return;
        }
      }
    }

    document.querySelectorAll('video').forEach(processVideoElement);

    const _observer = new MutationObserver((mutations) => {
      mutations.forEach(mutation => {
        if (mutation.type === 'attributes' && mutation.target.nodeName === 'VIDEO') {
          processVideoElement(mutation.target);
        }
        mutation.addedNodes.forEach(node => {
          if (node.nodeName === 'VIDEO') processVideoElement(node);
          if (node.querySelectorAll) {
            node.querySelectorAll('video').forEach(processVideoElement);
          }
        });
      });  
    });

    _observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['src']
    });
  """;

  static const String blobScript = """
    const _r_text = window.Response.prototype.text;
    window.Response.prototype.text = function () {
        return new Promise((resolve, reject) => {
            _r_text.call(this).then((text) => {
                resolve(text);
                if (text.trim().startsWith("#EXTM3U")) {
                    window.webkit.messageHandlers.msgToNative.postMessage('videoMessage:' + this.url);
                }
            }).catch(reject);
        });
    }

    const _open = window.XMLHttpRequest.prototype.open;
    window.XMLHttpRequest.prototype.open = function (...args) {
        this.addEventListener("load", () => {
            try {
                let content = this.responseText;
                if (content.trim().startsWith("#EXTM3U")) {
                    window.webkit.messageHandlers.msgToNative.postMessage('videoMessage:' + args[1]);
                };
            } catch { }
        });
        return _open.apply(this, args);
    }
  """;

  static const String qqqysFragmentScript = """
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
  """;

  Future<void> redirect2Blank() async {
     webviewController?.launch("about:blank");
  }
}
