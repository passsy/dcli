import '../../dcli.dart';

/// [truepath] creates an absolute and canonicalize path.
///
/// True path provides a safe and consistent manner for
/// manipulating, accessing and displaying paths.
///
/// Works like [join] in that it concatenates a set of directories
/// into a path.
/// [truepath] then goes on to create an absolute path which
/// is then canonicalize to remove any segments (.. or .).
///
String truepath(String part1,
        [String? part2,
        String? part3,
        String? part4,
        String? part5,
        String? part6,
        String? part7]) =>
    canonicalize(absolute(part1, part2, part3, part4, part5, part6, part7));

/// Removes the users home directory from a path replacing it with ~
String privatePath(String part1,
        [String? part2,
        String? part3,
        String? part4,
        String? part5,
        String? part6,
        String? part7]) =>
    truepath(part1, part2, part3, part4, part5, part6, part7)
        .replaceAll(HOME, '/<HOME>');

/// returns the root path this is '/' or '\\' depending on platform.
String get rootPath => separator;
