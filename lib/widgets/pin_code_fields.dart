import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Четыре поля для ввода цифрового кода (SMS или пароль).
class PinCodeFields extends StatelessWidget {
  const PinCodeFields({
    super.key,
    required this.controllers,
    this.firstFocusNode,
    this.obscure = false,
    this.onCompleted,
  });

  final List<TextEditingController> controllers;
  final FocusNode? firstFocusNode;
  final bool obscure;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return Container(
          width: 60,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF001F3F).withOpacity(0.85),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF00BFFF), width: 2),
          ),
          child: TextField(
            controller: controllers[index],
            focusNode: index == 0 ? firstFocusNode : null,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            obscureText: obscure,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 28,
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.bold,
            ),
            maxLength: 1,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 3) {
                FocusScope.of(context).nextFocus();
              }
              if (value.isNotEmpty && index == 3) {
                onCompleted?.call();
              }
            },
          ),
        );
      }),
    );
  }

  static String readCode(List<TextEditingController> controllers) {
    return controllers.map((c) => c.text).join();
  }

  static List<TextEditingController> createControllers() {
    return List.generate(4, (_) => TextEditingController());
  }
}
