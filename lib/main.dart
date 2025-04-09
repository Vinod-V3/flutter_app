import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'webview_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter WebView Example',
      home: HomeScreen(),
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  void _openWebView(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: url
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home Page in Flutter app")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _openWebView("https://elevate-ml.shikshalokam.org/listing/project?type=project"),
              child: const Text("PROJECTS LISTING"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _openWebView("https://elevate-ml.shikshalokam.org/listing/project?type=survey"),
              child: const Text("SURVEY LISTING"),
            ),
          ],
        ),
      ),
    );
  }
}