import 'dart:io';

import 'package:csv/csv.dart';
import 'package:meta/meta.dart';
import '../../dcli.dart';
import 'runnable_process.dart';

///
/// EXPERIMENTAL
///
/// This class is likely to change/replaced.
@visibleForTesting
class ProcessHelper {
  ///
  factory ProcessHelper() => _self;

  ProcessHelper._internal();

  static final ProcessHelper _self = ProcessHelper._internal();

  /// returns the name of the process for the given pid.
  String? getProcessName(int? pid) {
    if (Settings().isWindows) {
      return _getWindowsProcessName(pid);
    } else {
      return _getLinuxProcessName(pid);
    }
  }

  /// Gest the process name for the given pid
  ///
  /// Throws an RunException exception if the name can't
  /// be obtained.
  String? _getLinuxProcessName(int? lpid) {
    String? line;
    var processName = 'unknown';

    try {
      line = 'ps -q $lpid -o comm='.firstLine;
      Settings().verbose('ps: $line');
    } on RunException catch (e) {
      /// the pid is no longer running
      if (e.exitCode == 1) {
        Settings().verbose('pid $lpid is no longer running');
      }
    } on ProcessException {
      // ps not supported on current OS
    }
    if (line != null) {
      processName = line.trim();
    }

    Settings().verbose('_getLinuxProcessName $lpid $processName');

    return line;
  }

  /// Get the PID of the parent
  /// Returns -1 if a parent can't be obtained.
  int? getParentPID(int? childPid) {
    if (Settings().isWindows) {
      return _windowsGetParentPid(childPid);
    } else {
      return _linuxGetParentPID(childPid);
    }
  }

  /// returns true if the given [pid] is still running.
  bool isRunning(int? pid) {
    if (Settings().isWindows) {
      return _windowsIsrunning(pid);
    } else {
      return _linuxisRunning(pid);
    }
  }

  /// returns the pid of the parent pid or -1 if the
  /// child doesn't have a parent.
  int _linuxGetParentPID(int? childPid) {
    String? line;
    try {
      // ignore: flutter_style_todos
      /// TODO: find a way to get the parent of a given pid
      /// not the current pid.
      /// The following will work on SOME linux platforms.
      /// https://gist.github.com/fclairamb/a16a4237c46440bdb172
      // if (isPosixSupported) {
      //   line = '${getppid()}';
      // } else {
      line = 'ps -p $childPid -o ppid='.firstLine;
      Settings().verbose('ps: $line');
//      }
    } on ProcessException {
      // ps not supported on current OS
      line = '-1';
    }
    return int.tryParse(line!.trim()) ?? -1;
  }

  /// returns the pid of the parent pid of -1 if the
  /// child doesn't have a parent.
  int? _windowsGetParentPid(int? childPid) {
    final parents = _windowsParentProcessList();

    for (final parent in parents) {
      if (parent.processPid == childPid) {
        return parent.parentPid;
      }
    }
    return -1;
  }

  List<_WindowsParentProcess> _windowsParentProcessList() {
    final parents = <_WindowsParentProcess>[];

    final processes =
        'wmic process get processid,parentprocessid,executablepath'
            .toList(skipLines: 1);

    for (var process in processes) {
      // Settings().verbose('wmic: $process');
      process = process.trim();
      process = process.replaceAll(RegExp(r'\s+'), ' ');

      final parts = process.split(' ');
      if (parts.length < 3) {
        // a lot of the lines have blank process ames
        continue;
      }

      // we have to deal with files that contain spaces in their name.
      final exe = parts.sublist(0, parts.length - 3).join(' ');
      final parentPid = int.tryParse(parts[parts.length - 2]);
      final processPid = int.tryParse(parts[parts.length - 1]);

      final parent = _WindowsParentProcess()
        ..path = exe
        ..parentPid = parentPid
        ..processPid = processPid;
      parents.add(parent);
    }
    return parents;
  }

  bool _windowsIsrunning(int? lpid) {
    for (final details in _getWindowsProcesses()) {
      if (details.pid == lpid) {
        return true;
      }
    }
    return false;
  }

  bool _linuxisRunning(int? lpid) {
    var isRunning = false;

    String? line;

    try {
      /// https://stackoverflow.com/questions/9152979/check-if-process-exists-given-its-pid
      // if (isPosixSupported) {
      //   kill(0);
      // }
      line = 'ps -q $lpid -o comm='.firstLine;
      Settings().verbose('ps: $line');
      if (line != null) {
        isRunning = true;
      }
    } on RunException {
      // ps not supported on current OS
      // we have to assume the process is running
    }

    return isRunning;
  }

  /// completely untested as I don't have a windows box.
  String? _getWindowsProcessName(int? lpid) {
    String? pidName;
    for (final details in _getWindowsProcesses()) {
      if (lpid == details.pid) {
        pidName = details.processName;
        break;
      }
    }
    Settings().verbose('_getWindowsProcessName $lpid $pidName');
    return pidName;
  }

  List<_PIDDetails> _getWindowsProcesses() {
    final pids = <_PIDDetails>[];

    // example:
    // "wininit.exe","584","Services","0","5,248 K"
    final tasks = 'tasklist /fo csv /nh'.toList();

    final lines = const CsvToListConverter().convert(tasks.join('\r\n'));
    for (final line in lines) {
      //Settings().verbose('tasklist: $line');
      final details = _PIDDetails()
        ..processName = line[0] as String?
        ..pid = int.tryParse(line[1] as String);
      // Settings().verbose('${details.processName} ${details.pid}');

      final memparts = (line[4] as String).split(' ');
      details.memory = memparts[0];
      // details.memory can contain 'N/A' in which case their is no units.
      if (memparts.length == 2) {
        details.memoryUnits = memparts[1];
      }

      pids.add(details);
    }

    return pids;
  }
}

class _PIDDetails {
  int? pid;
  String? processName;
  String? memory;
  String? memoryUnits;
}

class _WindowsParentProcess {
  String? path;
  int? parentPid;
  int? processPid;
}
