import 'package:flutter/material.dart';

import '../../widgets/common.dart';

/// Alt sayfalar için ortak iskelet (degrade arka plan + başlık).
class SubPageScaffold extends StatelessWidget {
  const SubPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(title), actions: actions),
      body: GradientBackground(child: SafeArea(child: body)),
    );
  }
}
