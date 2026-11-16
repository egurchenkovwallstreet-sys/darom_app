import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/darom_decorations.dart';
import '../utils/responsive_layout.dart';
import 'keyboard_inset_padding.dart';
import 'responsive_page_frame.dart';

/// Прокручиваемая форма входа/регистрации — поле не перекрывается клавиатурой (в т.ч. на телефоне в браузере).
///
/// Раскладка не меняется при фокусе: иначе на мобильном вебе форма «прыгает».
class AuthFormScroll extends StatefulWidget {
  const AuthFormScroll({
    super.key,
    required this.title,
    required this.form,
    this.subtitle,
    this.subtitleWidget,
    this.compactSubtitle,
    this.leading,
    this.footer,
    this.focusNode,
    this.formKey,
  });

  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
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
    if (!_focusNode.hasFocus) return;
    Future<void>.delayed(const Duration(milliseconds: 350), _scrollToForm);
  }

  void _scrollToForm() {
    if (!mounted || !_focusNode.hasFocus) return;
    final target = widget.formKey?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      duration: DaromDecorations.interactionDuration,
      curve: DaromDecorations.interactionCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.subtitle;

    return KeyboardInsetPadding(
      child: SafeArea(
        child: ResponsivePageFrame(
          maxWidth: ResponsiveLayout.authFormMaxWidth(context),
          child: SingleChildScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.leading != null) ...[
                  Center(child: widget.leading!),
                  const SizedBox(height: 24),
                ],
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: DaromDecorations.titleStyle(fontSize: 26),
                ),
                if (widget.subtitleWidget != null) ...[
                  const SizedBox(height: 12),
                  widget.subtitleWidget!,
                ] else if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                KeyedSubtree(
                  key: widget.formKey,
                  child: widget.form,
                ),
                if (widget.footer != null) ...[
                  const SizedBox(height: 24),
                  widget.footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
