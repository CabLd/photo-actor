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
      debugShowCheckedModeBanner: false,
      title: 'Shader Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CameraFilterPage(),
    );
  }
}
