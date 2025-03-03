import 'package:meta/meta.dart';

import '../../dcli.dart';
import '../shell/posix_shell.dart';

/// Used to locate and manipulate the dart pub cache
///
/// https://dart.dev/tools/pub/environment-variables
///
class PubCache {
  ///
  factory PubCache() => _self ??= PubCache._internal();

  PubCache._internal() {
    // first check if an environment variable exists.
    // The PUB_CACHE env var allows a user to over-ride
    // the standard location of the pub cache.
    final pubCacheEnv = env[envVarPubCache];

    String? dir;

    /// determine pubCacheDir
    if (pubCacheEnv != null) {
      dir = pubCacheEnv;
    }
    if (Settings().isWindows) {
      dir ??= join('Pub', 'Cache');
      // doco says this is AppData but some installers seem to use LocalAppData
      _pubCachePath = truepath(join(env['AppData']!, dir));
      if (!exists(_pubCachePath)) {
        _pubCachePath = truepath(join(env['LocalAppData']!, dir));
      }
    } else {
      dir ??= '.pub-cache';

      // determine pub-cache path
      if (Shell.current.isSudo) {
        /// I'm really not certain about this.
        /// The logic is that if we are running under sudo then the pub-cache
        /// we are using actually belongs to the original users so we
        /// we get that user's home directory and pub cache.
        final home = (Shell.current as PosixShell).loggedInUsersHome;
        _pubCachePath = truepath(join(home, dir));
      } else {
        _pubCachePath = truepath(join(env['HOME']!, dir));
      }
    }

    _pubCacheDir = dir;

    Settings().verbose('pub-cache found in=$_pubCachePath');

    // determine pub-cache/bin
    _pubCacheBinPath = truepath(join(_pubCachePath, 'bin'));
  }

  /// The name of the environment variable that can be
  /// set to change the location of the .pub-cache directory.
  /// You should change this path by calling [pathTo].
  static const String envVarPubCache = 'PUB_CACHE';
  late String _pubCachePath;

  static PubCache? _self;

  /// The name of the pub cache directory (e.g. .pub-cache)
  late String _pubCacheDir;

  late String _pubCacheBinPath;

  /// The fully qualified path to the pub cache.
  ///
  /// Dart allows the user to modify the location of
  /// the .pub-cache by setting the environment var
  /// PUB_CACHE.
  ///
  /// This method processes PUB_CACHE if it exists.
  String get pathTo => _pubCachePath;

  /// Updates pathTo, pathToBin and the PUB_CACHE environment variable
  /// which will cause pub get (and friends) to look to this
  /// alternate path.
  ///
  /// This will only affect this script and any child processes spawned from
  /// this script.
  set pathTo(String pathToPubCache) {
    env[envVarPubCache] = pathToPubCache;
    _pubCachePath = pathToPubCache;
    _pubCacheBinPath = truepath(join(_pubCachePath, 'bin'));
  }

  /// The fully qualified path to the pub cache's bin directory
  /// where executables from installed packages are stored.
  String get pathToBin => _pubCacheBinPath;

  /// Returns the directory name of the pub cache.
  ///
  /// e.g.
  /// .pub-cache
  ///
  /// Dart allows the user to modify the location of
  /// the .pub-cache by setting the environment var
  /// PUB_CACHE.
  ///
  /// This method processes PUB_CACHE if it exists.
  String? get cacheDir => _pubCacheDir;

  /// only to be used for unit tests.
  /// It resets the paths so that they can pick
  /// up changes to HOME made by the unit tests.
  @visibleForTesting
  static void reset() {
    _self = null;
  }
}
