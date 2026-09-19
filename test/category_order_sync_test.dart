import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/models/category/category_model_impl.dart';
import 'package:fstore/models/entities/category.dart';
import 'package:fstore/models/index.dart' show AppModel;
import 'package:fstore/modules/dynamic_layout/config/app_config.dart';
import 'package:fstore/services/service_config.dart';
import 'package:fstore/widgets/backdrop/filters/category_filter_categories.dart';

void main() {
  group('Category Order & Hierarchy Tests', () {
    late CategoryModelImpl categoryModel;

    final sampleCategories = <Category>[
      Category(
          id: '124', name: 'سبائك ذهب', parent: '0', subCategories: const []),
      Category(
          id: '126', name: 'جنيهات ذهب', parent: '0', subCategories: const []),
      Category(id: '85', name: 'أساور', parent: '0', subCategories: const []),
      Category(
          id: '90', name: 'المجوهرات', parent: '0', subCategories: const []),
      Category(id: '1', name: '1 تولا', parent: '124', subCategories: const []),
      Category(id: '2', name: '1 جرام', parent: '124', subCategories: const []),
      Category(
          id: '10', name: '10 جرام', parent: '124', subCategories: const []),
    ];

    setUp(() {
      ServerConfig()
          .setConfig({'type': 'woo', 'url': 'https://kanzalsahra.com'});
      categoryModel = CategoryModelImpl();
    });

    test(
        'sortCategoryList orders specified IDs first and preserves remaining without dropping any',
        () {
      final sortingOrder = ['126', '90'];

      categoryModel.sortCategoryList(
        categoryList: List<Category>.of(sampleCategories),
        sortingList: sortingOrder,
      );

      final result = categoryModel.categories!;
      expect(result.length, sampleCategories.length);

      expect(result[0].id, '126');
      expect(result[0].name, 'جنيهات ذهب');
      expect(result[1].id, '90');
      expect(result[1].name, 'المجوهرات');

      final remainingIds = result.sublist(2).map((c) => c.id).toList();
      expect(remainingIds, containsAll(['124', '85', '1', '2', '10']));
    });

    test(
        'rootCategories getter reflects custom order while filtering out child subcategories',
        () {
      final sortingOrder = ['90', '85', '126', '124'];

      categoryModel.sortCategoryList(
        categoryList: List<Category>.of(sampleCategories),
        sortingList: sortingOrder,
      );

      final roots = categoryModel.rootCategories!;
      expect(roots.length, 4);
      expect(roots.map((c) => c.id).toList(), ['90', '85', '126', '124']);
      expect(roots.every((c) => c.isRoot), isTrue);
    });

    test('resortCategories updates category order when new sortingList arrives',
        () {
      categoryModel.sortCategoryList(
        categoryList: List<Category>.of(sampleCategories),
        sortingList: null,
      );

      expect(categoryModel.categories![0].id, '124');

      categoryModel.resortCategories(['85']);
      expect(categoryModel.categories![0].id, '85');
      expect(categoryModel.rootCategories![0].id, '85');
    });

    test('handleCategoryTab handles both int and String category lists safely',
        () {
      final appModel = AppModel();

      final tabWithInts = TabBarMenuConfig(
        layout: 'category',
        categories: [126, 90, 85],
      );
      appModel.handleCategoryTab(tabWithInts);
      expect(appModel.categories, ['126', '90', '85']);

      final tabWithStrings = TabBarMenuConfig(
        layout: 'category',
        categories: ['124', '126'],
      );
      appModel.handleCategoryTab(tabWithStrings);
      expect(appModel.categories, ['124', '126']);
    });

    test('filter-specific order controls visibility without flattening parents',
        () {
      final result = arrangeFilterCategories(
        sampleCategories,
        ['126', '124', '2', '1'],
      );

      expect(result.map((item) => item.id), ['126', '124', '2', '1']);
      expect(result.last.parent, '124');
      expect(result.any((item) => item.id == '90'), isFalse);
    });

    test('selected child is detected so only its ancestor path opens', () {
      expect(
        categoryContainsSelection(sampleCategories, '124', {'2'}),
        isTrue,
      );
      expect(
        categoryContainsSelection(sampleCategories, '126', {'2'}),
        isFalse,
      );
    });

    test('filter category IDs are read separately from Categories tab order',
        () {
      final appModel = AppModel();
      appModel.handleCategoryTab(TabBarMenuConfig(
        layout: 'category',
        categories: ['124', '126'],
        filterCategories: [126, 124, 2],
      ));

      expect(appModel.categories, ['124', '126']);
      expect(appModel.filterCategories, ['126', '124', '2']);
    });
  });
}
