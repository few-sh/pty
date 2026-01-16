import 'dart:io';
import 'package:pty/pty.dart';

void main() async {
  print('Starting test with delay...');
  
  final pty = PseudoTerminal.start('sh', ['-c', 'sleep 0.2; exit 42']);
  
  print('PTY started, waiting for exit code...');
  
  final code = await pty.exitCode.timeout(
    Duration(seconds: 5),
    onTimeout: () {
      print('TIMEOUT!');
      return -1;
    },
  );
  
  print('Exit code: $code');
  exit(code == 42 ? 0 : 1);
}
