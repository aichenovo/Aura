import 'dart:async';
import 'dart:io';

import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:webview_windows/webview_windows.dart';

class WebviewHtmlFetcher {
  Future<String> fetchHtml(
    String url, {
    Duration timeout = const Duration(seconds: 45),
    Duration settleDelay = const Duration(milliseconds: 600),
    Duration pollInterval = const Duration(milliseconds: 400),
    Duration maxPoll = const Duration(seconds: 20),
    int minHtmlLength = 2000,
    String? userAgent,
  }) async {
    if (Platform.isWindows) {
      final headless = HeadlessWebview();
      try {
        await headless.run().timeout(timeout);
        await headless.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
        if (userAgent != null && userAgent.trim().isNotEmpty) {
          await headless.setUserAgent(userAgent.trim());
        }

        final navDone = Completer<void>();
        late final StreamSubscription sub;
        sub = headless.loadingState.listen((state) {
          if (state == LoadingState.navigationCompleted &&
              !navDone.isCompleted) {
            navDone.complete();
          }
        });

        await headless.loadUrl(url).timeout(timeout);
        await navDone.future.timeout(timeout);
        await sub.cancel();

        await Future<void>.delayed(settleDelay);

        final deadline = DateTime.now().add(maxPoll);
        String html = '';
        while (DateTime.now().isBefore(deadline)) {
          final dynamic res =
              await headless.executeScript('document.documentElement.outerHTML');
          if (res is String && res.isNotEmpty) {
            html = res;
            if (!_looksLikeWafBlock(html) &&
                _looksLoadedEnough(html, minHtmlLength)) {
              return html;
            }
          }
          await Future<void>.delayed(pollInterval);
        }

        return html;
      } finally {
        try {
          await headless.dispose();
        } catch (_) {}
      }
    }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      throw UnsupportedError('WebviewHtmlFetcher is only supported on Windows/Android/iOS');
    }

    PlatformInAppWebViewController? controller;
    final created = Completer<void>();
    final navDone = Completer<void>();
    final headless = PlatformHeadlessInAppWebView(
      PlatformHeadlessInAppWebViewCreationParams(
        initialSettings: InAppWebViewSettings(
          userAgent: userAgent?.trim(),
          cacheEnabled: false,
          clearCache: true,
          transparentBackground: true,
          mediaPlaybackRequiresUserGesture: true,
          geolocationEnabled: false,
          upgradeKnownHostsToHTTPS: false,
        ),
        onWebViewCreated: (c) {
          controller = c;
          if (!created.isCompleted) created.complete();
        },
        onLoadStop: (_, __) {
          if (!navDone.isCompleted) navDone.complete();
        },
      ),
    );

    try {
      await headless.run().timeout(timeout);
      await created.future.timeout(timeout);
      await controller
          ?.loadUrl(urlRequest: URLRequest(url: WebUri(url)))
          .timeout(timeout);
      await navDone.future.timeout(timeout);

      await Future<void>.delayed(settleDelay);

      final deadline = DateTime.now().add(maxPoll);
      String html = '';
      while (DateTime.now().isBefore(deadline)) {
        final res = await controller?.evaluateJavascript(
            source: 'document.documentElement.outerHTML');
        if (res is String && res.isNotEmpty) {
          html = res;
          if (!_looksLikeWafBlock(html) && _looksLoadedEnough(html, minHtmlLength)) {
            return html;
          }
        }
        await Future<void>.delayed(pollInterval);
      }
      return html;
    } finally {
      try {
        await headless.dispose();
      } catch (_) {}
    }
  }

  bool _looksLikeWafBlock(String html) {
    final lower = html.toLowerCase();
    if (lower.contains('safeline')) return true;
    if (lower.contains('sl-session')) return true;
    if (lower.contains('human verification')) return true;
    if (lower.contains('人机验证')) return true;
    if (lower.contains('challenge-platform')) return true;
    if (lower.contains('cf-chl')) return true;
    return false;
  }

  bool _looksLoadedEnough(String html, int minHtmlLength) {
    if (html.length >= minHtmlLength) return true;
    final lower = html.toLowerCase();
    if (!lower.contains('<body')) return false;
    if (!lower.contains('</body')) return false;
    return true;
  }
}
