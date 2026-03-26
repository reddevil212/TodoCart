import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:todocart/models/task_structure.dart';
import 'package:todocart/services/api/api.dart';

class VoiceCommandResult {
  final String? transcript;
  final TaskStructure? structure;
  final String message;
  final bool success;

  const VoiceCommandResult({
    required this.transcript,
    required this.structure,
    required this.message,
    required this.success,
  });
}

class VoiceCommandService {
  VoiceCommandService._();

  static final VoiceCommandService instance = VoiceCommandService._();

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  String? _listenFailureMessage;

  Future<VoiceCommandResult> processVoiceCommand({
    bool speakFeedback = true,
  }) async {
    final transcript = await _listenOnce();
    if (transcript == null || transcript.trim().isEmpty) {
      final fallback =
          _listenFailureMessage ??
          'Could not listen. Please allow microphone access or type your task.';
      if (speakFeedback) {
        await _speak(fallback);
      }
      return VoiceCommandResult(
        transcript: null,
        structure: null,
        message: fallback,
        success: false,
      );
    }

    final parsed = await parseTaskCommand(transcript);

    return VoiceCommandResult(
      transcript: transcript,
      structure: parsed.structure,
      message: parsed.assistantMessage,
      success: true,
    );
  }

  Future<String?> _listenOnce() async {
    _listenFailureMessage = null;

    final available = await _speech.initialize(
      onStatus: (_) {},
      onError: (error) {
        if (error.errorMsg.isNotEmpty) {
          _listenFailureMessage = 'Voice error: ${error.errorMsg}';
        }
      },
      debugLogging: false,
    );

    if (!available) {
      _listenFailureMessage =
          'Microphone unavailable. Please allow microphone permission and try again.';
      return null;
    }

    final completer = Completer<String>();
    var recognized = '';
    var receivedFinalResult = false;

    await _speech.listen(
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      onSoundLevelChange: (_) {},
      onResult: (result) {
        recognized = result.recognizedWords;
        if (result.finalResult && !completer.isCompleted) {
          receivedFinalResult = true;
          completer.complete(recognized);
        }
      },
    );

    final output = await completer.future.timeout(
      const Duration(seconds: 14),
      onTimeout: () => recognized,
    );

    await _speech.stop();

    if (!receivedFinalResult && output.trim().isEmpty) {
      _listenFailureMessage =
          'I could not catch that. Please speak clearly and try again.';
    }

    return output.trim().isEmpty ? null : output.trim();
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }
}
