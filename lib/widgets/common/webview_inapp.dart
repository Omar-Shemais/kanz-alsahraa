import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' hide kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:inspireui/widgets/platform_error/platform_error.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../models/entities/cookie_data.dart';
import '../../services/native_browser_session.dart';
import '../../services/web_navigation_policy.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class WebViewInApp extends StatefulWidget {
  final String url;
  final String? title;
  final String? script;
  final Function(String?, String?, InAppWebViewController?)? onUrlChanged;
  final Map<String, String>? headers;
  final Function? onClosed;
  final bool enableForward;
  final bool enableBackward;
  final bool enableClose;
  final Function? overrideNavigation;
  final AppBar? appBar;
  final bool showAppBar;
  final bool showLoading;
  final List<CookieData>? cookies;

  const WebViewInApp({
    super.key,
    required this.url,
    this.title,
    this.script,
    this.onUrlChanged,
    this.onClosed,
    this.headers,
    this.enableBackward = true,
    this.enableForward = true,
    this.enableClose = true,
    this.overrideNavigation,
    this.appBar,
    this.showAppBar = true,
    this.showLoading = true,
    this.cookies,
  });

  @override
  State<WebViewInApp> createState() => _WebViewInAppState();
}

class _WebViewInAppState extends State<WebViewInApp> {
  final GlobalKey webViewKey = GlobalKey();

  int selectedIndex = 1;

  InAppWebViewController? webViewController;
  bool _sessionError = false;
  final _sessionGeneration = browserSession.generation;

  Future<void> _clearSession() async {
    if (mounted && _sessionGeneration != browserSession.generation) {
      setState(() => _sessionError = true);
    }
    final controller = webViewController;
    if (controller == null) return;
    await controller.stopLoading();
    await controller.evaluateJavascript(
        source:
            'try { localStorage.clear(); sessionStorage.clear(); } catch (_) {}');
    await controller.loadUrl(
        urlRequest: URLRequest(url: WebUri('about:blank')));
    if (mounted && _sessionGeneration != browserSession.generation) {
      setState(() => _sessionError = true);
    }
  }

  Future<void> _openSession() async {
    try {
      if (webUrlAction(widget.url) != WebUrlAction.embed ||
          widget.url == 'about:blank') {
        throw StateError('Unsafe initial web URL');
      }
      await browserSession.ensureReady();
      if (!mounted) return;
      if (_sessionGeneration != browserSession.generation) {
        throw StateError('Account session changed');
      }
      await browserSession.open(_sessionGeneration, () async {
        for (final cookie in widget.cookies ?? <CookieData>[]) {
          if (cookie.valid) {
            await CookieManager.instance().setCookie(
              url: WebUri(widget.url),
              name: cookie.name,
              value: cookie.value,
              isSecure: true,
            );
          }
        }
        if (!mounted) return;
        await webViewController?.loadUrl(
            urlRequest:
                URLRequest(url: WebUri(widget.url), headers: widget.headers));
      });
      if (mounted) setState(() => _sessionError = false);
    } catch (_) {
      if (mounted) setState(() => _sessionError = true);
    }
  }

  InAppWebViewSettings settings = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    transparentBackground: true,
    mediaPlaybackRequiresUserGesture: false,
    useOnDownloadStart: true,
    useHybridComposition: true,
    allowsInlineMediaPlayback: true,
  );

  late PullToRefreshController pullToRefreshController;
  bool get _canPop =>
      ModalRoute.of(context)?.canPop ?? Navigator.of(context).canPop();

  void onTapBackButton() async {
    if (_sessionGeneration != browserSession.generation) return;
    final value = await webViewController?.canGoBack();
    if (value == true) {
      await webViewController?.goBack();
    } else if (!widget.enableClose && _canPop) {
      widget.onClosed?.call();
      Navigator.of(context).pop();
    }
  }

  void onTapForwardButton() {
    if (_sessionGeneration != browserSession.generation) return;
    webViewController?.goForward();
  }

  void onTapCloseButton() async {
    widget.onClosed?.call();

    if (_canPop) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    browserSession.unregister(_clearSession);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.black45,
      ),
      onRefresh: () async {
        printLog('[WebView InApp] Pull to Refresh');
        if (isAndroid) {
          await webViewController?.reload();
        } else if (isIos) {
          await webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || isDesktop) {
      return const PlatformError(
        enablePop: false,
      );
    }
    return Scaffold(
      appBar: !widget.showAppBar
          ? null
          : widget.appBar ??
              AppBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0.0,
                centerTitle: true,
                title: Text(
                  widget.title ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                leadingWidth: 150,
                actions: [
                  if (widget.enableClose)
                    IconButton(
                      onPressed: onTapCloseButton,
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  const SizedBox(width: 10),
                ],
                leading: Builder(builder: (buildContext) {
                  return Row(
                    children: [
                      const SizedBox(width: 20),
                      if (widget.enableBackward)
                        IconButton(
                          icon: Icon(Tools.getBackIcon(context), size: 20),
                          onPressed: onTapBackButton,
                        ),
                      if (webViewController?.canGoForward() != null &&
                          widget.enableForward)
                        IconButton(
                          onPressed: onTapForwardButton,
                          icon: Icon(Tools.getForwardIcon(context), size: 20),
                        ),
                    ],
                  );
                }),
              ),
      body: IndexedStack(
        index: _sessionError ? 2 : selectedIndex,
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(url: WebUri('about:blank')),
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              if (_sessionGeneration != browserSession.generation &&
                  navigationAction.request.url?.toString() != 'about:blank') {
                return NavigationActionPolicy.CANCEL;
              }
              final url = navigationAction.request.url.toString();
              final action = webUrlAction(url);
              if (action == WebUrlAction.block) {
                return NavigationActionPolicy.CANCEL;
              }
              if (action == WebUrlAction.external) {
                try {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                } catch (_) {}
                return NavigationActionPolicy.CANCEL;
              }
              final result = await widget.overrideNavigation?.call(url);

              if (result == true) {
                return NavigationActionPolicy.CANCEL;
              }

              return NavigationActionPolicy.ALLOW;
            },
            initialUserScripts: UnmodifiableListView<UserScript>([
              /// Demo the Javascript Style override
              UserScript(
                source: originBoundWebScript(widget.script ?? '', widget.url),
                forMainFrameOnly: true,
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
              ),
            ]),
            gestureRecognizers: <Factory<VerticalDragGestureRecognizer>>{}..add(
                const Factory<VerticalDragGestureRecognizer>(
                    VerticalDragGestureRecognizer.new),
              ),
            initialSettings: settings,
            pullToRefreshController: pullToRefreshController,
            onWebViewCreated: (controller) {
              webViewController = controller;
              browserSession.register(_clearSession);
              _openSession();
            },
            onPermissionRequest: (controller, request) async {
              return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.DENY,
              );
            },
            onGeolocationPermissionsShowPrompt:
                (InAppWebViewController controller, String origin) async {
              // No embedded store or payment origin needs geolocation.
              return GeolocationPermissionShowPromptResponse(
                origin: origin,
                allow: false,
                retain: false,
              );
            },
            onReceivedError: (controller, request, error) {
              pullToRefreshController.endRefreshing();
            },
            onLoadStop: (androidIsReload, uri) {
              if (uri?.toString() == 'about:blank' ||
                  _sessionGeneration != browserSession.generation) {
                return;
              }
              setState(() {
                selectedIndex = 0;
              });
              if (isAndroid) {
                _onUrlChange(uri);
              }
            },
            onProgressChanged: (_, progress) {
              if (progress == 100) {
                pullToRefreshController.endRefreshing();
              }
            },
            onUpdateVisitedHistory: (ctrl, uri, androidIsReload) {
              if (isAndroid == false) {
                _onUrlChange(uri);
              }
            },
            onDownloadStartRequest: (_, request) async {
              final value = request.url.toString();
              if (webUrlAction(value) == WebUrlAction.embed &&
                  value != 'about:blank') {
                try {
                  await launchUrl(Uri.parse(value),
                      mode: LaunchMode.externalApplication);
                } catch (_) {}
              }
            },
          ),
          if (widget.showLoading)
            Center(
              child: kLoadingWidget(context),
            )
          else
            const SizedBox(),
          Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('تعذر فتح الصفحة بأمان. أغلقها وافتحها مجددًا.'),
            TextButton(
                onPressed: _openSession, child: const Text('إعادة المحاولة')),
          ])),
        ],
      ),
    );
  }

  Future<void> _onUrlChange(WebUri? uri) async {
    if (uri == null ||
        uri.toString() == 'about:blank' ||
        _sessionGeneration != browserSession.generation) {
      return;
    }
    if (widget.onUrlChanged != null) {
      final html = await webViewController?.getHtml();
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.onUrlChanged!(uri.toString(), html, webViewController));
    }
  }
}
