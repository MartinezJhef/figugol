import 'package:home_widget/home_widget.dart';
import '../../features/stickers/data/repositories/stickers_repository.dart';
import '../../features/stickers/data/sources/full_catalog.dart';

class WidgetService {
  static const String androidWidgetName = 'WorldCupWidgetProvider';

  final StickersRepository _stickersRepository = StickersRepository();

  Future<void> updateAlbumStatsWidget(String? userId) async {
    if (userId == null) return;
    
    try {
      // Get the current user stickers
      final userStickersMap = await _stickersRepository.watchUserStickers(userId).first;
      final userStickers = userStickersMap.values;
      
      int uniqueOwned = 0;
      int duplicatesCount = 0;
      
      for (final sticker in userStickers) {
        if (sticker.quantity > 0) {
          uniqueOwned++;
          if (sticker.quantity > 1) {
            duplicatesCount += (sticker.quantity - 1);
          }
        }
      }
      
      final missingCount = fullStickerCatalog.length - uniqueOwned;
      
      final missingText = missingCount > 0 
          ? '¡Te faltan solo $missingCount figuritas para llenar el álbum! 🚀'
          : '¡Has completado tu álbum! 🏆';
          
      final duplicatesText = duplicatesCount > 0 
          ? 'Tienes $duplicatesCount repetidas nuevas. ¡Entra a intercambiarlas! 🔄'
          : '¡No tienes repetidas! Sigue abriendo sobres 🌟';

      // Save data to the widget
      await HomeWidget.saveWidgetData<String>('missing_text', missingText);
      await HomeWidget.saveWidgetData<String>('duplicates_text', duplicatesText);
      
      // Trigger update for the Android Widget
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
      );
    } catch (e) {
      // Ignore errors for widget updating
    }
  }

  Future<void> requestPin(String? userId) async {
    // Ensure we have the latest data before pinning
    await updateAlbumStatsWidget(userId);
    
    // Request Android to pin the widget to the home screen
    await HomeWidget.requestPinWidget(
      name: androidWidgetName,
      androidName: androidWidgetName,
    );
  }
}
