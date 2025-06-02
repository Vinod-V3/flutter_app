import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({Key? key, required this.url}) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late InAppWebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _webViewController.canGoBack()) {
          _webViewController.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("WebView")),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowsInlineMediaPlayback: true,
            mediaPlaybackRequiresUserGesture: false,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;

            _webViewController.addJavaScriptHandler(
              handlerName: 'FlutterChannel',
              callback: (args) async {
                final data = args[0];
                final content = data['url'];
                final title = data['title'];

                if (data['type'] == 'share') {
                  await downloadAndSharePdf(content, title);
                } else if (data['type'] == 'download') {
                  await downloadFileToDownloads(content, title);
                }else if(data["type"] == "redirect"){
                  if(data["pathType"] == "profile"){
                    await Navigator.pushNamed(context, '<path-to-profile>');
                  }else if(data["pathType"] == "login"){
                    await Navigator.pushNamed(context, '<path-to-login>');
                  }
                }
              },
            );
          },
          onLoadStop: (controller, url) async {
            await _setTokenInWebView();
            await controller.evaluateJavascript(source: """
              window.FlutterChannel = {
                postMessage: function(data) {
                  window.flutter_inappwebview.callHandler('FlutterChannel', data);
                }
              };
            """);
          },
        ),
      ),
    );
  }

  Future<void> _setTokenInWebView() async {
    await _webViewController.evaluateJavascript(source: """
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

  Future<void> downloadAndSharePdf(String url, String filename) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception("Download failed");

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$filename.pdf';
      final file = File(path)..writeAsBytesSync(response.bodyBytes);

      final xFile = XFile(path, name: "$filename.pdf", mimeType: 'application/pdf');
      await Share.shareXFiles([xFile], text: "Sharing PDF: $filename");
    } catch (e) {
      print("Download/share error: $e");
    }
  }

  Future<void> downloadFileToDownloads(String url, String filename) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) throw Exception("Storage permission not granted");
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception("Download failed");

      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      final path = '${downloadDir.path}/$filename.pdf';
      final file = File(path)..writeAsBytesSync(response.bodyBytes);

      print("Saved to: $path");
    } catch (e) {
      print("File save error: $e");
    }
  }
}
