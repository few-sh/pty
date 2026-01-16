import 'dart:io';
import 'package:pty/pty.dart';

void main() async {
  print('Starting test...');
  
  final pty = PseudoTerminal.start('sh', ['-c', 'exit 42']);
  
  print('PTY started, reading output...');
  
  // Try to read any output
  pty.out.listen((data) {
    print('Output: $data');
  });
  
  print('Waiting for exit code...');
  
  final code = await pty.exitCode.timeout(
    Duration(seconds: 5),
    onTimeout: () {
      print('TIMEOUT!');
      return -1;
    },
  );
  
  print('Exit code (raw): $code (hex: 0x${code.toRadixString(16)})');
  
  // Extract actual exit code from waitpid status
  // In Unix, if WIFEXITED(status), then WEXITSTATUS(status) = (status >> 8) & 0xFF
  final actualExitCode = (code >> 8) & 0xFF;
  print('Actual exit code: $actualExitCode');
  
  exit(actualExitCode == 42 ? 0 : 1);
}
