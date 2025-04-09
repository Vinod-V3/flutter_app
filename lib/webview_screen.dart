import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({Key? key, required this.url}) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url){
            _setTokenInWebView();
          }
        )
      );
  }

    void _setTokenInWebView() {
      _controller.runJavaScript("""
        localStorage.setItem('headers',JSON.stringify({
          "authorization": "Bearer <value>",
          "x-auth-token": "<value>",
          "x-authenticated-user-token": "<value>",
          "x-channel-id": "<value>",
          "x-device-id": "<value>",
          "x-session-id": "<value>"
        }));
        localStorage.setItem('name', <value>);
        localStorage.setItem('accToken',<value>);
        localStorage.setItem('profileData', JSON.stringify({
          "state": "<value>",
          "cluster": "<value>",
          "district": "<value>",
          "block": "<value>",
          "school": "<value>",
          "role": "<value>"
        }));
      """);
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text("WebView")),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}