import 'package:flutter/material.dart';
import 'package:stardom/core/utils/constants/sizes.dart';

class BaseScreen extends StatelessWidget {
  final Widget content;
  final bool? allowResize;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? title;
  final Color? backgroundColor;

  const BaseScreen(
      {super.key, required this.content, this.leading, this.actions, this.allowResize = false, this.title, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    var shouldDisplayAppbar = leading != null || actions != null || title != null;
    return Scaffold(
      backgroundColor: backgroundColor ,
      resizeToAvoidBottomInset: allowResize,
      appBar: shouldDisplayAppbar
          ? AppBar(
              leading: leading, actions: actions, title: title, automaticallyImplyLeading: false, centerTitle: true)
          : null,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: SSizes.md,
                right: SSizes.md,
                bottom: viewPadding.bottom + SSizes.sm,
              ),
              child: content,
            ),
          );
        }),
      ),
    );
  }
}
