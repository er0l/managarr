import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Clears imperative detail routes as well as selecting the Dashboard branch.
void returnToDashboard(BuildContext context) {
  final router = GoRouter.of(context);
  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  router.go('/');
}

class ModuleHomeButton extends StatelessWidget {
  const ModuleHomeButton({super.key, this.onImage = false});
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton.icon(
        onPressed: () => returnToDashboard(context),
        style: TextButton.styleFrom(
          foregroundColor: onImage ? Colors.white : colors.primary,
          backgroundColor: onImage ? Colors.black54 : colors.primaryContainer,
          minimumSize: const Size(76, 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        icon: const Icon(Icons.home_outlined, size: 20),
        label: const Text('Home'),
      ),
    );
  }
}

class ModuleBackButton extends StatelessWidget {
  const ModuleBackButton({super.key, this.onImage = false});
  final bool onImage;

  @override
  Widget build(BuildContext context) => BackButton(
    color: onImage ? Colors.white : Theme.of(context).colorScheme.onSurface,
    onPressed: () async {
      if (!await Navigator.of(context).maybePop() && context.mounted) {
        returnToDashboard(context);
      }
    },
  );
}

/// Shared chrome for module roots, forms, and secondary screens.
class ModuleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ModuleAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.bottom,
    this.leading,
    this.toolbarHeight = kToolbarHeight,
    this.centerTitle = false,
  });
  final Widget title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final double toolbarHeight;
  final bool centerTitle;

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      toolbarHeight: toolbarHeight,
      automaticallyImplyLeading: false,
      leading: leading ?? const ModuleBackButton(),
      title: title,
      actions: [...actions, const ModuleHomeButton()],
      bottom: bottom,
    );
  }
}
