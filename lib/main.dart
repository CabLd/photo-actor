import 'package:flutter/material.dart';

import 'pages/camera_filter_page.dart';
import 'commons/filePathHelper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FilePathHelper.prepareAppDir();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shader Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Shader Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Camera Filter Shader Research'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CameraFilterPage()),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Camera Filter'),
            ),
          ],
        ),
      ),
    );
  }
}
