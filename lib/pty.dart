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
      // Add '-l' flag for interactive shell sessions to get login shell behavior.
      // Only do this for known shell executables and when no command flags are present.
      // This ensures proper environment setup (PATH, HOME, etc.) for interactive use.
      final isShell = _isShellExecutable(executable);
      final hasCommandFlag = arguments.any((arg) => 
        arg.startsWith('-c') || arg.startsWith('-s'));
      
      if (isShell && !hasCommandFlag && arguments.isEmpty) {
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

/// Check if the executable is a known shell that supports the -l flag
bool _isShellExecutable(String executable) {
  // Extract just the executable name (without path)
  // Note: This function is only called on Unix systems (not Windows),
  // so Unix-style path separators are appropriate here
  final name = executable.split('/').last;
  
  // Common shells that support -l flag for login shell behavior
  const shells = ['sh', 'bash', 'zsh', 'ksh', 'dash', 'ash', 'fish', 'tcsh', 'csh'];
  
  return shells.contains(name);
}
