import 'dart:io';
import 'package:pty/pty.dart';

void main() async {
  print('Starting simple shell test...');
  
  final pty = PseudoTerminal.start('sh', []);
  
  print('PTY started');
  
  // Listen to output
  pty.out.listen((data) {
    print('OUT: $data');
  });
  
  // Give it a moment
  await Future.delayed(Duration(milliseconds: 500));
  
  print('Terminating PTY...');
  pty.kill();
  
  print('Waiting for exit code...');
  final code = await pty.exitCode.timeout(
    Duration(seconds: 5),
    onTimeout: () {
      print('TIMEOUT waiting for exit!');
      return -999;
    },
  );
  
  print('Exit code: $code');
  exit(0);
}
