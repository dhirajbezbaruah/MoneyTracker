import 'package:package_info_plus/package_info_plus.dart';

class VersionUtil {
  static PackageInfo? _packageInfo;

  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  static String get version {
    return _packageInfo?.version ?? '1.5.0';
  }

  static String get buildNumber {
    return _packageInfo?.buildNumber ?? '7';
  }

  static String get fullVersion {
    return '$version+$buildNumber';
  }
}
