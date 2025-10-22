import 'dart:io';

import 'package:nutricare_app/services/gemini_service.dart';

Future<void> main(List<String> args) async {
  final apiKey = args.isNotEmpty ? args.first : Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('Usage: dart run tool/validate_gemini.dart <API_KEY>\nOr set GEMINI_API_KEY in the environment.');
    exit(64);
  }
  stdout.writeln('Validating Gemini API key...');
  final result = await GeminiService.validateApiKeyAccess(apiKey);
  stdout.writeln(result);
}


