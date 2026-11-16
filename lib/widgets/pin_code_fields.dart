import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';
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
            color: AppColors.surface.withOpacity(0.92),
            borderRadius: BorderRadius.circular(15),
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
              color: AppColors.textPrimary,
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
