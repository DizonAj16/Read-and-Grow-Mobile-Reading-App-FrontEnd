import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderWidget extends StatefulWidget {
  final String studentId;
  final String quizQuestionId;
  final Function(String) onRecordComplete;

  const AudioRecorderWidget({
    Key? key,
    required this.studentId,
    required this.quizQuestionId,
    required this.onRecordComplete,
  }) : super(key: key);

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedPath;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/audio_${widget.studentId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
        _recordedPath = path;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      await _recorder.stop();
      setState(() => _isRecording = false);
      if (_recordedPath != null) {
        widget.onRecordComplete(_recordedPath!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording saved locally')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Record your answer:"),
        const SizedBox(height: 10),
        FloatingActionButton(
          backgroundColor: _isRecording ? Colors.red : Colors.green,
          onPressed: _isRecording ? _stopRecording : _startRecording,
          child: Icon(_isRecording ? Icons.stop : Icons.mic),
        ),
        if (_recordedPath != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Recorded: ${_recordedPath!.split('/').last}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
