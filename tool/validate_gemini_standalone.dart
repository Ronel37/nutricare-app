import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

Future<void> main(List<String> args) async {
  final apiKey = args.isNotEmpty ? args.first : Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('Usage: dart run tool/validate_gemini_standalone.dart <API_KEY>\nOr set GEMINI_API_KEY in the environment.');
    exit(64);
  }

  final candidates = <String>[
    'gemini-1.5-pro-latest',
    'gemini-1.5-pro-001',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash-001',
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-1.0-pro',
  ];

  stdout.writeln('Probing Gemini models with provided API key...');
  for (final modelName in candidates) {
    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(maxOutputTokens: 8),
      );
      final resp = await model.generateContent([Content.text('ping')]);
      final text = resp.text ?? '';
      stdout.writeln('OK: $modelName -> ${(text.isNotEmpty ? 'responded' : 'no text')}');
      stdout.writeln('USABLE MODEL: $modelName');
      exit(0);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('not found') || msg.contains('unsupported') || msg.contains('404')) {
        stdout.writeln('SKIP (not available): $modelName');
        continue;
      }
      stderr.writeln('ERROR on $modelName: $e');
      exit(1);
    }
  }

  stderr.writeln('No supported Gemini model found for this API key.');
  exit(2);
}


