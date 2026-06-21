import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/connectivity_service.dart';
import '../models/sticker.dart';
import '../models/sticker_stats.dart';
import '../models/user_sticker.dart';
import '../sources/full_catalog.dart';

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

  Stream<List<Sticker>> watchCatalog() {
    return _firestore.collection('stickers').orderBy('number').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Fallback to local catalog if Firestore is empty (or for local testing)
        return fullStickerCatalog;
      }
      return snapshot.docs.map((doc) => Sticker.fromJson(doc.data())).toList();
    });
  }

  Future<void> seedDatabase() async {
    final collectionRef = _firestore.collection('stickers');
    final batch = _firestore.batch();
    for (final sticker in fullStickerCatalog) {
      final docRef = collectionRef.doc(sticker.id);
      batch.set(docRef, sticker.toJson());
    }
    await batch.commit();
  }

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
      'collectionId': defaultCollectionId,
      'updatedAt': updatedAt,
    }, SetOptions(merge: true));
    batch.set(
      collectionRef.collection('stickers').doc(userSticker.stickerId),
      userSticker.toJson(),
    );

    await batch.commit();
  }

  Stream<StickerStats> watchStickerStats(String userId) {
    return watchUserStickers(userId).map((userStickers) {
      var owned = 0;
      var duplicates = 0;
      var missing = 0;

      // Note: In a real app, you might want to fetch the real catalog length, 
      // but for simplicity we assume the full catalog length.
      for (final sticker in fullStickerCatalog) {
        final userSticker = userStickers[sticker.id];
        final quantity = userSticker?.quantity ?? 0;
        final isPasted = userSticker?.isPasted ?? false;

        if (isPasted) {
          owned++;
        } else {
          missing++;
        }
        
        if (quantity > 0) {
          duplicates++;
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

  Future<void> executeDirectExchange({
    required String fromUserId,
    required String toUserId,
    required List<String> fromUserGivesIds,
    required List<String> toUserGivesIds,
  }) async {
    if (fromUserId == 'invitado_local' || toUserId == 'invitado_local') {
      return;
    }

    await _connectivityService.ensureInternetConnection(
      action: ImportantNetworkAction.saveStickers,
    );

    final fromCollection = _userStickers(fromUserId);
    final toCollection = _userStickers(toUserId);

    await _firestore.runTransaction((transaction) async {
      final now = Timestamp.now();
      
      // 1. Process fromUserGivesIds (fromUserId loses duplicate, toUserId gains pasted)
      for (final stickerId in fromUserGivesIds) {
        final fromSnap = await transaction.get(fromCollection.doc(stickerId));
        final fromData = fromSnap.data() ?? {};
        final fromQty = fromData['quantity'] as int? ?? 0;
        final fromPasted = fromData['isPasted'] as bool? ?? false;
        
        if (fromQty < 1) {
          throw Exception('No tienes suficientes repetidas para intercambiar.');
        }

        transaction.set(fromCollection.doc(stickerId), {
          'userId': fromUserId,
          'stickerId': stickerId,
          'quantity': fromQty - 1,
          'isPasted': fromPasted,
          'updatedAt': now,
        });

        final toSnap = await transaction.get(toCollection.doc(stickerId));
        final toData = toSnap.data() ?? {};
        final toQty = toData['quantity'] as int? ?? 0;

        transaction.set(toCollection.doc(stickerId), {
          'userId': toUserId,
          'stickerId': stickerId,
          'quantity': toQty,
          'isPasted': true,
          'updatedAt': now,
        });
      }

      // 2. Process toUserGivesIds (toUserId loses duplicate, fromUserId gains pasted)
      for (final stickerId in toUserGivesIds) {
        final toSnap = await transaction.get(toCollection.doc(stickerId));
        final toData = toSnap.data() ?? {};
        final toQty = toData['quantity'] as int? ?? 0;
        final toPasted = toData['isPasted'] as bool? ?? false;

        if (toQty < 1) {
          throw Exception('El otro usuario no tiene suficientes repetidas.');
        }

        transaction.set(toCollection.doc(stickerId), {
          'userId': toUserId,
          'stickerId': stickerId,
          'quantity': toQty - 1,
          'isPasted': toPasted,
          'updatedAt': now,
        });

        final fromSnap = await transaction.get(fromCollection.doc(stickerId));
        final fromData = fromSnap.data() ?? {};
        final fromQty = fromData['quantity'] as int? ?? 0;

        transaction.set(fromCollection.doc(stickerId), {
          'userId': fromUserId,
          'stickerId': stickerId,
          'quantity': fromQty,
          'isPasted': true,
          'updatedAt': now,
        });
      }
      
      // Update top level timestamps
      transaction.set(_firestore.collection('sticker_collections').doc(fromUserId), {
        'userId': fromUserId,
        'collectionId': defaultCollectionId,
        'updatedAt': now,
      }, SetOptions(merge: true));
      
      transaction.set(_firestore.collection('sticker_collections').doc(toUserId), {
        'userId': toUserId,
        'collectionId': defaultCollectionId,
        'updatedAt': now,
      }, SetOptions(merge: true));
    });
  }
}
