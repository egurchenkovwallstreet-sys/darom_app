import 'package:flutter/material.dart';

import 'keyboard_inset_padding.dart';

/// Прокручиваемая форма входа/регистрации — поле не перекрывается клавиатурой (в т.ч. на телефоне в браузере).
class AuthFormScroll extends StatefulWidget {
  const AuthFormScroll({
    super.key,
    required this.title,
    required this.form,
    this.subtitle,
    this.compactSubtitle,
    this.leading,
    this.footer,
    this.focusNode,
    this.formKey,
  });

  final String title;
  final String? subtitle;
  final String? compactSubtitle;
  final Widget? leading;
  final Widget form;
  final Widget? footer;
  final FocusNode? focusNode;
  final GlobalKey? formKey;

  @override
  State<AuthFormScroll> createState() => _AuthFormScrollState();
}

class _AuthFormScrollState extends State<AuthFormScroll> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  final _scrollController = ScrollController();

  bool get _compact => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
    if (!_focusNode.hasFocus) return;

    for (final delay in [200, 400, 600]) {
      Future<void>.delayed(Duration(milliseconds: delay), _scrollToForm);
    }
  }

  void _scrollToForm() {
    if (!mounted || !_focusNode.hasFocus) return;
    final target = widget.formKey?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.25,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _compact
        ? (widget.compactSubtitle ?? widget.subtitle)
        : widget.subtitle;

    return KeyboardInsetPadding(
      child: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(30, _compact ? 12 : 24, 30, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_compact && widget.leading != null) ...[
                widget.leading!,
                const SizedBox(height: 32),
              ],
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _compact ? 22 : 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFFFFF),
                  shadows: const [
                    Shadow(
                      color: Color(0x6600BFFF),
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFFFFFFFF).withOpacity(0.7),
                    height: 1.45,
                  ),
                ),
              ],
              SizedBox(height: _compact ? 20 : 32),
              KeyedSubtree(
                key: widget.formKey,
                child: widget.form,
              ),
              if (widget.footer != null) ...[
                SizedBox(height: _compact ? 20 : 32),
                widget.footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
