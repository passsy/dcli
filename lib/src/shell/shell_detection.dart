import 'dart:io';

import '../../dcli.dart';
import 'ash_shell.dart';
import 'bash_shell.dart';
import 'cmd_shell.dart';
import 'dash_shell.dart';
import 'fish_shell.dart';
import 'power_shell.dart';
import 'sh_shell.dart';
import 'shell_mixin.dart';
import 'unknown_shell.dart';
import 'zsh_shell.dart';

/// The project:
/// https://github.com/sarugaku/shellingham
///
/// is a useful reference on shell detection.

///
/// Provides some conveinence funtions to get access to
/// details about the system shell (e.g. bash) that we were run from.
///
/// Note: when you start up dcli from the cli there are three processes
/// involved:
///
/// cli - the cli you started dcli from. This is the shell we will return
/// sh - the shebang (#!) spawns an 'sh' shell which dart is run under.
/// dart - the dart process
///
/// This class is considered EXPERIMENTAL and is likely to change.
class ShellDetection {
  /// obtain a singleton instance of Shell.
  factory ShellDetection() => _shell;

  ShellDetection._internal();

  static final ShellDetection _shell = ShellDetection._internal();

  final _shells = <String, Shell Function(int? pid)>{
    AshShell.shellName: (pid) => AshShell.withPid(pid),
    CmdShell.shellName: (pid) => CmdShell.withPid(pid),
    DashShell.shellName: (pid) => DashShell.withPid(pid),
    BashShell.shellName: (pid) => BashShell.withPid(pid),
    PowerShell.shellName: (pid) => PowerShell.withPid(pid),
    ShShell.shellName: (pid) => ShShell.withPid(pid),
    ZshShell.shellName: (pid) => ZshShell.withPid(pid),
    FishShell.shellName: (pid) => FishShell.withPid(pid),
  };

  /// Attempts to identify the shell that
  /// DCli was run under.
  /// Ignores the 'sh' instances used by #! to start
  /// a DCli script.
  ///
  /// If we can't find a known shell we will return
  /// [UnknownShell].
  /// If the 'sh' instance created by #! is the only
  /// known shell we detect then we will return that
  /// shell [ShShell].
  ///
  /// Currently this isn't very reliable.
  Shell identifyShell() {
    /// on posix systems this MAY give us the login shell name.
    final _loginShell = ShellMixin.loginShell();
    if (_loginShell != null) {
      return _shellByName(_loginShell, -1);
    } else {
      return _searchProcessTree();
    }
  }

  Shell _searchProcessTree() {
    Shell? firstShell;
    int? firstPid;
    Shell? shell;
    int? childPID = pid;

    var firstPass = true;
    while (shell == null) {
      final possiblePid = ProcessHelper().getParentPID(childPID);

      /// Check if we ran into the root process or we
      ///  couldn't get the parent pid.
      if (possiblePid == 0 || possiblePid == -1) {
        break;
      }
      var processName = ProcessHelper().getProcessName(possiblePid);
      if (processName != null) {
        processName = processName.toLowerCase();
        Settings().verbose('found: $possiblePid $processName');
        shell = _shellByName(processName, possiblePid);
      } else {
        Settings()
            .verbose('possiblePID: $possiblePid Unable to obtain process name');
        shell = UnknownShell.withPid(possiblePid, processName: 'unknown');
      }

      if (firstPass) {
        firstPass = false;

        /// there may actually be no shell in which
        /// case the firstShell will contain the parent process
        /// and we will return UnknownShell with the parent processes
        /// id
        firstShell = shell;
        firstPid = possiblePid;

        /// If started by #! the parent willl be an 'sh' shell
        ///  which we need to ignore.
        if (shell.name == ShShell.shellName) {
          /// just in case we find no other shells we will return
          /// the sh shell because in theory we can actually be run
          /// from an sh shell.

          shell = null;
        }
      }
      if (shell != null && shell.name == UnknownShell.shellName) {
        shell = null;
      }

      childPID = possiblePid;
    }

    /// If we didn't find a shell then use firstShell.
    shell ??= firstShell;
    childPID ??= firstPid;

    /// if things are really sad.
    shell ??= UnknownShell.withPid(childPID);
    Settings().verbose(blue('Identified shell: ${shell.name}'));
    return shell;
  }

  /// Returns the shell with the name that matches [processName]
  /// If there is no match then [UnknownShell] is returned.
  Shell _shellByName(String processName, int? pid) {
    Shell? shell;

    final finalprocessName = processName.toLowerCase();

    if (_shells.containsKey(finalprocessName)) {
      shell = _shells[finalprocessName]!.call(pid);
    }

    return shell ??= UnknownShell.withPid(pid, processName: finalprocessName);
  }
}
