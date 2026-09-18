import 'dart:async';
import 'dart:convert' as convert;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../common/config.dart';
import '../common/config/models/index.dart';
import '../common/config/multi_site.dart';
import '../common/constants.dart';
import '../data/boxes.dart';
import '../modules/dynamic_layout/config/app_config.dart';
// import '../modules/salesiq_mobilisten/salesiq_services.dart';
import '../services/home_config_repository.dart';
import '../services/home_config_sources.dart';
import '../services/index.dart';
import '../services/remote_home_config.dart';
import 'advertisement/index.dart' show AdvertisementConfig;
import 'cart/cart_model.dart';
import 'category/category_model.dart';
import 'entities/currency.dart';
import 'filter_attribute_model.dart';
import 'product_wish_list_model.dart';
import 'recent_product_model.dart';
import 'user_model.dart';

class AppModel with ChangeNotifier {
  final HomeConfigRepository _homeConfigs;
  final Future<AppConfig> Function(String) _loadRemoteHome;
  final Future<String> Function(String) _loadHomeAsset;
  final String Function() _homeSource;
  HomeConfigScope? _homeScope;
  int _homeLoadGeneration = 0;
  bool _homeDisposed = false;
  Future<void>? _homeRefresh;
  int? _homeRefreshGeneration;
  HomeConfigOrigin? homeConfigOrigin;
  DateTime? homeConfigSavedAt;
  MultiSiteConfig? multiSiteConfig;
  AppConfig? appConfig;
  AdvertisementConfig advertisement = const AdvertisementConfig();
  Map? deeplink;
  late bool isMultivendor;

  /// Loading State setting
  bool isLoading = true;
  bool isInit = false;
  bool isOpenFloatMenu = false;

  /// Current and Payment settings
  String? currency;
  String? currencyCode;
  Map<String, dynamic> currencyRate = <String, dynamic>{};

  /// Language Code
  String _langCode = kAdvanceConfig.defaultLanguage;

  String get langCode => _langCode;

  /// Theming values for light or dark theme mode
  ThemeMode? themeMode;

  bool get darkTheme => themeMode == ThemeMode.dark;

  set darkTheme(bool value) =>
      themeMode = value ? ThemeMode.dark : ThemeMode.light;

  ThemeConfig get themeConfig => darkTheme ? kDarkConfig : kLightConfig;

  /// The app will use mainColor from env.dart,
  /// or override it with mainColor from config JSON if found.
  String get mainColor {
    final configJsonMainColor = appConfig?.settings.mainColor;
    if (configJsonMainColor != null && configJsonMainColor.isNotEmpty) {
      return configJsonMainColor;
    }
    return themeConfig.mainColor;
  }

  /// Product and Category Layout setting
  List<String>? categories;
  List<Map>? remapCategories;
  Map? categoriesIcons;
  String categoryLayout = '';
  String vendorLayout = '';

  String get productListLayout => appConfig!.settings.productListLayout;

  double get ratioProductImage =>
      appConfig!.settings.ratioProductImage ??
      (kAdvanceConfig.ratioProductImage * 1.0);

  String get productDetailLayout =>
      appConfig!.settings.productDetail ?? kProductDetail.layout;

  kBlogLayout get blogDetailLayout => appConfig!.settings.blogDetail != null
      ? kBlogLayout.values.byName(appConfig!.settings.blogDetail!)
      : kAdvanceConfig.detailedBlogLayout;

  String? get countryCode => SettingsBox().countryCode;

  /// App Model Constructor
  AppModel([String? lang]) : this.withHomeConfig(lang: lang);

  AppModel.withHomeConfig({
    String? lang,
    HomeConfigRepository? homeConfigs,
    Future<AppConfig> Function(String)? loadRemote,
    Future<String> Function(String)? loadAsset,
    String Function()? source,
  })  : _homeConfigs = homeConfigs ??
            HomeConfigRepository(
              read: (key) => SettingsBox().box.get(key),
              write: (key, value) => SettingsBox().box.put(key, value),
            ),
        _loadRemoteHome = loadRemote ?? loadRemoteHomeConfig,
        _loadHomeAsset = loadAsset ?? rootBundle.loadString,
        _homeSource = source ?? (() => kAppConfig) {
    _langCode = lang ?? _langCode;

    advertisement = AdvertisementConfig.fromJson(adConfig: kAdConfig);
    isMultivendor = ServerConfig().typeName.isMultiVendor;
  }

  void _updateAndSaveDefaultLanguage(String? lang) {
    if (!kAdvanceConfig.isMultiLanguages) {
      _langCode = kAdvanceConfig.defaultLanguage;
      SettingsBox().languageCode = _langCode;
      return;
    }
    final prefLang = SettingsBox().languageCode;
    _langCode =
        prefLang != null && prefLang.isNotEmpty ? prefLang : lang ?? _langCode;
    SettingsBox().languageCode = _langCode.split('-').first.toLowerCase();
  }

  /// Get persist config from Share Preference
  Future<bool> getPrefConfig({String? lang}) async {
    try {
      if (multiSiteConfig?.languageCode?.isEmpty ?? true) {
        _updateAndSaveDefaultLanguage(lang);
      }

      var defaultCurrency = kAdvanceConfig.defaultCurrency;

      darkTheme = SettingsBox().isDarkTheme ?? kDefaultDarkTheme;
      currency = SettingsBox().currency ?? defaultCurrency?.currencyDisplay;
      currencyCode =
          SettingsBox().currencyCode ?? defaultCurrency?.currencyCode;
      SettingsBox().countryCode = defaultCurrency?.countryCode;
      isInit = true;
      await updateTheme(darkTheme);

      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> changeLanguage(String languageCode, BuildContext context) async {
    try {
      if (!kAdvanceConfig.isMultiLanguages) {
        _langCode = kAdvanceConfig.defaultLanguage;
        SettingsBox().languageCode = _langCode;
        return true;
      }
      _langCode = languageCode;
      SettingsBox().languageCode = _langCode;

      await loadAppConfig(isSwitched: true);
      eventBus.fire(const EventChangeLanguage());
      unawaited(loadCurrency());

      final categoryModel = Provider.of<CategoryModel>(context, listen: false);
      categoryModel.refreshCategoryList();
      unawaited(categoryModel.getCategories(
        lang: _langCode,
        sortingList: categories,
        categoryLayout: categoryLayout,
        remapCategories: remapCategories,
      ));
      unawaited(Provider.of<FilterAttributeModel>(context, listen: false)
          .getFilterAttributes());

      return true;
    } catch (err) {
      return false;
    }
  }

  Currency? _getCurrencyByCode(String? code) {
    final currencies = kAdvanceConfig.currencies;
    return currencies.firstWhereOrNull(
        (e) => e.currencyCode.toLowerCase() == code?.toLowerCase());
  }

  Future<void> changeCurrency(
      BuildContext context, Currency newCurrency) async {
    try {
      final cartModel = Provider.of<CartModel>(context, listen: false);

      currency = newCurrency.currencyDisplay;
      currencyCode = newCurrency.currencyCode;
      SettingsBox().currencyCode = currencyCode;
      SettingsBox().currency = currency;
      SettingsBox().countryCode = newCurrency.countryCode;

      cartModel.changeCurrency(newCurrency.currencyCode);
      cartModel.updatePriceWhenCurrencyChanged();
      notifyListeners();
    } catch (error) {
      printLog('[changeCurrency] error: ${error.toString()}');
    }
  }

  Future<void> updateTheme(bool theme) async {
    try {
      darkTheme = theme;
      SettingsBox().isDarkTheme = theme;
      notifyListeners();
    } catch (error) {
      printLog('[updateTheme] error: ${error.toString()}');
    }
  }

  void loadStreamConfig(config) {
    if (_homeDisposed) return;
    _homeLoadGeneration++;
    _homeConfigs.invalidate();
    _homeScope = null;
    appConfig = AppConfig.fromJson(config);
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCloudAppConfig(String url) async {
    // Assignment is atomic: an invalid response cannot replace usable settings.
    final generation = _homeLoadGeneration;
    final next = await _loadRemoteHome(url);
    if (!_homeDisposed && generation == _homeLoadGeneration) {
      _adoptHomeConfig(next, HomeConfigOrigin.remote);
    }
  }

  Future<void> applyAppCaching() {
    if (_homeDisposed || isLoading || ServerConfig().isBuilder) {
      return Future.value();
    }
    final generation = _homeLoadGeneration;
    if (_homeRefresh != null && _homeRefreshGeneration == generation) {
      return _homeRefresh!;
    }
    final refresh = _refreshHomeConfig(generation);
    _homeRefresh = refresh;
    _homeRefreshGeneration = generation;
    return refresh.whenComplete(() {
      if (identical(_homeRefresh, refresh)) _homeRefresh = null;
    });
  }

  Future<void> _refreshHomeConfig(int generation) async {
    final scope = _homeScope;
    final language = langCode;
    final folder = multiSiteConfig?.configFolder;
    try {
      if (scope != null && isRemoteHomeSource(scope.source)) {
        final urls = homeRemoteUrls(
            source: scope.source, language: language, folder: folder);
        if (urls.isEmpty) return;
        final snapshot =
            await _homeConfigs.refresh(scope, loadRemote: () async {
          for (final url in urls) {
            try {
              return await _loadRemoteHome(url);
            } catch (_) {}
          }
          throw const FormatException('Remote home configuration unavailable.');
        });
        if (snapshot != null &&
            !_homeDisposed &&
            generation == _homeLoadGeneration &&
            language == langCode) {
          _adoptHomeConfig(snapshot.config, snapshot.origin,
              savedAt: snapshot.savedAt);
        }
        return;
      }
      // Preserve the legacy Woo layout hook, but never persist personalized data.
      var accepting = true;
      try {
        final operation =
            Services().widget.onLoadedAppConfig(language, (configCache) {
          if (accepting &&
              !_homeDisposed &&
              generation == _homeLoadGeneration &&
              language == langCode) {
            try {
              _adoptHomeConfig(
                  AppConfig.fromJson(configCache), HomeConfigOrigin.remote);
            } catch (_) {
              printLog('Home cache ignored: invalid layout.');
            }
          }
        });
        await (operation ?? Future<void>.value())
            .timeout(const Duration(seconds: 10));
      } finally {
        accepting = false;
      }
    } catch (_) {
      // The baseline remains visible; no raw server/config errors in the UI.
      printLog('Home refresh unavailable; keeping the usable local layout.');
    }
  }

  void _adoptHomeConfig(AppConfig next, HomeConfigOrigin origin,
      {DateTime? savedAt}) {
    if (_homeDisposed) return;
    // Keep active routes (especially checkout) intact during banner refresh.
    // The full remote TabBar remains in stored JSON for the next startup.
    if (appConfig != null) {
      final activeTabs = appConfig!.tabBar;
      for (final nextTab in next.tabBar) {
        final existingTab =
            activeTabs.firstWhereOrNull((e) => e.layout == nextTab.layout);
        if (existingTab != null) {
          existingTab.categories = nextTab.categories;
          existingTab.images = nextTab.images;
          existingTab.categoryLayout = nextTab.categoryLayout;
          existingTab.vendorLayout = nextTab.vendorLayout;
          existingTab.remapCategories = nextTab.remapCategories;
        }
      }
      next.tabBar = activeTabs;
    }
    appConfig = next;
    homeConfigOrigin = origin;
    homeConfigSavedAt = savedAt;
    _syncHomeNavigation();
    notifyListeners();
    eventBus.fire(const EventLoadedAppConfig());
  }

  void _syncHomeNavigation() {
    categories = null;
    remapCategories = null;
    categoriesIcons = null;
    categoryLayout = '';
    vendorLayout = '';
    final vendorTab =
        appConfig!.tabBar.firstWhereOrNull((e) => e.layout == 'vendors');
    final categoryTab =
        appConfig!.tabBar.firstWhereOrNull((e) => e.layout == 'category');
    if (vendorTab != null) {
      handleCategoryTab(vendorTab);
      vendorLayout = vendorTab.vendorLayout;
    } else if (categoryTab != null) {
      handleCategoryTab(categoryTab);
    }
    if (appConfig?.settings.tabBarConfig.alwaysShowTabBar != null) {
      Configurations().setAlwaysShowTabBar(
          appConfig?.settings.tabBarConfig.alwaysShowTabBar ?? false);
    }
  }

  void handleCategoryTab(TabBarMenuConfig categoryTab) {
    if (categoryTab.categories != null) {
      if (categoryTab.categories is Iterable) {
        categories = (categoryTab.categories as Iterable)
            .map((e) => e.toString())
            .toList();
      } else {
        categories = [categoryTab.categories.toString()];
      }
      if (ServerConfig().isShopify) {
        /// Support old type category (base64) work with new API
        /// Old type is base64, new type is url like gid://shopify/Collection/123456789
        categories = categories?.map(_parseShopifyCategories).toList();
      }
    }
    if (categoryTab.images != null) {
      categoriesIcons =
          categoryTab.images is Map ? Map.from(categoryTab.images) : null;
    }
    if (categoryTab.remapCategories != null) {
      remapCategories = categoryTab.remapCategories;

      /// Support old type category (base64) work with new API
      /// Old type is base64, new type is url like gid://shopify/Collection/123456789
      if (ServerConfig().isShopify) {
        remapCategories = remapCategories?.map((e) {
          for (var key in ['parent', 'category']) {
            if (e[key] != null) {
              e[key] = _parseShopifyCategories(e[key]);
            }
          }
          return e;
        }).toList();
      }
    }
    categoryLayout = categoryTab.categoryLayout;
  }

  Future<AppConfig?> loadAppConfig(
      {isSwitched = false, Map<String, dynamic>? config}) async {
    if (_homeDisposed) return null;
    final generation = ++_homeLoadGeneration;
    _homeConfigs.invalidate();
    _homeScope = null;
    isLoading = true;
    notifyListeners();

    var startTime = DateTime.now();

    if (_langCode == '') {
      _langCode = kAdvanceConfig.defaultLanguage;
    }

    try {
      if (!isInit || _langCode.isEmpty) {
        await getPrefConfig();
      }
      if (_homeDisposed || generation != _homeLoadGeneration) return null;

      if (config != null) {
        appConfig = AppConfig.fromJson(config);
        homeConfigOrigin = null;
        homeConfigSavedAt = null;
      } else {
        /// load config from Notion
        if (ServerConfig().type == ConfigType.notion) {
          final appCfg = await Services().widget.onGetAppConfig(langCode);

          if (appCfg != null) {
            appConfig = appCfg;
          }
        }

        await _loadConfigJson(generation);
      }
      if (_homeDisposed || generation != _homeLoadGeneration) return null;

      /// Load categories config for the Tabbar menu
      /// User to sort the category Setting
      /// Prefer loading category configuration from the first vendor tab

      _syncHomeNavigation();
      isLoading = false;

      notifyListeners();
      printLog('[Debug] Finish Load AppConfig', startTime);
      eventBus.fire(const EventLoadedAppConfig());
      if (config == null) unawaited(applyAppCaching());
      return appConfig;
    } catch (err, trace) {
      if (_homeDisposed || generation != _homeLoadGeneration) return null;
      printLog('🔴 AppConfig JSON loading error');
      printError(err, trace);
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadCurrency({Function(Map<String, dynamic>)? callback}) async {
    try {
      /// Load the Rate for Product Currency
      final rates = await Services().api.getCurrencyRate();
      if (rates != null) {
        currencyRate = rates;
        callback?.call(rates);
      }
    } catch (_) {}
  }

  void updateProductListLayout(layout) {
    appConfig!.settings =
        appConfig!.settings.copyWith(productListLayout: layout);
    notifyListeners();
  }

  void raiseNotify() {
    notifyListeners();
  }

  String _parseShopifyCategories(String categoryId) {
    try {
      return EncodeUtils.decode(categoryId);
    } on FormatException catch (_) {
      return categoryId;
    }
  }

  void setMainSiteConfig() {
    if (SettingsBox().isSelectedSiteConfig?.isNotEmpty ?? false) {
      multiSiteConfig = Configurations.multiSiteConfigs?.firstWhereOrNull(
          (e) => e.serverConfig?['url'] == SettingsBox().isSelectedSiteConfig);
    }

    multiSiteConfig ??= (Configurations.multiSiteConfigs?.isNotEmpty ?? false)
        ? Configurations.multiSiteConfigs!.first
        : null;
    SettingsBox().selectedSiteConfig = multiSiteConfig?.serverConfig?['url'];
    Configurations.serverConfig =
        multiSiteConfig?.serverConfig ?? Configurations.serverConfig;
    Services().setAppConfig(serverConfig);
    isMultivendor = ServerConfig().typeName.isMultiVendor;
    MultiSite.mainSiteUrl = Uri.parse(Configurations.mainSiteUrl);
    _updateAndSaveDefaultLanguage(multiSiteConfig?.languageCode);
  }

  Future changeSiteConfig(BuildContext context, MultiSiteConfig? config) async {
    if (multiSiteConfig?.name != config?.name) {
      try {
        await Provider.of<UserModel>(context, listen: false).logout();
        Provider.of<CartModel>(context, listen: false).clearCart();
        await Provider.of<ProductWishListModel>(context, listen: false)
            .clearWishList();
        Provider.of<RecentModel>(context, listen: false).cleanRecentProducts();
        UserBox().orders = []; //clear local orders when change site

        multiSiteConfig = config;
        SettingsBox().selectedSiteConfig =
            multiSiteConfig?.serverConfig?['url'];
        Configurations.serverConfig =
            multiSiteConfig?.serverConfig ?? Configurations.serverConfig;
        Services().setAppConfig(serverConfig);
        if (config?.currencyCode?.isNotEmpty ?? false) {
          var currency = _getCurrencyByCode(config!.currencyCode!);
          if (currency != null) {
            await changeCurrency(context, currency);
          }
        }
        isMultivendor = ServerConfig().typeName.isMultiVendor;
        await changeLanguage(config?.languageCode ?? _langCode, context);
      } catch (e) {
        rethrow;
      }
    }
  }

  Map? get overrideTranslation {
    final overrideLocale =
        appConfig?.overrideTranslation?['@@locale']?.toString() ?? '';
    if (overrideLocale.isEmpty ||
        overrideLocale.toLowerCase() != langCode.toLowerCase()) {
      return null;
    }

    return appConfig?.overrideTranslation;
  }

  Future<void> _loadConfigJson(int generation) async {
    final language = langCode;
    final folder = multiSiteConfig?.configFolder;
    final source = _homeSource();
    // A separate site identity prevents two folders at the same host sharing data.
    final isolatedScope = HomeConfigScope(
        site: convert.jsonEncode([ServerConfig().url, folder]),
        language: language,
        source: source);
    _homeScope = isolatedScope;
    final paths = homeBundlePaths(
        source: source,
        language: language,
        folder: folder,
        fallbackLanguage: multiSiteConfig?.languageCode);
    final snapshot = await _homeConfigs.loadBaseline(isolatedScope,
        loadBundle: () => loadBundledHomeConfig(paths, _loadHomeAsset));
    if (snapshot != null &&
        !_homeDisposed &&
        generation == _homeLoadGeneration &&
        language == langCode) {
      appConfig = snapshot.config;
      homeConfigOrigin = snapshot.origin;
      homeConfigSavedAt = snapshot.savedAt;
    }
  }

  @override
  void dispose() {
    _homeDisposed = true;
    _homeLoadGeneration++;
    _homeConfigs.dispose();
    super.dispose();
  }
}
