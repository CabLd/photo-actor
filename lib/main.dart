import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'pages/camera_filter_page.dart';
import 'commons/filePathHelper.dart';
import 'storage/template_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>('template_cache');
  await Hive.openBox<String>('capture_meta');
  await FilePathHelper.prepareAppDir();
  await TemplateCache.attemptInitialFetchOnce();
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
