import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/connectivity_service.dart';
import '../models/sticker_stats.dart';
import '../models/user_sticker.dart';
import '../sources/demo_sticker_catalog.dart';

class StickersRepository {
  StickersRepository({
    FirebaseFirestore? firestore,
    ConnectivityService? connectivityService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _connectivityService =
           connectivityService ?? const ConnectivityService();

  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivityService;

  static final Map<String, UserSticker> _localMockStickers = {};
  static Map<String, UserSticker> get localMockStickers => _localMockStickers;
  static final StreamController<Map<String, UserSticker>> _localStickersController =
      StreamController<Map<String, UserSticker>>.broadcast();

  Stream<Map<String, UserSticker>> watchUserStickers(String userId) {
    if (userId == 'invitado_local') {
      final controller = StreamController<Map<String, UserSticker>>();
      controller.add(Map<String, UserSticker>.from(_localMockStickers));
      final subscription = _localStickersController.stream.listen((data) {
        controller.add(data);
      });
      controller.onCancel = () {
        subscription.cancel();
        controller.close();
      };
      return controller.stream;
    }
    return _userStickers(userId).snapshots().map((snapshot) {
      return {
        for (final document in snapshot.docs)
          document.id: UserSticker.fromJson(document.data()),
      };
    });
  }

  Future<void> saveUserSticker(UserSticker userSticker) async {
    if (userSticker.userId == 'invitado_local') {
      _localMockStickers[userSticker.stickerId] = userSticker;
      _localStickersController.add(Map<String, UserSticker>.from(_localMockStickers));
      return;
    }

    await _connectivityService.ensureInternetConnection(
      action: ImportantNetworkAction.saveStickers,
    );

    final collectionRef = _firestore
        .collection('sticker_collections')
        .doc(userSticker.userId);
    final updatedAt = Timestamp.fromDate(userSticker.updatedAt);
    final batch = _firestore.batch();

    batch.set(collectionRef, {
      'userId': userSticker.userId,
      'collectionId': demoCollectionId,
      'updatedAt': updatedAt,
    }, SetOptions(merge: true));
    batch.set(
      collectionRef.collection('stickers').doc(userSticker.stickerId),
      userSticker.toJson(),
    );

    await batch.commit();
  }

  Stream<StickerStats> watchStickerStats(String userId) {
    return watchUserStickers(userId).map((stickers) {
      var owned = 0;
      var duplicates = 0;
      var missing = 0;

      for (final sticker in demoStickerCatalog) {
        final quantity = stickers[sticker.id]?.quantity ?? 0;
        if (quantity > 0) {
          owned++;
        } else {
          missing++;
        }
        if (quantity > 1) {
          duplicates += quantity - 1;
        }
      }

      return StickerStats(
        owned: owned,
        duplicates: duplicates,
        missing: missing,
      );
    });
  }

  CollectionReference<Map<String, dynamic>> _userStickers(String userId) {
    return _firestore
        .collection('sticker_collections')
        .doc(userId)
        .collection('stickers');
  }
}
