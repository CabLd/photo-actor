import 'dart:math';
import 'dart:ui';

class SizeConfig {
  static final PlatformDispatcher _platformDispatcher =
      PlatformDispatcher.instance;

  static FlutterView get _viewConfiguration => _platformDispatcher.views.first;

  static double get _devicePixelRatio =>
      _platformDispatcher.views.first.devicePixelRatio;

  static double get screenWidth =>
      _viewConfiguration.physicalSize.width / _devicePixelRatio;

  static double get screenHeight =>
      _viewConfiguration.physicalSize.height / _devicePixelRatio;

  static double get topMargin =>
      _viewConfiguration.padding.top / _devicePixelRatio;

  static double _bottomMargin = 0;

  static double get bottomMargin {
    _bottomMargin = max(
      _viewConfiguration.padding.bottom / _devicePixelRatio,
      _bottomMargin,
    );
    return _bottomMargin;
  }

  static double defaultHeight = getProportionateScreenHeight(230);

  static double adaptNormal(double value) {
    double widthScale = screenWidth / 375;
    double heightScale = screenHeight / 667;

    return widthScale > heightScale
        ? (heightScale * value).floorToDouble()
        : (widthScale * value).floorToDouble();
  }
}

// Get the proportionate height as per screen size
double getProportionateScreenHeight(double inputHeight) {
  double screenHeight = SizeConfig.screenHeight;
  // 812 is the layout height that designer use
  return (inputHeight / 800.0) * screenHeight;
}

// Get the proportionate height as per screen size
double getProportionateScreenWidth(double inputWidth) {
  double screenWidth = SizeConfig.screenWidth;
  // 375 is the layout width that designer use
  return (inputWidth / 360.0) * screenWidth;
}

double getProportionateScreenScale(double value) {
  double screenWidth = SizeConfig.screenWidth;
  double screenHeight = SizeConfig.screenHeight;
  double scaleWidth = (screenWidth / 375.0);
  double scaleHeight = (screenHeight / 812.0);
  double scale = scaleWidth > scaleHeight ? scaleHeight : scaleWidth;
  return scale * value;
}

extension SizeConfigExt on num {
  double get pt => getProportionateScreenWidth(toDouble());
}
