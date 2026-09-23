import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/config.dart';
import '../common/config/models/index.dart';
import '../common/constants.dart';
import '../common/tools.dart';
import '../generated/l10n.dart';
import '../models/index.dart'
    show AppModel, BackDropArguments, Category, CategoryModel, UserModel;
import '../modules/dynamic_layout/config/app_config.dart';
import '../modules/dynamic_layout/helper/helper.dart';
import '../routes/flux_navigate.dart';
import '../services/index.dart';
import '../widgets/common/index.dart' show FluxImage, WebView;
import '../widgets/general/index.dart';
import 'kanz_drawer_categories.dart';
import 'maintab_delegate.dart';

class SideBarMenu extends StatefulWidget {
  const SideBarMenu();

  @override
  MenuBarState createState() => MenuBarState();
}

class MenuBarState extends State<SideBarMenu> {
  static List<Category>? _cachedPublicDrawerCategories;
  List<Category>? _publicDrawerCategories = _cachedPublicDrawerCategories;
  bool _drawerCategoriesLoading = false;
  bool _drawerCategoriesFailed = false;
  bool _drawerCategoriesScheduled = false;

  void _loadDrawerCategories() {
    if (_drawerCategoriesLoading) return;
    setState(() => _drawerCategoriesLoading = true);
    loadPublicDrawerCategories().then((categories) {
      if (!mounted) return;
      setState(() {
        _publicDrawerCategories = categories;
        _cachedPublicDrawerCategories = categories;
        _drawerCategoriesLoading = false;
        _drawerCategoriesFailed = false;
      });
    }).catchError((Object _) {
      if (!mounted) return;
      setState(() {
        _drawerCategoriesLoading = false;
        _drawerCategoriesFailed = true;
      });
    });
  }

  bool get isEcommercePlatform =>
      !ServerConfig().isListingType || !ServerConfig().isWordPress;

  DrawerMenuConfig get drawer =>
      Provider.of<AppModel>(context, listen: false).appConfig?.drawer ??
      kDefaultDrawer;

  Color get backgroundColor =>
      drawer.backgroundColor.toColor() ?? Theme.of(context).colorScheme.surface;

  Color get textColor {
    return drawer.textColor.toColor() ??
        backgroundColor.getColorBasedOnBackground;
  }

  Color get iconColor {
    return drawer.iconColor.toColor() ??
        backgroundColor.getColorBasedOnBackground;
  }

  TextStyle get textStyle => TextStyle(color: textColor);

  void pushNavigator({String? name, Widget? screen}) {
    eventBus.fire(const EventCloseNativeDrawer());
    if (name?.isNotEmpty ?? false) {
      MainTabControlDelegate.getInstance()
          .changeTab(name?.replaceFirst('/', ''));
      return;
    }
    if (screen != null) {
      FluxNavigate.push(
        MaterialPageRoute(builder: (_) => screen),
        context: context,
      );
    }
  }

  void onNavigator() {
    eventBus.fire(const EventCloseNativeDrawer());
  }

  @override
  Widget build(BuildContext context) {
    final kanzDrawer = Provider.of<AppModel>(context).appConfig?.kanzDrawer;
    if (kanzDrawer?.enabled == true) {
      return buildKanzDrawer(kanzDrawer!);
    }
    var isDarkTheme = Provider.of<AppModel>(context, listen: false).darkTheme;
    var logo = drawer.getLogoByTheme(isDarkTheme);

    printLog('[AppState] Load Menu');

    return SafeArea(
      top: drawer.safeArea,
      right: false,
      bottom: false,
      left: false,
      child: Padding(
        key: drawer.key != null ? Key(drawer.key as String) : UniqueKey(),
        padding: EdgeInsets.only(
            bottom:
                injector<AudioManager>().isStickyAudioWidgetActive ? 46 : 0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (logo != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      color: drawer.logoConfig.backgroundColor.toColor(),
                      padding: EdgeInsets.only(
                        bottom: drawer.logoConfig.marginBottom.toDouble(),
                        top: drawer.logoConfig.marginTop.toDouble(),
                        left: drawer.logoConfig.marginLeft.toDouble(),
                        right: drawer.logoConfig.marginRight.toDouble(),
                      ),
                      child: FluxImage(
                        width: drawer.logoConfig.useMaxWidth
                            ? MediaQuery.of(context).size.width
                            : drawer.logoConfig.width?.toDouble(),
                        fit: Helper.boxFit(drawer.logoConfig.boxFit),
                        height: drawer.logoConfig.height.toDouble(),
                        imageUrl: logo,
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
              ...List.generate(
                drawer.items?.length ?? 0,
                (index) {
                  return drawerItem(
                    drawer.items![index],
                    drawer.subDrawerItem ?? {},
                  );
                },
              ),
              Layout.isDisplayDesktop(context)
                  ? const SizedBox(height: 300)
                  : const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildKanzDrawer(KanzDrawerConfig config) {
    if (_publicDrawerCategories == null &&
        !_drawerCategoriesLoading &&
        !_drawerCategoriesFailed &&
        !_drawerCategoriesScheduled) {
      _drawerCategoriesScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _drawerCategoriesScheduled = false;
        if (mounted) _loadDrawerCategories();
      });
    }
    final modelCategories = context.watch<CategoryModel>().categories;
    final categories = (_publicDrawerCategories?.isNotEmpty ?? false)
        ? _publicDrawerCategories!
        : (modelCategories?.isNotEmpty ?? false)
            ? modelCategories!
            : _immediateDrawerCategories();
    final roots = categories
        .where((category) =>
            category.isRoot &&
            category.slug != 'uncategorized' &&
            _visibleCategory(category, categories, config.hideEmptyCategories))
        .toList();
    const websiteCategoryIds = ['124', '130', '438', '430', '453'];
    final categoryOrder = config.rootCategoryIds.isNotEmpty
        ? config.rootCategoryIds
        : websiteCategoryIds;
    if (roots.any((category) => categoryOrder.contains(category.id))) {
      roots.removeWhere((category) => !categoryOrder.contains(category.id));
      roots.sort((a, b) => categoryOrder
          .indexOf(a.id ?? '')
          .compareTo(categoryOrder.indexOf(b.id ?? '')));
    }
    final isDarkTheme = Provider.of<AppModel>(context, listen: false).darkTheme;
    final logo = drawer.getLogoByTheme(isDarkTheme);
    const foreground = Color(0xFF1D1F1F);
    const accent = Color(0xFFC8A34B);
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: true,
        bottom: true,
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (logo != null && logo.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Center(
                    child: FluxImage(
                      imageUrl: logo,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFEBEBEB), height: 1, thickness: 1),
              ],
              if (config.showSearch)
                _kanzMenuRow(
                  'البحث عن المنتجات',
                  leading: const Icon(Icons.search, color: foreground, size: 20),
                  onTap: () {
                    onNavigator();
                    FluxNavigate.pushNamed(RouteList.search, context: context);
                  },
                ),
              for (final root in roots)
                _kanzCategoryTile(root, categories, config.hideEmptyCategories),
              if (config.showTracking)
                _kanzMenuRow(
                  'تتبع شحنتك',
                  color: accent,
                  onTap: () => pushNavigator(
                      screen: const WebView(
                    url: 'https://kanzalsahra.com/تتبع-شحنتك/',
                    title: 'تتبع شحنتك',
                  )),
                ),
              if (config.showCorporate)
                _kanzMenuRow(
                  'طلبات الشركات',
                  onTap: () => pushNavigator(
                      screen: const WebView(
                    url:
                        'https://kanzalsahra.com/corporate-gold-bullion-requests/',
                    title: 'طلبات الشركات',
                  )),
                ),
              const SizedBox(height: 30),
              const Divider(color: Color(0xFFEBEBEB), height: 1, thickness: 1),
              _kanzMenuRow('الرئيسية',
                  onTap: () => pushNavigator(name: RouteList.home)),
              _kanzMenuRow('السلة',
                  onTap: () => pushNavigator(name: RouteList.cart)),
              _kanzMenuRow('حسابي',
                  onTap: () => pushNavigator(name: RouteList.profile)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kanzMenuRow(String label,
      {VoidCallback? onTap,
      Widget? leading,
      Color color = const Color(0xFF1D1F1F)}) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFFF0F0F0),
        highlightColor: const Color(0xFFF9F9F9),
        child: Container(
          height: 51,
          padding: const EdgeInsetsDirectional.only(start: 22, end: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFEBEBEB), width: 0.8)),
          ),
          child: Row(children: [
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700))),
            if (leading != null) leading,
          ]),
        ),
      ),
    );
  }

  List<Category> _immediateDrawerCategories() => [
        Category(
            id: '124',
            name: 'سبائك ذهب',
            parent: '0',
            totalProduct: 1,
            subCategories: []),
        Category(
            id: '130',
            name: 'جنيهات ذهب',
            parent: '0',
            totalProduct: 1,
            subCategories: []),
        Category(
            id: '438',
            name: 'أساور',
            parent: '0',
            totalProduct: 1,
            subCategories: []),
        Category(
            id: '430',
            name: 'سبائك فضة',
            parent: '0',
            totalProduct: 1,
            subCategories: []),
        Category(
            id: '453',
            name: 'أطقم الماس',
            parent: '0',
            totalProduct: 1,
            subCategories: []),
      ];

  bool _visibleCategory(Category category, List<Category> all, bool hideEmpty,
      [Set<String>? visited]) {
    if (!hideEmpty || (category.totalProduct ?? 0) > 0) return true;
    final seen = visited ?? <String>{};
    if (category.id == null || !seen.add(category.id!)) return false;
    return all
        .where((child) => child.parent == category.id)
        .any((child) => _visibleCategory(child, all, hideEmpty, seen));
  }

  Widget _kanzCategoryTile(
      Category category, List<Category> all, bool hideEmpty) {
    final children = all
        .where((child) =>
            child.parent == category.id &&
            _visibleCategory(child, all, hideEmpty))
        .toList();
    final label = category.id == '453' ? 'أطقم الماس' : category.name ?? '';
    if (children.isEmpty) {
      return _kanzMenuRow(label, onTap: () => _openKanzCategory(category));
    }
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: const Color(0xFFF0F0F0),
        highlightColor: const Color(0xFFF9F9F9),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsetsDirectional.only(start: 22, end: 20),
        childrenPadding: EdgeInsets.zero,
        iconColor: const Color(0xFF1D1F1F),
        collapsedIconColor: const Color(0xFF1D1F1F),
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        shape: const Border(bottom: BorderSide(color: Color(0xFFEBEBEB), width: 0.8)),
        collapsedShape: const Border(bottom: BorderSide(color: Color(0xFFEBEBEB), width: 0.8)),
        title: Text(label,
            style: const TextStyle(
              color: Color(0xFF1D1F1F),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            )),
        children: [
          _kanzMenuRow('عرض الكل', onTap: () => _openKanzCategory(category)),
          for (final child in children)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12),
              child: _kanzCategoryTile(child, all, hideEmpty),
            ),
        ],
      ),
    );
  }

  void _openKanzCategory(Category category) {
    onNavigator();
    navigateToBackDrop(category);
  }

  Widget drawerItem(
    DrawerItemsConfig drawerItemConfig,
    Map<String, GeneralSettingItem> subDrawerItem,
  ) {
    if (drawerItemConfig.show == false) return const SizedBox();
    var value = drawerItemConfig.type;

    switch (value) {
      case 'home':
        {
          return ListTile(
            leading: Icon(
              isEcommercePlatform ? Icons.home : Icons.shopping_basket,
              size: 20,
              color: iconColor,
            ),
            title: Text(
              isEcommercePlatform ? S.of(context).home : S.of(context).shop,
              style: textStyle,
            ),
            onTap: () {
              pushNavigator(name: RouteList.home);
            },
          );
        }
      case 'categories':
        {
          return ListTile(
            leading: Icon(
              Icons.category,
              size: 20,
              color: iconColor,
            ),
            title: Text(
              S.of(context).categories,
              style: textStyle,
            ),
            onTap: () => pushNavigator(
              name: !Provider.of<AppModel>(context, listen: false).isMultivendor
                  ? RouteList.category
                  : RouteList.vendorCategory,
            ),
          );
        }
      case 'cart':
        {
          if ((!Services().widget.enableShoppingCart(null)) ||
              ServerConfig().isListingType) {
            return const SizedBox();
          }
          return ListTile(
            leading: Icon(
              Icons.shopping_cart,
              size: 20,
              color: iconColor,
            ),
            title: Text(
              S.of(context).cart,
              style: textStyle,
            ),
            onTap: () => pushNavigator(name: RouteList.cart),
          );
        }
      case 'profile':
        {
          return ListTile(
            leading: Icon(
              Icons.person,
              size: 20,
              color: iconColor,
            ),
            title: Text(
              S.of(context).settings,
              style: textStyle,
            ),
            onTap: () => pushNavigator(name: RouteList.profile),
          );
        }
      case 'web':
        {
          return ListTile(
            leading: Icon(
              Icons.web,
              size: 20,
              color: iconColor,
            ),
            title: Text(
              S.of(context).webView,
              style: textStyle,
            ),
            onTap: () {
              pushNavigator(
                screen: WebView(
                  url: 'https://inspireui.com',
                  title: S.of(context).webView,
                ),
              );
            },
          );
        }
      case 'blog':
        {
          return ListTile(
            leading: Icon(
              CupertinoIcons.news_solid,
              size: 20,
              color: iconColor,
            ),
            title: Text(
              S.of(context).blog,
              style: textStyle,
            ),
            onTap: () => pushNavigator(name: RouteList.listBlog),
          );
        }
      case 'login':
        {
          if (!kLoginSetting.enable) {
            return const SizedBox();
          }
          return ListenableProvider.value(
            value: Provider.of<UserModel>(context, listen: false),
            child: Consumer<UserModel>(builder: (context, userModel, _) {
              final loggedIn = userModel.loggedIn;
              return ListTile(
                leading: Icon(Icons.exit_to_app, size: 20, color: iconColor),
                title: loggedIn
                    ? Text(S.of(context).logout, style: textStyle)
                    : Text(S.of(context).login, style: textStyle),
                onTap: () async {
                  if (loggedIn) {
                    final confirmed = await context.showFluxDialogConfirm(
                      useAppNavigator: true,
                      primaryAsDestructiveAction: true,
                      title: S.of(context).logout,
                      body: S.of(context).areYouSureLogOut,
                    );
                    if (!confirmed) return;
                    unawaited(userModel.logout());
                    if (Services().widget.isRequiredLogin) {
                      unawaited(NavigateTools.navigateToLogin(
                        context,
                        replacement: true,
                      ));
                    }
                  } else {
                    unawaited(NavigateTools.navigateToLogin(
                      context,
                    ));
                  }
                },
              );
            }),
          );
        }
      case 'category':
        {
          return buildListCategory();
        }
      default:
        {
          var item = subDrawerItem[value];
          if (value?.contains('web') ?? false) {
            return GeneralWebWidget(
              item: item,
              useTile: true,
              iconColor: iconColor,
              textStyle: textStyle,
              onNavigator: onNavigator,
            );
          }
          if (value?.contains('post') ?? false) {
            return GeneralPostWidget(
              item: item,
              useTile: true,
              iconColor: iconColor,
              textStyle: textStyle,
              onNavigator: onNavigator,
            );
          }
          if (value?.contains('title') ?? false) {
            return GeneralTitleWidget(item: item);
          }
          if (value?.contains('button') ?? false) {
            return GeneralButtonWidget(
              item: item,
              onNavigator: onNavigator,
            );
          }
          if (value?.contains('product') ?? false) {
            return GeneralProductWidget(
              item: item,
              useTile: true,
              iconColor: iconColor,
              textStyle: textStyle,
              onNavigator: onNavigator,
            );
          }
          if (value?.contains('category') ?? false) {
            return GeneralCategoryWidget(
              item: item,
              useTile: true,
              iconColor: iconColor,
              textStyle: textStyle,
              onNavigator: onNavigator,
            );
          }
          if (value?.contains('banner') ?? false) {
            return GeneralBannerWidget(
              item: item,
              onNavigator: onNavigator,
            );
          }
          if (value?.contains('blogCategory') ?? false) {
            return GeneralBlogCategoryWidget(
              item: item,
              useTile: true,
              iconColor: iconColor,
              textStyle: textStyle,
              onNavigator: onNavigator,
            );
          }
          if (value?.contains('blog') ?? false) {
            return GeneralBlogWidget(
              item: item,
              useTile: true,
              iconColor: iconColor,
              textStyle: textStyle,
              onNavigator: onNavigator,
            );
          }
          if (value?.contains('screen') ?? false) {
            return GeneralScreenWidget(
              item: item,
              useTile: true,
              iconColor: iconColor,
              textStyle: textStyle,
              onNavigator: onNavigator,
            );
          }
        }

        return const SizedBox();
    }
  }

  Widget buildListCategory() {
    return Selector<CategoryModel, List<Category>?>(
      shouldRebuild: (previous, next) {
        return previous != next;
      },
      selector: (context, provider) => provider.categories,
      builder: (context, categories, child) {
        var widgets = <Widget>[];

        if (categories != null) {
          final list = categories.where((item) => item.isRoot).toList();
          for (var i = 0; i < list.length; i++) {
            final currentCategory = list[i];
            final childCategories = categories
                .where((o) => o.parent == currentCategory.id)
                .toList();
            final categoryName = currentCategory.name?.toUpperCase() ?? '';

            widgets.add(Container(
              color: i.isOdd
                  ? null
                  : Theme.of(context).colorScheme.secondary.withOpacity(0.1),

              /// Check to add only parent link category
              child: childCategories.isEmpty
                  ? InkWell(
                      onTap: () => navigateToBackDrop(currentCategory),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 20,
                          bottom: 12,
                          left: 16,
                          top: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(
                              categoryName,
                              style: textStyle,
                            )),
                            const SizedBox(width: 24),
                            currentCategory.totalProduct == null
                                ? const Icon(Icons.chevron_right)
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Text(
                                      S.of(context).nItems(
                                          currentCategory.totalProduct!),
                                      style: textStyle.copyWith(fontSize: 12),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    )
                  : ExpansionTile(
                      title: Padding(
                        padding: const EdgeInsets.only(left: 0.0, top: 0),
                        child: Text(
                          categoryName,
                          style: textStyle.copyWith(fontSize: 14),
                        ),
                      ),
                      iconColor: iconColor,
                      collapsedIconColor: textColor,
                      children: getChildren(
                              categories, currentCategory, childCategories)
                          as List<Widget>,
                    ),
            ));
          }
        }

        return ExpansionTile(
          initiallyExpanded: true,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          tilePadding: const EdgeInsets.only(left: 16, right: 8),
          title: Text(
            S.of(context).byCategory.toUpperCase(),
            style: textStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconColor: iconColor,
          collapsedIconColor: textColor,
          children: widgets,
        );
      },
    );
  }

  List getChildren(
    List<Category> categories,
    Category currentCategory,
    List<Category> childCategories, {
    double paddingOffset = 0.0,
  }) {
    var list = <Widget>[];
    final totalProduct = currentCategory.totalProduct;
    list.add(
      ListTile(
        leading: Padding(
          padding: EdgeInsets.only(left: 20 + paddingOffset),
          child: Text(
            S.of(context).seeAll,
            style: textStyle.copyWith(fontSize: 14),
          ),
        ),
        trailing: ((totalProduct != null && totalProduct > 0))
            ? Text(
                S.of(context).nItems(totalProduct),
                style: textStyle.copyWith(fontSize: 12),
              )
            : null,
        onTap: () => navigateToBackDrop(currentCategory),
      ),
    );
    for (var i in childCategories) {
      var newChildren = categories.where((cat) => cat.parent == i.id).toList();
      final name = i.name ?? '';

      if (newChildren.isNotEmpty) {
        list.add(
          ExpansionTile(
            title: Padding(
              padding: EdgeInsets.only(left: 20.0 + paddingOffset),
              child: Text(
                name.toUpperCase(),
                style: textStyle.copyWith(fontSize: 14),
              ),
            ),
            iconColor: iconColor,
            collapsedIconColor: textColor,
            children: getChildren(
              categories,
              i,
              newChildren,
              paddingOffset: paddingOffset + 10,
            ) as List<Widget>,
          ),
        );
      } else {
        final totalProduct = i.totalProduct;
        list.add(
          ListTile(
            title: Padding(
              padding: EdgeInsets.only(left: 20 + paddingOffset),
              child: Text(
                name,
                style: textStyle.copyWith(fontSize: 14),
              ),
            ),
            trailing: (totalProduct != null && totalProduct > 0)
                ? Text(
                    S.of(context).nItems(i.totalProduct!),
                    style: textStyle.copyWith(fontSize: 12),
                  )
                : null,
            onTap: () => navigateToBackDrop(i),
          ),
        );
      }
    }
    return list;
  }

  void navigateToBackDrop(Category category) {
    FluxNavigate.pushNamed(
      RouteList.backdrop,
      arguments: BackDropArguments(
        cateId: category.id,
        cateName: category.name,
      ),
      context: context,
    );
  }
}
