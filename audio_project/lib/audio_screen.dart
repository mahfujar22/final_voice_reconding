import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:voice_recorder/features/audio/presentation/widget/class_message.dart';
import 'package:voice_recorder/features/audio/presentation/widget/input_bar_widget.dart';
import 'package:voice_recorder/features/audio/presentation/widget/text_bubble.dart';
import 'package:voice_recorder/features/audio_bubble.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final _textController = TextEditingController();

  List<Message> _messages = [];

  bool _isRecording = false;
  bool _isLocked = false;
  String? _playingPath;

  Duration _recordDuration = Duration.zero;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _player.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;

    final dir = await getApplicationDocumentsDirectory();
    final path =
        p.join(dir.path, "audio_${DateTime.now().millisecondsSinceEpoch}.m4a");

    await _recorder.start(const RecordConfig(), path: path);

    setState(() {
      _isRecording = true;
      _isLocked = false;
      _recordDuration = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _timer?.cancel();
    final path = await _recorder.stop();

    setState(() {
      _isRecording = false;
      _isLocked = false;
    });

    if (path != null) {
      _messages.insert(0, Message(type: MessageType.audio, content: path));
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    _timer?.cancel();
    await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isLocked = false;
    });
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.insert(0, Message(type: MessageType.text, content: text));
      _textController.clear();
    });
  }

  Future<void> _playAudio(String path) async {
    if (_playingPath == path) {
      _player.playing ? await _player.pause() : await _player.play();
    } else {
      await _player.setFilePath(path);
      setState(() => _playingPath = path);
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Voice Messages"),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return message.type == MessageType.audio
                        ? AudioBubble(
                            path: message.content,
                            isPlaying: _playingPath == message.content,
                            onPlay: () => _playAudio(message.content),
                          )
                        : TextBubble(text: message.content);
                  },
                ),
              ),
              InputBarWidget(
                controller: _textController,
                isRecording: _isRecording,
                isLocked: _isLocked,
                duration: _recordDuration,
                onStartRecord: _startRecording,
                onStopRecord: _stopRecording,
                onCancelRecord: _cancelRecording,
                onSendText: _sendText,
                onLock: () => setState(() => _isLocked = true),
                onUnlock: () => setState(() => _isLocked = false),
              ),
            ],
          ),
          if (_isRecording)
            Positioned(
              bottom: 60, 
              left: 20,   
              child: AnimatedScale(
                scale: _isLocked ? 1.2 : 0.8,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _isLocked ? Icons.lock : Icons.lock_open,
                  size: 40,
                  color: _isLocked ? Colors.green : Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}



