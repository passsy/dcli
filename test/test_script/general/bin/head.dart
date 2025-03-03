#! /usr/bin/env dcli

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:args/args.dart';

/// Used by unit tests as a cross platform version of cat
void main(List<String> args) {
  final parser = ArgParser()..addOption('n', abbr: 'n', defaultsTo: '10');

  final results = parser.parse(args);

  final lines = int.tryParse(results['n'] as String);
  if (lines == null) {
    printerr("Argument passed to -n must ge an integer. Found ${results['n']}");
    exit(1);
  }

  final paths = results.rest;

  if (paths.isEmpty) {
    printerr('Expected at least one file');
    exit(1);
  }
  Settings().setVerbose(enabled: true);

  for (final path in paths) {
    if (Settings().isWindows) {
      final files = find(path).toList();
      if (files.isEmpty) {
        printerr(
            "head: cannot open '$path' for reading: No such file or directory");
        exit(1);
      } else {
        for (final file in files) {
          head(file, lines);
        }
      }
    } else {
      if (!exists(path)) {
        printerr(
            "head: cannot open '$path' for reading: No such file or directory");
      } else {
        head(path, lines);
      }
    }
  }
}
