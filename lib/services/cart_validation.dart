import '../models/cart/mixin/cart_mixin.dart';
import '../models/entities/product.dart';
import '../models/entities/product_variation.dart';

/// Only locally authored validation messages may bypass the generic UI error.
class CartValidationNotice {
  const CartValidationNotice(this.message);
  final String message;
}

class CartValidationLine {
  const CartValidationLine({
    required this.key,
    required this.product,
    required this.quantity,
    this.variation,
  });
  final String key;
  final Product product;
  final int quantity;
  final ProductVariation? variation;
}

class CartValidationResult {
  final Map<String, Product> products = {};
  final Map<String, ProductVariation> variations = {};
  final Set<String> issues = {};
  bool priceChanged = false;
  bool hasBullion = false;
  bool get canProceed => issues.isEmpty && !priceChanged;
  String get message => issues.isNotEmpty
      ? issues.join('\n')
      : 'تغير سعر بعض المنتجات. تم تحديث السلة؛ راجع الإجمالي ثم تابع الدفع.';
}

/// Read-only preflight. The server still must validate/reserve stock and price
/// atomically when creating the order; this is not a payment authority.
Future<CartValidationResult> validateWooCart({
  required List<CartValidationLine> lines,
  required Future<Product?> Function(String id) loadProduct,
  required Future<ProductVariation?> Function(String id, String variationId)
      loadVariation,
}) async {
  final result = CartValidationResult();
  if (lines.isEmpty) {
    result.issues.add('السلة فارغة. أضف المنتجات قبل المتابعة.');
    return result;
  }
  final loaded = <String, Product?>{};
  final variants = <String, ProductVariation?>{};
  final stockTotals = <String, int>{};
  final stockLimits = <String, int>{};
  final stockNames = <String, String>{};
  final productTotals = <String, int>{};
  for (final line in lines) {
    final id = line.product.id;
    final name = line.product.name ?? 'المنتج';
    if (id.isEmpty || line.quantity <= 0) {
      result.issues.add('راجع كمية $name في السلة.');
      continue;
    }
    if (!loaded.containsKey(id)) loaded[id] = await loadProduct(id);
    final product = loaded[id];
    if (product == null ||
        product.id != id ||
        product.status != 'publish' ||
        product.purchasable == false) {
      result.issues.add('$name لم يعد متاحاً للشراء. راجع السلة.');
      continue;
    }
    if (CartMixin.isBullionOrRestrictedProduct(product)) {
      result.hasBullion = true;
    }
    final oldVariation = line.variation;
    productTotals[id] = (productTotals[id] ?? 0) + line.quantity;
    final step = product.quantityStep;
    if (step != null && step > 0 && line.quantity % step != 0) {
      result.issues.add('راجع كمية $name؛ يجب اختيار مضاعفات $step.');
    }
    ProductVariation? variation;
    if (oldVariation != null) {
      final variationId = oldVariation.id;
      if (variationId == null ||
          !(product.variationIds?.contains(variationId) ?? false)) {
        result.issues
            .add('الخيار المحدد لـ$name لم يعد متاحاً. اختره من جديد.');
        continue;
      }
      final variantKey = '$id:$variationId';
      if (!variants.containsKey(variantKey)) {
        variants[variantKey] = await loadVariation(id, variationId);
      }
      variation = variants[variantKey];
      if (variation == null ||
          variation.id != variationId ||
          !variation.isActive) {
        result.issues.add('الخيار المحدد لـ$name لم يعد متاحاً للشراء.');
        continue;
      }
    } else if (product.isVariableProduct || product.type != line.product.type) {
      result.issues.add('تغيرت خيارات $name. افتح المنتج واختره من جديد.');
      continue;
    }
    final price = double.tryParse(variation?.price ?? product.price ?? '');
    if (price == null || !price.isFinite || price < 0) {
      result.issues.add('تعذر تأكيد سعر $name. أعد المحاولة لاحقاً.');
      continue;
    }
    final oldPrice =
        double.tryParse(oldVariation?.price ?? line.product.price ?? '');
    if (oldPrice == null || oldPrice != price) result.priceChanged = true;
    result.products[id] = product;
    if (variation != null) result.variations[line.key] = variation;

    final parentStock = variation == null || variation.stockManagedByParent;
    final inStock = parentStock ? product.inStock : variation.inStock;
    final backorders = parentStock
        ? product.backordersAllowed
        : variation.backordersAllowed == true;
    if (inStock != true && !backorders) {
      result.issues
          .add('$name غير متوفر حالياً بالخيارات المطلوبة. راجع السلة.');
    }
    final managed = parentStock ? product.manageStock : variation.manageStock;
    final quantity =
        parentStock ? product.stockQuantity : variation.stockQuantity;
    if (managed && !backorders) {
      if (quantity == null) {
        result.issues.add('تعذر تأكيد الكمية المتاحة لـ$name. أعد المحاولة.');
      } else {
        final stockKey = parentStock ? id : '$id:${variation.id}';
        stockTotals[stockKey] = (stockTotals[stockKey] ?? 0) + line.quantity;
        stockLimits[stockKey] = quantity;
        stockNames[stockKey] = name;
      }
    }
  }
  for (final key in stockTotals.keys) {
    if (stockTotals[key]! > stockLimits[key]!) {
      result.issues.add(
          'الكمية المطلوبة لـ${stockNames[key]} أكبر من المتاح. عدّل السلة.');
    }
  }
  for (final entry in productTotals.entries) {
    final product = loaded[entry.key]!;
    if ((product.minQuantity != null && entry.value < product.minQuantity!) ||
        (product.maxQuantity != null && entry.value > product.maxQuantity!)) {
      result.issues.add(
          'كمية ${product.name ?? 'المنتج'} لا توافق حدود الشراء الحالية. عدّل السلة.');
    }
  }
  return result;
}
