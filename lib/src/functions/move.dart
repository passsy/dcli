import 'dart:io';
import 'package:path/path.dart' as p;

import '../../dcli.dart';
import 'function.dart';

///
/// Moves the file [from] to the location [to].
///
/// ```dart
/// createDir('/tmp/folder');
/// move('/tmp/fred.txt', '/tmp/folder/tom.txt');
/// ```
/// [from] must be a file.
///
/// [to] may be a file or a path.
///
/// If [to] is a file then a rename occurs.
///
/// if [to] is a path then [from] is moved to the given path.
///
/// If the move fails for any reason a [MoveException] is thrown.
///
void move(String from, String to, {bool overwrite = false}) =>
    _Move().move(from, to, overwrite: overwrite);

class _Move extends DCliFunction {
  void move(String from, String to, {bool overwrite = false}) {
    Settings().verbose('move ${truepath(from)} -> ${truepath(to)}');

    var dest = to;

    if (isDirectory(to)) {
      dest = p.join(to, p.basename(from));
    }

    if (!overwrite && exists(dest)) {
      throw MoveException('The [to] path ${truepath(dest)} already exists.'
          ' Use overwrite:true ');
    }
    try {
      File(from).renameSync(dest);
    } on FileSystemException catch (e) {
      if (e.osError != null && e.osError!.errorCode == 18) {
        /// Invalid cross-device link
        /// We can't move files across a partition so
        /// do a copy/delete.
        copy(from, to, overwrite: overwrite);
        delete(from);
      } else {
        _improveError(e, from, to);
      }
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      _improveError(e, from, to);
    }
  }
}

/// We try to improve the OS error message, because its crap.
void _improveError(Object e, String from, String to) {
  if (!exists(from)) {
    throw MoveException(
        'The Move of ${truepath(from)} failed as it does not exist.');
  } else if (!exists(dirname(truepath(to)))) {
    throw MoveException(
        'The Move of ${truepath(from)} failed as the target directory '
        '${truepath(dirname(to))} does not exist.');
  } else {
    throw MoveException(
        'The Move of ${truepath(from)} to ${truepath(to)} failed. Error $e');
  }
}

/// Thrown when the [move] function encouters an error.
class MoveException extends FunctionException {
  /// Thrown when the [move] function encouters an error.
  MoveException(String reason) : super(reason);
}
