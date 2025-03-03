import 'dart:io';

/// Helper class to assist in printing text to the console with a color.
///
/// Use one of the color functions instead of this class.
///
/// See AnsiColor
///     [Terminal]
///  ...
class Ansi {
  /// Factory ctor
  factory Ansi() => _self;

  const Ansi._internal();

  static const _self = Ansi._internal();
  static bool? _emitAnsi;

  /// returns true of the terminal supports ansi escape characters.
  static bool get isSupported => _emitAnsi ??= stdin.supportsAnsiEscapes;

  /// You can set [isSupported] to
  /// override the detected ansi settings.
  /// Dart doesn't do a great job of correctly detecting
  /// ansi support so this give a way to override it.
  /// If [isSupported] is true then escape charaters are emmitted
  /// If [isSupported] is false escape characters are not emmited
  /// By default the detected setting is used.
  /// After setting emitAnsi you can reset back to the
  /// default detected by calling [resetEmitAnsi].
  static set isSupported(bool emit) => _emitAnsi = emit;

  /// If you have called [isSupported] then calling
  /// [resetEmitAnsi]  will reset the emit
  /// setting to the default detected.
  static void get resetEmitAnsi => _emitAnsi = null;

  /// ANSI Control Sequence Introducer, signals the terminal for new settings.
  static const esc = '\x1b[';
  // static const esc = '\u001b[';
}
