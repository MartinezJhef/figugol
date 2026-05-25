import 'package:figugol/features/offers/data/repositories/trade_offers_repository.dart';
import 'package:figugol/features/stickers/data/sources/demo_sticker_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses consecutive country catalog codes', () {
    final mexicoCodes = demoStickerCatalog
        .where((sticker) => sticker.team == 'Mexico')
        .take(2)
        .map((sticker) => sticker.catalogCode)
        .toList();
    final uruguayCodes = demoStickerCatalog
        .where((sticker) => RegExp(r'^uruguay-\d').hasMatch(sticker.id))
        .take(2)
        .map((sticker) => sticker.catalogCode)
        .toList();
    final uruguayShield = demoStickerCatalog.firstWhere(
      (sticker) => sticker.id == 'uruguay-logo',
    );

    expect(mexicoCodes, ['MEX-01', 'MEX-02']);
    expect(uruguayCodes, ['URU-01', 'URU-02']);
    expect(uruguayShield.catalogCode, 'URU-ESC');
  });

  test('offers use a one hundred kilometer visible radius', () {
    expect(TradeOffersRepository.maximumVisibleDistanceKm, 100);
  });
}
