library pty;

import 'dart:io';

import 'package:pty/src/impl/unix.dart';
import 'package:pty/src/impl/windows.dart';
import 'package:pty/src/pty.dart';
import 'package:pty/src/pty_core.dart';

export 'src/pty.dart';

abstract class PseudoTerminal {
  /// If [blocking] is [true], the PseudoTerminal starts in blocking mode
  /// (better suited for flutter release mode), otherwise in polling mode
  /// (better suited for flutter debug mode).
  static PseudoTerminal start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool blocking = false,
    bool ackProcessed = false,
    // bool includeParentEnvironment = true,
    // bool runInShell = false,
    // ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    late PtyCore core;

    if (Platform.isWindows) {
      core = PtyCoreWindows.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        blocking: blocking,
      );
    } else {
      // Add '-l' as argument for the shell to perform a login, but only if
      // this is an interactive shell (not running with -c, -s, or similar command flags)
      final hasCommandFlag = arguments.any((arg) => 
        arg == '-c' || arg == '-s' || arg.startsWith('-c') || arg.startsWith('-s'));
      
      if (!hasCommandFlag && arguments.isEmpty) {
        // Interactive shell - add '-l' for login shell behavior
        arguments = ['-l'];
      }

      core = PtyCoreUnix.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        blocking: blocking,
      );
    }

    late PseudoTerminal pty;
    if (blocking) {
      pty = BlockingPseudoTerminal(core, ackProcessed);
    } else {
      pty = PollingPseudoTerminal(core);
    }
    pty.init();
    return pty;
  }

  void init();
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);

  Future<int> get exitCode;

  // int get pid {
  //   return _core.pid;
  // }

  void write(String input);

  Stream<String> get out;

  void ackProcessed();

  void resize(int width, int height);
}
