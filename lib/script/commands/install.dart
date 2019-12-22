import 'dart:io';

import 'package:dshell/dshell.dart';
import 'package:dshell/functions/which.dart';
import 'package:dshell/pubspec/global_dependancies.dart';
import 'package:dshell/script/command_line_runner.dart';
import 'package:dshell/settings.dart';
import 'package:dshell/util/ansi_color.dart';

import '../flags.dart';
import 'commands.dart';

class InstallCommand extends Command {
  static const String NAME = 'install';

  static const String pubCache = '.pub-cache/bin';

  InstallCommand() : super(NAME);

  @override
  int run(List<Flag> selectedFlags, List<String> subarguments) {
    var exitCode = 0;

    if (subarguments.isNotEmpty) {
      throw CommandLineException(
          "'dshell install' does not take any arguments. Found $subarguments");
    }

    print(red('Hang on a tick whilst we install dshell.'));
    print('');
    // Create the ~/.dshell root.
    if (!exists(Settings().dshellPath)) {
      print(blue('Creating ${Settings().dshellPath}'));
      createDir(Settings().dshellPath);
    } else {
      print('Found existing install at: ${Settings().dshellPath}');
    }
    print('');

    // Create dependencies.yaml
    var blue2 = blue(
        'Creating ${Settings().dshellPath}/dependencies.yaml with default packages.');
    print(blue2);
    GlobalDependancies.createDefault();

    print('Default packages are:');
    for (var dep in GlobalDependancies.defaultDependencies) {
      print('  ${dep.name}:${dep.version}');
    }
    print('');
    print(red(
        'Edit dependencies.yaml to add/remove/update your default dependencies.'));

    /// create the template directory.
    if (!exists(Settings().templatePath)) {
      print('');
      print(
          blue('Creating Template directory in: ${Settings().templatePath}.'));
      createDir(Settings().templatePath);
    }

    /// create the cache directory.
    if (!exists(Settings().cachePath)) {
      print('');
      print(blue('Creating Cache directory in: ${Settings().cachePath}.'));
      createDir(Settings().cachePath);
    }

    print('');

    // print OS version.
    // print('Platform.version ${Platform.version}');

    var dshellLocation = which('dshell').toList();
    // check if dshell is on the path
    if (dshellLocation.isEmpty) {
      print('');
      print(red('ERROR: dshell was not found on your path!'));
      print('Try to resolve the problem and then run dshell install again.');
      print('dshell is normally located in ~/$pubCache');

      if (!env('path').contains(join(env('home'), pubCache))) {
        print('Your path does not contain ~/$pubCache');
      }
      exit(1);
    } else {
      print('dshell found in : ${dshellLocation[0]}');
    }
    print('');

    // print('Copying dshell (${Platform.executable}) to /usr/bin/dshell');
    // copy(Platform.executable, '/usr/bin/dshell');

    print(red('dshell installation complete.'));
    print('');
    print(red('Create your first dshell script using:'));
    print(blue('  dshell create <scriptname>.dart'));
    print('');
    print(blue('  Run your script by typing:'));
    print(blue('  ./<scriptname>.dart'));

    return exitCode;
  }

  @override
  String description() => """There are two forms of dshell isntall:
      Running 'dshell install' completes the installation of dshell.
      
      EXPERIMENTAL:
      Running 'dshell install <script> compiles the given script to a native executable and installs
         the script to your path. Only required if you want super fast execution.
         """;

  @override
  String usage() => 'Install | install <script path.dart>';
}
