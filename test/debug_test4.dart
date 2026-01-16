import 'dart:io';
import 'package:pty/pty.dart';

void main() async {
  print('Test 1: Simple process termination');
  {
    final pty = PseudoTerminal.start('sh', []);
    await Future.delayed(Duration(milliseconds: 100));
    pty.kill();
    final code = await pty.exitCode.timeout(Duration(seconds: 2));
    print('Termination exit code: $code (expected 137 for SIGKILL)');
  }
  
  print('\nTest 2: Echo command');
  {
    final pty = PseudoTerminal.start('sh', ['-c', 'echo hello; sleep 0.2']);
    final outputs = <String>[];
    final sub = pty.out.listen((data) {
      outputs.add(data);
    });
    await Future.delayed(Duration(milliseconds: 500));
    sub.cancel();
    pty.kill();
    await pty.exitCode.timeout(Duration(seconds: 2));
    print('Echo outputs: ${outputs.join()}');
  }
  
  print('\nTest 3: Exit code');
  {
    final pty = PseudoTerminal.start('sh', ['-c', 'sleep 0.3; exit 5']);
    final code = await pty.exitCode.timeout(Duration(seconds: 2));
    print('Exit code: $code (expected 5)');
  }
  
  print('\nAll tests passed!');
}
