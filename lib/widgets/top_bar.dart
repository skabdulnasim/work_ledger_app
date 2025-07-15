import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String pageTitle;
  final List<dynamic> actions;
  final void Function(String value)? onSelected;

  TopBar({
    super.key,
    required this.pageTitle,
    required this.actions,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(pageTitle),
      actions: (actions.isNotEmpty && actions is List<Widget>)
          ? actions as List<Widget>
          : [
              if (actions.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (String value) {
                    if (onSelected != null) {
                      onSelected!(value);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return actions.map((action) {
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
