import 'dart:async';

import 'package:flutter/material.dart';

/// Оставшееся время брони без секунд: «5 ч 20 мин» или «45 мин».
String? formatReservationRemaining(DateTime? until) {
  if (until == null) return null;

  final remaining = until.toUtc().difference(DateTime.now().toUtc());
  if (remaining.isNegative) return null;

  final totalMinutes = remaining.inMinutes;
  if (totalMinutes <= 0) return '< 1 мин';

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours > 0) {
    if (minutes > 0) return '$hours ч $minutes мин';
    return '$hours ч';
  }
  return '$minutes мин';
}

/// Живой обратный отсчёт брони (обновление раз в минуту, без секунд).
class ReservationCountdownText extends StatefulWidget {
  const ReservationCountdownText({
    super.key,
    required this.until,
    this.style,
    this.prefix = '',
    this.expiredLabel,
  });

  final DateTime? until;
  final TextStyle? style;
  final String prefix;
  final String? expiredLabel;

  @override
  State<ReservationCountdownText> createState() => _ReservationCountdownTextState();
}

class _ReservationCountdownTextState extends State<ReservationCountdownText> {
  Timer? _timer;
  String? _label;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  @override
  void didUpdateWidget(covariant ReservationCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.until != widget.until) {
      _refresh();
    }
  }

  void _refresh() {
    final formatted = formatReservationRemaining(widget.until);
    if (!mounted) return;
    setState(() => _label = formatted);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    if (label == null) {
      if (widget.expiredLabel == null) return const SizedBox.shrink();
      return Text('${widget.prefix}${widget.expiredLabel}', style: widget.style);
    }
    return Text('${widget.prefix}$label', style: widget.style);
  }
}
