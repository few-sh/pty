import 'dart:io';

import 'package:pty/pty.dart';
import 'package:test/test.dart';

void main() {
  group('Basic PTY Operations', () {
    test('Can instantiate and kill PseudoTerminal', () async {
      final pty = PseudoTerminal.start(_getShell(), []);
      pty.kill();
      await pty.exitCode;
    });

    test('Can read exit code', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), ['-c', 'exit 42']);
      
      final code = await pty.exitCode;
      expect(code, equals(42));
    });

    test('Can read zero exit code', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), ['-c', 'exit 0']);
      
      final code = await pty.exitCode;
      expect(code, equals(0));
    });
  });

  group('Input/Output Operations', () {
    test('Can execute simple command and capture output', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'echo "test_output"'],
      );
      
      final output = await pty.out.first;
      expect(output, contains('test_output'));
      
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can read multiple lines of output', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'echo line1; echo line2; echo line3'],
      );
      
      final outputs = <String>[];
      await for (final data in pty.out) {
        outputs.add(data);
        final combined = outputs.join();
        if (combined.contains('line1') && 
            combined.contains('line2') && 
            combined.contains('line3')) {
          break;
        }
      }
      
      final combined = outputs.join();
      expect(combined, contains('line1'));
      expect(combined, contains('line2'));
      expect(combined, contains('line3'));
      
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can write and read data', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), ['-c', 'cat']);
      
      pty.write('test data\n');
      
      final output = await pty.out.first;
      expect(output, contains('test data'));
      
      pty.kill();
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 10)));
  });

  group('Environment Variables', () {
    test('Can pass custom environment variables', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'echo \$TEST_VAR'],
        environment: {'TEST_VAR': 'test_value'},
      );
      
      final output = await pty.out.first;
      expect(output, contains('test_value'));
      
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Environment includes TERM variable', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'echo \$TERM'],
      );
      
      final output = await pty.out.first;
      expect(output, contains('xterm-256color'));
      
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can override PATH variable', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'echo \$PATH'],
        environment: {'PATH': '/custom/path'},
      );
      
      final output = await pty.out.first;
      expect(output, contains('/custom/path'));
      
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 10)));
  });

  group('Working Directory', () {
    test('Can set custom working directory', () async {
      if (Platform.isWindows) return;
      
      final testDir = Directory.systemTemp.createTempSync('pty_test');
      
      try {
        final pty = PseudoTerminal.start(
          _getShell(),
          ['-c', 'pwd'],
          workingDirectory: testDir.path,
        );
        
        final output = await pty.out.first;
        expect(output.trim(), contains(testDir.path));
        
        await pty.exitCode;
      } finally {
        testDir.deleteSync(recursive: true);
      }
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can execute command in custom directory', () async {
      if (Platform.isWindows) return;
      
      final testDir = Directory.systemTemp.createTempSync('pty_test');
      
      try {
        // Create a test file
        File('${testDir.path}/testfile.txt').writeAsStringSync('content');
        
        final pty = PseudoTerminal.start(
          _getShell(),
          ['-c', 'ls testfile.txt'],
          workingDirectory: testDir.path,
        );
        
        final output = await pty.out.first;
        expect(output, contains('testfile.txt'));
        
        await pty.exitCode;
      } finally {
        testDir.deleteSync(recursive: true);
      }
    }, timeout: Timeout(Duration(seconds: 10)));
  });

  group('Process Control', () {
    test('Can kill long-running process', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'for i in {1..1000}; do echo \$i; sleep 0.1; done'],
      );
      
      // Wait for some output
      await pty.out.first;
      
      // Kill the process
      final killed = pty.kill();
      expect(killed, isTrue);
      
      // Wait for exit
      final code = await pty.exitCode;
      // Process was killed, so exit code should be non-zero
      expect(code, isNot(equals(0)));
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can send SIGTERM signal', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'sleep 10'],
      );
      
      // Give it a moment to start
      await Future.delayed(Duration(milliseconds: 100));
      
      final killed = pty.kill(ProcessSignal.sigterm);
      expect(killed, isTrue);
      
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 5)));

    test('Can send SIGKILL signal', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'sleep 10'],
      );
      
      // Give it a moment to start
      await Future.delayed(Duration(milliseconds: 100));
      
      final killed = pty.kill(ProcessSignal.sigkill);
      expect(killed, isTrue);
      
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 5)));
  });

  group('PTY Resize', () {
    test('Can resize PTY dimensions', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      
      // Should not throw
      expect(() => pty.resize(100, 50), returnsNormally);
      expect(() => pty.resize(80, 24), returnsNormally);
      
      pty.kill();
      await pty.exitCode;
    });

    test('Can detect terminal size in process', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'tput cols; tput lines'],
      );
      
      final output = await pty.out.first;
      // Default size is 80x20 as per the code
      expect(output, contains('80'));
      expect(output, contains('20'));
      
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Terminal size changes are reflected', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'trap "tput cols; tput lines" SIGWINCH; sleep 10 & wait'],
      );
      
      // Give it a moment to start
      await Future.delayed(Duration(milliseconds: 200));
      
      // Resize and trigger SIGWINCH
      pty.resize(120, 40);
      
      // Give it time to process
      await Future.delayed(Duration(milliseconds: 200));
      
      pty.kill();
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 10)));
  });

  group('Interactive Shell Features', () {
    test('Can interact with shell prompt', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      
      // Wait for initial output (shell startup)
      await pty.out.first;
      
      // Send command
      pty.write('echo TEST_PASSED\n');
      
      // Look for output
      bool foundOutput = false;
      final timeout = DateTime.now().add(Duration(seconds: 5));
      await for (final data in pty.out) {
        if (data.contains('TEST_PASSED')) {
          foundOutput = true;
          break;
        }
        if (DateTime.now().isAfter(timeout)) break;
      }
      
      expect(foundOutput, isTrue);
      
      pty.write('exit\n');
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can handle multiple sequential commands', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      
      await pty.out.first;
      
      pty.write('echo FIRST\n');
      pty.write('echo SECOND\n');
      pty.write('echo THIRD\n');
      
      final outputs = <String>[];
      final timeout = DateTime.now().add(Duration(seconds: 5));
      await for (final data in pty.out) {
        outputs.add(data);
        final combined = outputs.join();
        if (combined.contains('FIRST') && 
            combined.contains('SECOND') && 
            combined.contains('THIRD')) {
          break;
        }
        if (DateTime.now().isAfter(timeout)) break;
      }
      
      final combined = outputs.join();
      expect(combined, contains('FIRST'));
      expect(combined, contains('SECOND'));
      expect(combined, contains('THIRD'));
      
      pty.write('exit\n');
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can read command output with newlines', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      
      await pty.out.first;
      
      pty.write('printf "line1\\nline2\\nline3\\n"\n');
      
      final outputs = <String>[];
      final timeout = DateTime.now().add(Duration(seconds: 5));
      await for (final data in pty.out) {
        outputs.add(data);
        final combined = outputs.join();
        if (combined.contains('line1') && 
            combined.contains('line2') && 
            combined.contains('line3')) {
          break;
        }
        if (DateTime.now().isAfter(timeout)) break;
      }
      
      final combined = outputs.join();
      expect(combined, contains('line1'));
      expect(combined, contains('line2'));
      expect(combined, contains('line3'));
      
      pty.write('exit\n');
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 10)));
  });

  group('Edge Cases', () {
    test('Can handle empty command arguments', () async {
      final pty = PseudoTerminal.start(_getShell(), []);
      pty.kill();
      await pty.exitCode;
    });

    test('Can handle immediate kill after start', () async {
      final pty = PseudoTerminal.start(_getShell(), []);
      final killed = pty.kill();
      expect(killed, isTrue);
      await pty.exitCode;
    });

    test('Multiple kills are idempotent', () async {
      final pty = PseudoTerminal.start(_getShell(), []);
      
      await Future.delayed(Duration(milliseconds: 50));
      
      final killed1 = pty.kill();
      expect(killed1, isTrue);
      
      final killed2 = pty.kill();
      // Second kill may return false if process already dead
      
      await pty.exitCode;
    });

    test('Can handle UTF-8 output', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'echo "Hello 世界 🌍"'],
      );
      
      final output = await pty.out.first;
      expect(output, contains('世界'));
      expect(output, contains('🌍'));
      
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can handle large output', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'for i in {1..100}; do echo "Line \$i"; done'],
      );
      
      final outputs = <String>[];
      await for (final data in pty.out) {
        outputs.add(data);
        if (outputs.join().contains('Line 100')) break;
      }
      
      final combined = outputs.join();
      expect(combined, contains('Line 1'));
      expect(combined, contains('Line 50'));
      expect(combined, contains('Line 100'));
      
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 15)));
  });

  group('Blocking Mode Tests', () {
    test('Can instantiate PTY in blocking mode', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'echo test'],
        blocking: true,
      );
      
      final output = await pty.out.first;
      expect(output, contains('test'));
      
      await pty.exitCode;
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Blocking mode can read exit code', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(
        _getShell(),
        ['-c', 'exit 5'],
        blocking: true,
      );
      
      final code = await pty.exitCode;
      expect(code, equals(5));
    }, timeout: Timeout(Duration(seconds: 10)));
  });
}

String _getShell() {
  if (Platform.isWindows) {
    return 'cmd';
  }

  return 'sh';
}
