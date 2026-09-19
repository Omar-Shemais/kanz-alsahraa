import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/widgets/backdrop/filters/widgets/category_item.dart';
import 'package:fstore/widgets/common/tree_view.dart';

void main() {
  test('collapsed hierarchy arrow follows RTL and LTR direction', () {
    expect(categoryExpansionIcon(TextDirection.rtl, false),
        Icons.keyboard_arrow_left);
    expect(categoryExpansionIcon(TextDirection.ltr, false),
        Icons.keyboard_arrow_right);
  });

  test('expanded hierarchy uses down arrow', () {
    expect(categoryExpansionIcon(TextDirection.rtl, true),
        Icons.keyboard_arrow_down);
  });

  test('hierarchy indentation starts on the reading side', () {
    expect(categoryHierarchyMargin(TextDirection.rtl, 3).right, 45);
    expect(categoryHierarchyMargin(TextDirection.rtl, 3).left, 15);
    expect(categoryHierarchyMargin(TextDirection.ltr, 3).left, 45);
    expect(categoryHierarchyMargin(TextDirection.ltr, 3).right, 15);
  });

  testWidgets('tree parent exposes an independent expansion action',
      (tester) async {
    var selected = 0;
    await tester.pumpWidget(MaterialApp(
      home: Parent(
        parent: const SizedBox(),
        parentBuilder: (context, expanded, toggle) => Row(children: [
          TextButton(
            key: const Key('select-category'),
            onPressed: () => selected++,
            child: const Text('سبائك ذهب'),
          ),
          IconButton(
            key: const Key('expand-category'),
            onPressed: toggle,
            icon: Icon(expanded
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_left),
          ),
        ]),
        childList: const ChildList(children: [Text('1 جرام')]),
      ),
    ));

    await tester.tap(find.byKey(const Key('select-category')));
    expect(selected, 1);
    expect(find.text('1 جرام'), findsNothing);

    await tester.tap(find.byKey(const Key('expand-category')));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.text('1 جرام'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
  });
}
