import 'dart:async';
import 'package:flutter/services.dart';

class PlatformChannel {
  static const MethodChannel _channel = MethodChannel('read/setWindowSize');

  // 设置窗口大小
  static Future<void> setWindowSize(double width, double height) async {
    try {
      await _channel.invokeMethod('setWindowSize', {'width': width, 'height': height});
    } on PlatformException catch (e) {
      print("Error setting window size: $e");
    }
  }

  // 根据屏幕尺寸的比例设置窗口大小
  static Future<void> setWindowSizeToFraction(double widthFraction, double heightFraction) async {
    try {
      await _channel.invokeMethod('setWindowSizeToFraction', {'widthFraction': widthFraction, 'heightFraction': heightFraction});
    } on PlatformException catch (e) {
      print("Error setting window size: $e");
    }
  }
}
