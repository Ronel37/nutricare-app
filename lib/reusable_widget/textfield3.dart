import 'package:flutter/material.dart';

class TextFieldInpute3 extends StatelessWidget {
  final TextEditingController textEditingController;
  final String labelText;
  final bool isPass;
  final TextInputType keyboardType;
  final int? maxLines;

  const TextFieldInpute3({
    super.key,
    required this.textEditingController,
    required this.labelText,
    this.isPass = false,
    this.keyboardType = TextInputType.text, // Set default to TextInputType.text for flexibility
    this.maxLines,  // Support for multiline
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        obscureText: isPass,
        controller: textEditingController,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(
            color: Colors.black45,
            fontSize: 18,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 20,
          ),
          filled: true,
          fillColor: const Color(0xFFedf0f8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(30),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              width: 2,
              color: Color.fromARGB(255, 14, 176, 20),
            ),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
