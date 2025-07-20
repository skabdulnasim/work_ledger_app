import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String pageTitle;
  final List<dynamic> menuActions;
  final List<Widget> fixedAction;
  final void Function(String value)? onSelected;

  TopBar({
    super.key,
    required this.pageTitle,
    required this.menuActions,
    required this.fixedAction,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(pageTitle),
      actions: (menuActions.isNotEmpty && menuActions is List<Widget>)
          ? menuActions as List<Widget>
          : fixedAction +
              [
                if (menuActions.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (String value) {
                      if (onSelected != null) {
                        onSelected!(value);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return menuActions.map((action) {
                        return PopupMenuItem<String>(
                          value: action['value'],
                          child: Text(action['label'] ?? ''),
                        );
                      }).toList();
                    },
                  ),
              ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
