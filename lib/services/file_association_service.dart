import 'dart:io';

/// Registers the .tcmaker file type in the Windows registry on first run.
/// The icon is embedded in the exe itself (IDI_FILE_ICON, index 1),
/// so no separate .ico file is needed – the exe path is always correct.
class FileAssociationService {
  static Future<void> registerIfNeeded() async {
    if (!Platform.isWindows) return;

    try {
      final exePath = Platform.resolvedExecutable.replaceAll('/', '\\');

      // Check if already registered with our exe
      final checkResult = await Process.run('reg', [
        'query',
        r'HKCU\Software\Classes\TitleCardMaker.Project\shell\open\command',
        '/ve',
      ]);

      if (checkResult.stdout.toString().contains(exePath)) return; // already up to date

      // Write all registry keys
      final entries = {
        r'HKCU\Software\Classes\.tcmaker': {'': 'TitleCardMaker.Project'},
        r'HKCU\Software\Classes\TitleCardMaker.Project': {
          '': 'Title Card Maker Project'
        },
        r'HKCU\Software\Classes\TitleCardMaker.Project\DefaultIcon': {
          // Index 1 = IDI_FILE_ICON embedded in the exe
          '': '"$exePath",1'
        },
        r'HKCU\Software\Classes\TitleCardMaker.Project\shell\open\command': {
          '': '"$exePath" "%1"'
        },
      };

      for (final entry in entries.entries) {
        for (final value in entry.value.entries) {
          final args = [
            'add', entry.key,
            '/f',
            '/t', 'REG_SZ',
          ];
          if (value.key.isNotEmpty) {
            args.addAll(['/v', value.key]);
          } else {
            args.add('/ve');
          }
          args.addAll(['/d', value.value]);
          await Process.run('reg', args);
        }
      }

      // Notify the shell so Explorer updates icons immediately
      await Process.run('ie4uinit.exe', ['-show']);
    } catch (_) {
      // Registration is best-effort; never crash the app over this
    }
  }
}
