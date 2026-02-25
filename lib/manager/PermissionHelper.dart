import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static PermissionStatus micPermission = PermissionStatus.denied;

  static Future<void> getMicPermission() async {
    micPermission = await Permission.microphone.status;
  }

  static Future<bool> requestMicrophonePermission(String message) async {
    Permission permission = Permission.microphone;
    return _requestPermission(permission, message: message);
  }

  static Future<bool> _requestPermission(
    Permission permission, {
    String? title,
    String? message,
    bool isOpenSettings = true,
  }) async {
    try {
      PermissionStatus status = await permission.status;
      if (status.isDenied) {
        //We didn't ask for permission yet.
        PermissionStatus _s = await permission.request();
        bool isGranted = _s.isGranted;
        if (isGranted) {
          return true;
        } else {
          if (isOpenSettings) {
            print("todo isOpenSettings");
            // _showCustomAlert(
            //   message,
            //   title: title,
            //   permission: permission,
            // );
          }
        }
      } else if (status.isGranted) {
        return true;
      } else {
        if (isOpenSettings) {
          print("todo isOpenSettings");
          // _showCustomAlert(
          //   message,
          //   title: title,
          //   permission: permission,
          // );
        }
        return false;
      }
    } on PlatformException catch (e) {
      // XLogManager.log(
      //     tag: [XLogTag.error],
      //     content:
      //     '${permission.toString()} permission request error occurred, ${e.toString()}');
    }
    return false;
  }
}
