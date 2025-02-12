import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'tawk_user.dart';
import 'tawk_visitor.dart';

/// [Tawk] Widget.
class Tawk extends StatefulWidget {
  /// Tawk direct chat link.
  final String directChatLink;

  /// Object used to set the visitor name and email.
  final TawkVisitor? visitor;
  final TawkUser? user;
  final String? siteApiKey;

  /// Called right after the widget is rendered.
  final Function? onLoad;

  /// Called when a link pressed.
  final Function(String)? onLinkTap;

  /// Render your own loading widget.
  final Widget? placeholder;

  const Tawk({
    Key? key,
    required this.directChatLink,
    this.visitor,
    this.onLoad,
    this.onLinkTap,
    this.placeholder,
    this.user,
    this.siteApiKey,
  }) : super(key: key);

  @override
  _TawkState createState() => _TawkState();
}

class _TawkState extends State<Tawk> {
  late InAppWebViewController _controller;
  bool _isLoading = true;

  String generateHmacSha256(String message, String secretKey) {
    // Convert the secret key and message to UTF-8 encoded bytes
    var keyBytes = utf8.encode(secretKey);
    var messageBytes = utf8.encode(message);

    // Create an HMAC object using SHA256 and the secret key
    var hmacSha256 = Hmac(sha256, keyBytes);

    // Generate the HMAC hash as bytes
    var digest = hmacSha256.convert(messageBytes);

    // Optionally, encode the digest to a base64 string
    var base64Hash = base64.encode(digest.bytes);

    return base64Hash;
  }

  void login({
    required String siteApiKey,
    required TawkUser user,
  }) {
    var message = user.id + siteApiKey;
    //hash is a combination of userId + site API key using HMAC SHA256
    String hash = generateHmacSha256(message, siteApiKey);
    String script = '''
  var Tawk_API = Tawk_API || {};
  Tawk_API.onLoad = function() {
    Tawk_API.login({
      hash: $hash, // Required
      userId: '${user.id}',     // Required
      name: '${user.userName}',            // Optional
      phone: '${user.phone}'     // Optional
    }, function(error) {
      if (error) {
        console.error('Login error:', error);
      }
    });
  };

''';
    try {
      var result = _controller.evaluateJavascript(source: script);
      debugPrint("Result" + result.toString());
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _setUser(TawkVisitor visitor) {
    final json = jsonEncode(visitor);
    String javascriptString;

    if (Platform.isIOS) {
      javascriptString = '''
        Tawk_API = Tawk_API || {};
        Tawk_API.setAttributes($json);
      ''';
    } else {
      javascriptString = '''
        Tawk_API = Tawk_API || {};
        Tawk_API.onLoad = function() {
          Tawk_API.setAttributes($json);
        };
      ''';
    }
    try {
      var result = _controller.evaluateJavascript(source: javascriptString);
      debugPrint("Result" + result.toString());
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void init() async {
    if (Platform.isAndroid) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);

      var swAvailable = await WebViewFeature.isFeatureSupported(
          WebViewFeature.SERVICE_WORKER_BASIC_USAGE);
      var swInterceptAvailable = await WebViewFeature.isFeatureSupported(
          WebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);

      if (swAvailable && swInterceptAvailable) {
        ServiceWorkerController serviceWorkerController =
            ServiceWorkerController.instance();

        await serviceWorkerController
            .setServiceWorkerClient(ServiceWorkerClient(
          shouldInterceptRequest: (request) async {
            return null;
          },
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InAppWebView(
          gestureRecognizers: {}..add(Factory<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer())),
          initialUrlRequest:
              URLRequest(url: WebUri.uri(Uri.parse(widget.directChatLink))),
          onWebViewCreated: (webViewController) {
            setState(() {
              _controller = webViewController;
            });
          },
          onLoadStop: (_, __) {
            init();
            if (widget.visitor != null) {
              _setUser(widget.visitor!);
            } else if (widget.user != null && widget.siteApiKey != null) {
// 47f1db58dd5ddc0d79103bfc64fec0ebb979509b
              login(
                siteApiKey: widget.siteApiKey!,
                user: widget.user!,
              );
            }

            if (widget.onLoad != null) {
              widget.onLoad!();
            }

            setState(() {
              _isLoading = false;
            });
          },
        ),
        _isLoading
            ? widget.placeholder ??
                const Center(
                  child: CircularProgressIndicator(),
                )
            : Container(),
      ],
    );
  }
}
