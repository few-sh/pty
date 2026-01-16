import 'dart:io';

import 'package:pty/pty.dart';
import 'package:test/test.dart';

void main() {
  group('Basic PTY Operations', () {
    test('Can instantiate and terminate PseudoTerminal', () async {
      final pty = PseudoTerminal.start(_getShell(), []);
      await Future.delayed(Duration(milliseconds: 100));
      pty.kill(); // Default is SIGTERM
      final code = await pty.exitCode;
      expect(code, equals(143)); // SIGTERM = 128 + 15
    });

    test('Can send SIGTERM signal', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      await Future.delayed(Duration(milliseconds: 100));
      
      final terminated = pty.kill(ProcessSignal.sigterm);
      expect(terminated, isTrue);
      
      final code = await pty.exitCode;
      expect(code, equals(143)); // SIGTERM = 128 + 15
    });

    test('Can send SIGKILL signal', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      await Future.delayed(Duration(milliseconds: 100));
      
      final terminated = pty.kill(ProcessSignal.sigkill);
      expect(terminated, isTrue);
      
      final code = await pty.exitCode;
      expect(code, equals(137)); // SIGKILL = 128 + 9
    });

    test('Can resize PTY dimensions', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      
      // Should not throw
      expect(() => pty.resize(100, 50), returnsNormally);
      expect(() => pty.resize(80, 24), returnsNormally);
      expect(() => pty.resize(120, 40), returnsNormally);
      
      await Future.delayed(Duration(milliseconds: 50));
      pty.kill();
      await pty.exitCode;
    });
  });
}

String _getShell() {
  if (Platform.isWindows) {
    return 'cmd';
  }

  return 'sh';
}
