import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:voice_recorder/features/audio/presentation/widget/class_message.dart';
import 'package:voice_recorder/features/audio_buble.dart';
import 'package:voice_recorder/features/input_bar_widget.dart';
import 'package:voice_recorder/text_buble.dart';

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
  bool _isPaused = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;
  String? _playingPath;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() => _playingPath = null);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _player.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String path) async {
    try {
      print("Playing: $path");
      if (_playingPath == path) {
        if (_player.playing) {
          await _player.pause();
          setState(() => _playingPath = null);
        } else {
          await _player.play();
          setState(() => _playingPath = path);
        }
      } else {
        await _player.stop();
        await _player.setFilePath(path);
        setState(() => _playingPath = path);
        await _player.play();
      }
    } catch (e) {
      print("Error playing audio: $e");
      setState(() => _playingPath = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cannot play audio: ${e.toString()}")),
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Microphone permission required!")),
          );
        }
        return;
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, "audio_${DateTime.now().millisecondsSinceEpoch}.wav");
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      );
      
      await _recorder.start(config, path: path);
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _isLocked = false;
        _recordDuration = Duration.zero;
      });
      _startTimer();
    } catch (e) {
      debugPrint("Error starting record: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Recording failed: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _togglePauseResume() async {
    if (_isPaused) {
      await _recorder.resume();
      _startTimer();
    } else {
      await _recorder.pause();
      _timer?.cancel();
    }
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _stopRecording({bool save = true}) async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _isLocked = false;
    });

    if (save && path != null) {
      setState(() {
        _messages.insert(0, Message(type: MessageType.audio, content: path));
      });
    }
  }

  void _sendText() {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _messages.insert(0, Message(type: MessageType.text, content: _textController.text));
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Voice Messages"), backgroundColor: Colors.green),
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
                    final msg = _messages[index];
                    return msg.type == MessageType.audio
                        ? AudioBubble(
                            path: msg.content,
                            isPlaying: _playingPath == msg.content && _player.playing, 
                            onPlay: () => _playAudio(msg.content),
                          ) 
                        : TextBubble(text: msg.content);
                  },
                ),
              ),
              InputBarWidget(
                controller: _textController,
                isRecording: _isRecording,
                isLocked: _isLocked,
                isPaused: _isPaused,
                duration: _recordDuration,
                onStartRecord: _startRecording,
                onStopRecord: _stopRecording,
                onCancelRecord: () => _stopRecording(save: false),
                onSendText: _sendText,
                onPauseResume: _togglePauseResume,
                onLock: () => setState(() => _isLocked = true),
                onUnlock: () => setState(() => _isLocked = false),
              ),
            ],
          ),
          if (_isRecording)
            Positioned(
              bottom: 65, 
              left: 20,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 50,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_isLocked) _stopRecording(save: false);
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _isLocked
                                  ? const Icon(Icons.delete, key: ValueKey("del"), color: Colors.red, size: 28)
                                  : const Icon(Icons.lock_outline, key: ValueKey("lock"), color: Colors.grey, size: 28),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
