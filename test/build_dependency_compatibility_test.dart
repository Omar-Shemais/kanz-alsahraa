import 'package:flutter_test/flutter_test.dart';
import '../tools/prepare_build_dependencies.dart';

void main() {
  test('only the known Flare hash expression is replaced and is repeatable',
      () {
    const original = 'int get hashCode => hashValues(bundle, name);';
    final fixed = compatibleFlareSource(original);
    expect(fixed, 'int get hashCode => Object.hash(bundle, name);');
    expect(compatibleFlareSource(fixed), fixed);
  });
  test('unexpected source fails rather than applying a broad cache patch', () {
    expect(() => compatibleFlareSource('different upstream implementation'),
        throwsStateError);
    expect(
        () => compatibleFlareSource(
            'int get hashCode => hashValues(bundle, name);\nint get hashCode => hashValues(bundle, name);'),
        throwsStateError);
  });
}
