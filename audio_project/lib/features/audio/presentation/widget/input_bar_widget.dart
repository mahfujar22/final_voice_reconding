
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class InputBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final bool isRecording;
  final bool isLocked;
  final Duration duration;
  final VoidCallback onStartRecord;
  final VoidCallback onStopRecord;
  final VoidCallback onCancelRecord;
  final VoidCallback onSendText;
  final VoidCallback onLock;
  final VoidCallback onUnlock;

  const InputBarWidget({
    required this.controller,
    required this.isRecording,
    required this.isLocked,
    required this.duration,
    required this.onStartRecord,
    required this.onStopRecord,
    required this.onCancelRecord,
    required this.onSendText,
    required this.onLock,
    required this.onUnlock,
    super.key,
  });

  @override
  State<InputBarWidget> createState() => _InputBarWidgetState();
}

class _InputBarWidgetState extends State<InputBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _micController;
  late Animation<double> _micAnimation;

  late Timer _dotsTimer;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();

    _micController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _micAnimation =
        Tween<double>(begin: 0, end: 8).animate(CurvedAnimation(
      parent: _micController,
      curve: Curves.easeInOut,
    ))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _micController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              _micController.forward();
            }
          });

    if (widget.isRecording) {
      _micController.forward();
      _startDotsTimer();
    }
  }

  void _startDotsTimer() {
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        _dotCount = (_dotCount + 1) % 4;
      });
    });
  }

  void _stopDotsTimer() {
    _dotsTimer.cancel();
  }

  @override
  void didUpdateWidget(covariant InputBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRecording && !_micController.isAnimating) {
      _micController.forward();
      _startDotsTimer();
    } else if (!widget.isRecording && _micController.isAnimating) {
      _micController.stop();
      _stopDotsTimer();
    }
  }

  @override
  void dispose() {
    _micController.dispose();
    _stopDotsTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onLongPressStart: (_) => widget.onStartRecord(),
                    onLongPressMoveUpdate: (d) {
                      if (d.localPosition.dy < -40) widget.onLock();
                      if (!widget.isLocked && d.localPosition.dx > 120) {
                        widget.onCancelRecord();
                      }
                    },
                    onLongPressEnd: (_) {
                      if (!widget.isLocked) widget.onStopRecord();
                    },
                    child: AnimatedBuilder(
                      animation: _micAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, -_micAnimation.value),
                          child: Icon(
                            Icons.mic,
                            color: widget.isRecording ? Colors.red : Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: widget.isRecording
                        ? Text(
                            "Recording${'.' * _dotCount}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : TextField(
                            controller: widget.controller,
                            decoration: const InputDecoration(
                              hintText: "Type a message...",
                              border: InputBorder.none,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap:
                widget.isRecording ? widget.onStopRecord : widget.onSendText,
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.green,
              child: Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}



