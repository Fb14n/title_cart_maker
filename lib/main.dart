import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'providers/project_provider.dart';
import 'screens/home_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  String? fileToOpen;
  
  // Check if a file was passed as argument (e.g., from double-click)
  if (args.isNotEmpty) {
    final potentialFile = args.first;
    if (File(potentialFile).existsSync() && potentialFile.endsWith('.tcmaker')) {
      fileToOpen = potentialFile;
    }
  }
  
  runApp(MyApp(fileToOpen: fileToOpen));
}

class MyApp extends StatelessWidget {
  final String? fileToOpen;
  
  const MyApp({super.key, this.fileToOpen});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectProvider(),
      child: MaterialApp(
        title: 'Title Card Maker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: HomeScreen(fileToOpen: fileToOpen),
      ),
    );
  }
}
