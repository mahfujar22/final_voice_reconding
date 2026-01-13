import 'package:flutter/material.dart';
import 'audio_screen.dart';

void main() => runApp(const VoiceApp());

class VoiceApp extends StatelessWidget {
  const VoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const AudioScreen(),
    );
  }
}