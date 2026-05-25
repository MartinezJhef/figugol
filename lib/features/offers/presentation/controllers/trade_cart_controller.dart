import 'package:flutter/foundation.dart';

import '../../../stickers/data/models/sticker.dart';

class TradeCartItem {
  const TradeCartItem({required this.sticker, required this.quantity});

  final Sticker sticker;
  final int quantity;

  TradeCartItem copyWith({int? quantity}) {
    return TradeCartItem(sticker: sticker, quantity: quantity ?? this.quantity);
  }
}

class TradeCartController extends ChangeNotifier {
  static const minimumItemsToPublish = 6;

  final Map<String, TradeCartItem> _items = {};
  String? _validationMessage;

  List<TradeCartItem> get items => _items.values.toList(growable: false);
  String? get validationMessage => _validationMessage;
  int get totalItems =>
      _items.values.fold(0, (total, item) => total + item.quantity);
  bool get canPublish => totalItems >= minimumItemsToPublish;

  int quantityFor(String stickerId) => _items[stickerId]?.quantity ?? 0;

  bool canAddSticker({required String stickerId, required int ownedQuantity}) {
    return ownedQuantity > 1 && quantityFor(stickerId) < ownedQuantity - 1;
  }

  void addSticker({required Sticker sticker, required int ownedQuantity}) {
    if (ownedQuantity <= 1) {
      _validationMessage =
          'Solo puedes agregar figuritas repetidas al intercambio.';
      notifyListeners();
      return;
    }

    final currentQuantity = quantityFor(sticker.id);
    final maxOfferQuantity = ownedQuantity - 1;

    if (currentQuantity >= maxOfferQuantity) {
      _validationMessage =
          'Debes conservar al menos 1 unidad para tu colección.';
      notifyListeners();
      return;
    }

    _items[sticker.id] = TradeCartItem(
      sticker: sticker,
      quantity: currentQuantity + 1,
    );
    _validationMessage = null;
    notifyListeners();
  }

  void removeOne(String stickerId) {
    final currentItem = _items[stickerId];
    if (currentItem == null) {
      return;
    }

    if (currentItem.quantity <= 1) {
      _items.remove(stickerId);
    } else {
      _items[stickerId] = currentItem.copyWith(
        quantity: currentItem.quantity - 1,
      );
    }

    notifyListeners();
  }

  void removeSticker(String stickerId) {
    _items.remove(stickerId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _validationMessage = null;
    notifyListeners();
  }

  void validateForPublish() {
    if (canPublish) {
      _validationMessage = null;
    } else {
      _validationMessage =
          'Debes seleccionar mínimo 6 figuritas para publicar una oferta.';
    }
    notifyListeners();
  }

  void clearValidationMessage() {
    _validationMessage = null;
    notifyListeners();
  }
}
