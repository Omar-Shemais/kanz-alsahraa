import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/env.dart';
import 'package:fstore/models/entities/country.dart';

void main() {
  group('Saudi Commerce Configuration (Problems 12 & 38)', () {
    test('shipping config produces a usable country and offline regions', () {
      final config = environment['defaultCountryShipping'].first as Map;
      final originalStates = config['states'] as List;
      final country = Country.fromShippingConfig(config);
      expect(country.id, 'SA');
      expect(country.code, 'SA');
      expect(country.states, hasLength(13));
      expect(country.states!.first.code, 'RIY');
      expect(country.states!.first.name, 'الرياض');
      expect(originalStates, hasLength(13));
      expect(originalStates.first, isA<Map>());
    });

    test('legacy iosCode config remains supported without mutating input', () {
      final regions = [
        {'code': 'TEST', 'name': 'Test region'}
      ];
      final country = Country.fromShippingConfig({
        'iosCode': 'SA',
        'name': 'Saudi Arabia',
        'states': regions,
      });
      expect(country.id, 'SA');
      expect(country.states!.single.code, 'TEST');
      expect(regions, hasLength(1));
      final emptyCountry = Country.fromShippingConfig({'iosCode': 'SA'});
      expect(emptyCountry.states, isEmpty);
    });
    test('verifies default country is Saudi Arabia', () {
      final paymentConfig =
          environment['paymentConfig'] as Map<String, dynamic>;
      expect(paymentConfig['DefaultCountryISOCode'], 'SA');
      expect(paymentConfig['DefaultStateISOCode'], 'RIY');
    });

    test('verifies shipping is restricted to Saudi Arabia', () {
      final advanceConfig =
          environment['advanceConfig'] as Map<String, dynamic>;
      expect(advanceConfig['supportCountriesShipping'], contains('SA'));
      expect(advanceConfig['supportCountriesShipping'].length, 1);
    });

    test('verifies default currency is SAR', () {
      final advanceConfig =
          environment['advanceConfig'] as Map<String, dynamic>;
      final defaultCurrency =
          advanceConfig['DefaultCurrency'] as Map<String, dynamic>;
      expect(defaultCurrency['currency'], 'SAR');
      expect(defaultCurrency['currencyCode'], 'SAR');
      expect(defaultCurrency['symbol'], 'ر.س');
    });

    test('verifies all 13 Saudi administrative regions are populated', () {
      final shippingList = environment['defaultCountryShipping'] as List;
      expect(shippingList, isNotEmpty);
      final saudiConfig = shippingList.first as Map<String, dynamic>;
      expect(saudiConfig['code'], 'SA');
      final states = saudiConfig['states'] as List;
      expect(states.length, 13);

      final stateCodes = states.map((s) => s['code']).toList();
      expect(
          stateCodes,
          containsAll([
            'RIY',
            'MAK',
            'MED',
            'EAS',
            'QAS',
            'ASI',
            'TAB',
            'HAI',
            'NOR',
            'JAZ',
            'NAJ',
            'BAH',
            'JOW'
          ]));
    });

    test('verifies phone number defaults to KSA (+966)', () {
      final phoneConfig =
          environment['phoneNumberConfig'] as Map<String, dynamic>;
      expect(phoneConfig['countryCodeDefault'], 'SA');
      expect(phoneConfig['dialCodeDefault'], '+966');
      expect(phoneConfig['customCountryList'], ['SA']);
    });
  });
}
