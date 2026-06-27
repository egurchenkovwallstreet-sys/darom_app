import 'dart:html' as html;

import '../services/payments_api.dart';

void submitRobokassaPaymentForm(RobokassaPaymentForm form) {
  final element = html.FormElement()
    ..action = form.action
    ..method = form.method;

  for (final entry in form.fields.entries) {
    element.append(
      html.InputElement()
        ..type = 'hidden'
        ..name = entry.key
        ..value = entry.value,
    );
  }

  html.document.body?.append(element);
  element.submit();
}
