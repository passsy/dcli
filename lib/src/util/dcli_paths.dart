import '../settings.dart';

/// platform specific names of the dcli commands.
class DCliPaths {
  ///
  factory DCliPaths() => _self ??= DCliPaths._internal();

  DCliPaths._internal() {
    if (Settings().isWindows) {
      dcliName = 'dcli.bat';
      dcliInstallName = 'dcli_install.bat';
      dcliCompleteName = 'dcli_complete.bat';
    } else {
      dcliName = 'dcli';
      dcliInstallName = 'dcli_install';
      dcliCompleteName = 'dcli_complete';
    }
  }

  static DCliPaths? _self;

  /// platform specific name of the dcli command
  late String dcliName;

  /// platform specific name of the dcli install command
  String? dcliInstallName;

  /// platform specific name of the dcli auto complete command
  String? dcliCompleteName;
}
