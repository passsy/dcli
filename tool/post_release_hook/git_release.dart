#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:settings_yaml/settings_yaml.dart';

void main(List<String> args) {
  final project = DartProject.current;

  final pathToSettings = join(
      project.pathToProjectRoot, 'tool', 'post_release_hook', '.settings.yaml');
  final settings = SettingsYaml.load(pathToSettings: pathToSettings);
  final username = settings['username'] as String?;
  final personalAccessToken = settings['personalAccessToken'] as String?;
  final owner = settings['owner'] as String?;
  final repository = settings['repository'] as String?;

  'github_release -u $username --apiToken $personalAccessToken --owner $owner '
          '--repository $repository'
      .start(workingDirectory: Script.current.pathToProjectRoot);
}
