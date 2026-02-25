import 'dart:io';

import 'package:path_provider/path_provider.dart';

class FilePathHelper {
  static String appDocDir = '';

  static Future<bool?> prepareAppDir() async {
    try {
      appDocDir = (await getApplicationDocumentsDirectory()).path;
      return true;
    } catch (e) {
      print('prepareAppDir Exception ${e.toString()}');
      return false;
    }
  }

  /// 获取语音存储路径（同步）。调用前必须已执行 prepareAppDir()，否则返回 null。
  static String? getChatAudioFilePath(String name) {
    if (appDocDir.isEmpty) {
      print(
        'getChatAudioFilePath: appDocDir not prepared, call prepareAppDir() first',
      );
      return null;
    }
    final dirPath = '$appDocDir/chat/audio';
    final directory = Directory(dirPath);
    try {
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
        if (!directory.existsSync()) {
          return null;
        }
      }
      return '${directory.path}/$name';
    } on Exception catch (e) {
      print('getChatAudioFilePath Exception ${e.toString()}');
      return null;
    }
  }
}
