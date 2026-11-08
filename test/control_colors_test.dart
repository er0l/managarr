import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:managarr/core/theme/app_colors.dart';
import 'package:managarr/core/theme/control_theme.dart';
import 'package:managarr/core/widgets/service_detail_shell.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('readable actions and exclusive choices in $brightness', (
      tester,
    ) async {
      final theme = applyBrandControlTheme(ThemeData(brightness: brightness));
      var movies = true;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Column(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                  ChoiceChip(
                    label: const Text('Movies'),
                    selected: movies,
                    onSelected: (_) => setState(() => movies = true),
                  ),
                  ChoiceChip(
                    label: const Text('TV Shows'),
                    selected: !movies,
                    onSelected: (_) => setState(() => movies = false),
                  ),
                  ServiceToolbar(
                    children: [
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.sort),
                        label: const Text('Sort'),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.grid_view),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      Color? labelColor(String text) => tester
          .widget<RichText>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is RichText && widget.text.toPlainText() == text,
            ),
          )
          .text
          .style
          ?.color;
      Color? materialColor(Finder parent) => tester
          .widget<Material>(
            find.descendant(of: parent, matching: find.byType(Material)).first,
          )
          .color;
      Color? chipColor(String label) {
        final finder = find.widgetWithText(ChoiceChip, label);
        final chip = tester.widget<ChoiceChip>(finder);
        return ChipTheme.of(
          tester.element(finder),
        ).color?.resolve({if (chip.selected) WidgetState.selected});
      }

      final add = find.byType(FilledButton);
      expect(materialColor(add), AppColors.tealPrimary);
      expect(labelColor('Add'), Colors.white);
      expect(chipColor('Movies'), AppColors.tealPrimary);
      expect(labelColor('Movies'), Colors.white);
      expect(labelColor('TV Shows'), theme.colorScheme.onSurface);

      await tester.tap(find.text('TV Shows'));
      await tester.pumpAndSettle();
      expect(chipColor('TV Shows'), AppColors.tealPrimary);
      expect(labelColor('TV Shows'), Colors.white);
      expect(labelColor('Movies'), theme.colorScheme.onSurface);
      expect(chipColor('Movies'), Colors.transparent);
      expect(labelColor('Sort'), theme.colorScheme.onSurfaceVariant);
      for (final icon in [Icons.sort, Icons.grid_view]) {
        expect(
          IconTheme.of(tester.element(find.byIcon(icon))).color,
          theme.colorScheme.onSurfaceVariant,
        );
      }
      final contrast =
          (Colors.white.computeLuminance() + 0.05) /
          (AppColors.tealPrimary.computeLuminance() + 0.05);
      expect(contrast, greaterThanOrEqualTo(4.5));
    });
  }
}
