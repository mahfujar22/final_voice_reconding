import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class AudioBubble extends StatelessWidget {
  final String path;
  final bool isPlaying;
  final VoidCallback onPlay;

  const AudioBubble({
    required this.path,
    required this.isPlaying,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 50),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onPlay,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green,
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.graphic_eq, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              "${p.basename(path).split('.')[0]}",
              style: const TextStyle(color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}





