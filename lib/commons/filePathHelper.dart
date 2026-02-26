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

  static Directory? _ensureDirectory(String dirPath) {
    if (appDocDir.isEmpty) {
      print(
        '_ensureDirectory: appDocDir not prepared, call prepareAppDir() first',
      );
      return null;
    }
    final directory = Directory(dirPath);
    try {
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      if (!directory.existsSync()) return null;
      return directory;
    } on Exception catch (e) {
      print('_ensureDirectory Exception ${e.toString()}');
      return null;
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
    final directory = _ensureDirectory(dirPath);
    if (directory == null) return null;
    return '${directory.path}/$name';
  }

  /// 获取相机成片保存路径（同步）。调用前必须已执行 prepareAppDir()，否则返回 null。
  static String? getCapturedImageFilePath(String name) {
    final dirPath = '$appDocDir/camera/captures';
    final directory = _ensureDirectory(dirPath);
    if (directory == null) return null;
    return '${directory.path}/$name';
  }

  /// 列出已保存的相机成片，按修改时间倒序（最新在前）。
  static List<File> listCapturedImagesSorted() {
    if (appDocDir.isEmpty) {
      print(
        'listCapturedImagesSorted: appDocDir not prepared, call prepareAppDir() first',
      );
      return [];
    }
    final dirPath = '$appDocDir/camera/captures';
    final directory = Directory(dirPath);
    if (!directory.existsSync()) return [];

    final files = <File>[];
    try {
      for (final entity in directory.listSync(followLinks: false)) {
        if (entity is! File) continue;
        final lower = entity.path.toLowerCase();
        if (!lower.endsWith('.png') &&
            !lower.endsWith('.jpg') &&
            !lower.endsWith('.jpeg')) {
          continue;
        }
        files.add(entity);
      }

      files.sort((a, b) {
        DateTime am;
        DateTime bm;
        try {
          am = a.statSync().modified;
        } catch (_) {
          am = DateTime.fromMillisecondsSinceEpoch(0);
        }
        try {
          bm = b.statSync().modified;
        } catch (_) {
          bm = DateTime.fromMillisecondsSinceEpoch(0);
        }
        return bm.compareTo(am);
      });
      return files;
    } catch (e) {
      print('listCapturedImagesSorted Exception ${e.toString()}');
      return [];
    }
  }
}
