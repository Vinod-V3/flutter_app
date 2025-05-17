import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final Map<String, dynamic> data = jsonDecode(message.message);
          final content = '${data['url']}';
          final title = '${data['title']}';
          print("Flutter channel data received: ${data}");
          if (data['type'] == 'share') {
            downloadAndSharePdf(content,title);
            // );
          }else if(data['type'] == 'download'){
            downloadFileToDownloads(content, title);
          }
        },
      )
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

Future<void> downloadAndSharePdf(String url, String filename) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download file');
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$filename.pdf';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    final xFile = XFile(filePath, name: "$filename.pdf", mimeType: 'application/pdf');
    await Share.shareXFiles([xFile], text: "Sharing PDF: $filename");

  } catch (e) {
    print("Error downloading or sharing PDF: $e");
  }
}


Future<void> downloadFileToDownloads(String url, String filename) async {
  try {
    // if (Platform.isAndroid) {
    //   var status = await Permission.storage.request();
    //   if (!status.isGranted) {
    //     throw Exception("Storage permission not granted");
    //   }
    // }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download file');
    }

    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else {
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    final filePath = '${downloadsDir.path}/$filename.pdf';
    final file = File(filePath);

    await file.writeAsBytes(response.bodyBytes);

    print("File saved to: $filePath");
  } catch (e) {
    print("Error saving file: $e");
  }
}

}