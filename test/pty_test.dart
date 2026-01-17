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

  group('UTF-8 and Unicode Support', () {
    test('Can handle basic UTF-8 output', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      await Future.delayed(Duration(milliseconds: 200));
      
      // Test various Unicode categories
      pty.write('echo "Test: café 世界 🌍"\n');
      
      final outputs = <String>[];
      final timeout = DateTime.now().add(Duration(seconds: 3));
      await for (final data in pty.out) {
        outputs.add(data);
        final combined = outputs.join();
        if (combined.contains('café') && 
            combined.contains('世界') && 
            combined.contains('🌍')) {
          break;
        }
        if (DateTime.now().isAfter(timeout)) break;
      }
      
      final combined = outputs.join();
      expect(combined, contains('café'));
      expect(combined, contains('世界'));
      expect(combined, contains('🌍'));
      
      pty.write('exit\n');
      await pty.exitCode.timeout(Duration(seconds: 2));
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can handle emoji and special Unicode', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      await Future.delayed(Duration(milliseconds: 200));
      
      pty.write('echo "😀🎉🌟❤️🚀"\n');
      
      final outputs = <String>[];
      final timeout = DateTime.now().add(Duration(seconds: 3));
      await for (final data in pty.out) {
        outputs.add(data);
        if (outputs.join().contains('🎉')) {
          break;
        }
        if (DateTime.now().isAfter(timeout)) break;
      }
      
      final combined = outputs.join();
      expect(combined, contains('😀'));
      expect(combined, contains('🚀'));
      
      pty.write('exit\n');
      await pty.exitCode.timeout(Duration(seconds: 2));
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can handle RTL text (Arabic)', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      await Future.delayed(Duration(milliseconds: 200));
      
      pty.write('echo "مرحبا"\n');
      
      final outputs = <String>[];
      final timeout = DateTime.now().add(Duration(seconds: 3));
      await for (final data in pty.out) {
        outputs.add(data);
        if (outputs.join().contains('مرحبا')) {
          break;
        }
        if (DateTime.now().isAfter(timeout)) break;
      }
      
      final combined = outputs.join();
      expect(combined, contains('مرحبا'));
      
      pty.write('exit\n');
      await pty.exitCode.timeout(Duration(seconds: 2));
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can handle mixed Unicode in single output', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      await Future.delayed(Duration(milliseconds: 200));
      
      pty.write('echo "ASCII-café-世界-😀-مرحبا"\n');
      
      final outputs = <String>[];
      final timeout = DateTime.now().add(Duration(seconds: 3));
      await for (final data in pty.out) {
        outputs.add(data);
        final combined = outputs.join();
        if (combined.contains('ASCII') && 
            combined.contains('café') && 
            combined.contains('世界')) {
          break;
        }
        if (DateTime.now().isAfter(timeout)) break;
      }
      
      final combined = outputs.join();
      expect(combined, contains('ASCII'));
      expect(combined, contains('café'));
      expect(combined, contains('世界'));
      expect(combined, contains('😀'));
      
      pty.write('exit\n');
      await pty.exitCode.timeout(Duration(seconds: 2));
    }, timeout: Timeout(Duration(seconds: 10)));
  });

  group('Special Terminal Characters', () {
    test('Can handle ANSI escape sequences', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      await Future.delayed(Duration(milliseconds: 200));
      
      // ANSI color codes
      pty.write('echo -e "\\033[31mRed\\033[0m"\n');
      
      final outputs = <String>[];
      final timeout = DateTime.now().add(Duration(seconds: 3));
      await for (final data in pty.out) {
        outputs.add(data);
        if (outputs.join().contains('Red')) {
          break;
        }
        if (DateTime.now().isAfter(timeout)) break;
      }
      
      final combined = outputs.join();
      expect(combined, contains('Red'));
      // Should also contain ANSI escape sequences
      expect(combined, contains('\x1b[') || contains('[31m'));
      
      pty.write('exit\n');
      await pty.exitCode.timeout(Duration(seconds: 2));
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can handle tab characters', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      await Future.delayed(Duration(milliseconds: 200));
      
      pty.write('printf "Col1\\tCol2\\tCol3\\n"\n');
      
      final outputs = <String>[];
      final timeout = DateTime.now().add(Duration(seconds: 3));
      await for (final data in pty.out) {
        outputs.add(data);
        if (outputs.join().contains('Col1')) {
          break;
        }
        if (DateTime.now().isAfter(timeout)) break;
      }
      
      final combined = outputs.join();
      expect(combined, contains('Col1'));
      expect(combined, contains('Col2'));
      
      pty.write('exit\n');
      await pty.exitCode.timeout(Duration(seconds: 2));
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can handle line breaks and carriage returns', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      await Future.delayed(Duration(milliseconds: 200));
      
      pty.write('printf "Line1\\nLine2\\n"\n');
      
      final outputs = <String>[];
      final timeout = DateTime.now().add(Duration(seconds: 3));
      await for (final data in pty.out) {
        outputs.add(data);
        final combined = outputs.join();
        if (combined.contains('Line1') && combined.contains('Line2')) {
          break;
        }
        if (DateTime.now().isAfter(timeout)) break;
      }
      
      final combined = outputs.join();
      expect(combined, contains('Line1'));
      expect(combined, contains('Line2'));
      
      pty.write('exit\n');
      await pty.exitCode.timeout(Duration(seconds: 2));
    }, timeout: Timeout(Duration(seconds: 10)));
  });

  group('Edge Cases', () {
    test('Can handle long output strings', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      await Future.delayed(Duration(milliseconds: 200));
      
      // Generate a long string using shell builtins for portability
      pty.write('for i in {1..500}; do printf "A"; done; echo\n');
      
      final outputs = <String>[];
      final timeout = DateTime.now().add(Duration(seconds: 3));
      await for (final data in pty.out) {
        outputs.add(data);
        if (outputs.join().length > 400) {
          break;
        }
        if (DateTime.now().isAfter(timeout)) break;
      }
      
      final combined = outputs.join();
      // Should contain many A's
      expect(combined.split('').where((c) => c == 'A').length, greaterThan(400));
      
      pty.write('exit\n');
      await pty.exitCode.timeout(Duration(seconds: 2));
    }, timeout: Timeout(Duration(seconds: 10)));

    test('Can handle rapid output', () async {
      if (Platform.isWindows) return;
      
      final pty = PseudoTerminal.start(_getShell(), []);
      await Future.delayed(Duration(milliseconds: 200));
      
      // Multiple quick outputs
      pty.write('for i in {1..20}; do echo "Line \$i"; done\n');
      
      final outputs = <String>[];
      final timeout = DateTime.now().add(Duration(seconds: 3));
      await for (final data in pty.out) {
        outputs.add(data);
        final combined = outputs.join();
        if (combined.contains('Line 20')) {
          break;
        }
        if (DateTime.now().isAfter(timeout)) break;
      }
      
      final combined = outputs.join();
      expect(combined, contains('Line 1'));
      expect(combined, contains('Line 10'));
      expect(combined, contains('Line 20'));
      
      pty.write('exit\n');
      await pty.exitCode.timeout(Duration(seconds: 2));
    }, timeout: Timeout(Duration(seconds: 10)));
  });
}

String _getShell() {
  if (Platform.isWindows) {
    return 'cmd';
  }

  return 'sh';
}
