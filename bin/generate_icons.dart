// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  print('==================================================');
  print('EduConnect App Icon Generator (Release-Ready Polish)');
  print('==================================================');

  final sourceFile = File('assets/images/logo.png');
  if (!sourceFile.existsSync()) {
    print('[-] Error: Source logo file not found at assets/images/logo.png');
    exit(1);
  }

  final logoBytes = sourceFile.readAsBytesSync();
  print('[+] Successfully loaded brand logo (${(logoBytes.length / 1024).toStringAsFixed(2)} KB).');

  // 1. Android Launcher Icons paths
  final androidPaths = [
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
  ];

  print('\n[+] Overwriting Android Launcher Icons...');
  int androidCount = 0;
  for (final path in androidPaths) {
    final file = File(path);
    if (file.parent.existsSync()) {
      file.writeAsBytesSync(logoBytes);
      print('    -> Generated: $path');
      androidCount++;
    } else {
      print('    -> [Skipped] Directory does not exist: ${file.parent.path}');
    }
  }

  // 2. iOS Launcher Icons paths
  print('\n[+] Overwriting iOS Launcher Icons...');
  final iosDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  int iosCount = 0;
  if (iosDir.existsSync()) {
    final files = iosDir.listSync();
    for (final entity in files) {
      if (entity is File && entity.path.endsWith('.png')) {
        entity.writeAsBytesSync(logoBytes);
        print('    -> Overwrote iOS Icon: ${entity.path}');
        iosCount++;
      }
    }
  } else {
    print('    -> [Skipped] iOS AppIcon directory not found.');
  }

  print('\n==================================================');
  print('SUCCESS: App Icon generation complete!');
  print(' - Android: $androidCount icons updated.');
  print(' - iOS: $iosCount icons updated.');
  print('==================================================');
}
