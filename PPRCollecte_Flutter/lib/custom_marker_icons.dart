// custom_marker_icons.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class CustomMarkerIcons {
  // Cache pour stocker les icônes déjà générées
  static final Map<String, BitmapDescriptor> _iconCache = {};

  // Configuration des icônes
  static final Map<String, MarkerIconConfig> iconConfig = {
    'localites': MarkerIconConfig(
      icon: Icons.home,
      color: Color(0xFFE67E22), // Orange
    ),
    'ecoles': MarkerIconConfig(
      icon: Icons.school,
      color: Color(0xFF27AE60), // Vert
    ),
    'marches': MarkerIconConfig(
      icon: Icons.shopping_cart,
      color: Color(0xFFF1C40F), // Jaune
    ),
    'services_santes': MarkerIconConfig(
      icon: Icons.local_hospital,
      color: Color(0xFFE74C3C), // Rouge
    ),
    'batiments_administratifs': MarkerIconConfig(
      icon: Icons.business,
      color: Color(0xFF34495E), // Gris foncé
    ),
    'infrastructures_hydrauliques': MarkerIconConfig(
      icon: Icons.water_drop,
      color: Color(0xFF3498DB), // Bleu
    ),
    'autres_infrastructures': MarkerIconConfig(
      icon: Icons.location_pin,
      color: Color(0xFF95A5A6), // Gris
    ),
    'ponts': MarkerIconConfig(
      icon: Icons.account_balance,
      color: Color(0xFF9B59B6), // Violet
    ),
    'buses': MarkerIconConfig(
      icon: Icons.circle,
      color: Color(0xFF7F8C8D), // Gris moyen
    ),
    'dalots': MarkerIconConfig(
      icon: Icons.water,
      color: Color(0xFF3498DB), // Bleu
    ),
    'points_critiques': MarkerIconConfig(
      icon: Icons.warning,
      color: Color(0xFFD35400), // Orange foncé
    ),
    'points_coupures': MarkerIconConfig(
      icon: Icons.close,
      color: Color(0xFFC0392B), // Rouge foncé
    ),
  };

  // Méthode principale pour obtenir une icône (avec cache)
  static Future<BitmapDescriptor> getIconForTable(
    String tableName, {
    double size = 70.0,
    bool forceRefresh = false,
  }) async {
    final config = iconConfig[tableName];

    // Si pas de configuration, retourner une couleur par défaut
    if (config == null) {
      return _getDefaultIconForTable(tableName);
    }

    // Clé unique pour le cache
    final cacheKey = '${tableName}_${config.color.value}_$size';

    // Vérifier le cache (sauf si forceRefresh)
    if (!forceRefresh && _iconCache.containsKey(cacheKey)) {
      print('📦 [ICON CACHE] Utilisation du cache pour $tableName');
      return _iconCache[cacheKey]!;
    }

    print('🎨 [ICON CACHE] Génération d\'icône pour $tableName');

    // Générer la nouvelle icône
    final icon = await _createCustomIcon(
      config.icon,
      config.color,
      size: size,
    );

    // Mettre en cache
    _iconCache[cacheKey] = icon;

    return icon;
  }

  // Méthode pour créer une icône personnalisée
  static Future<BitmapDescriptor> _createCustomIcon(
    IconData iconData,
    Color backgroundColor, {
    double size = 70.0,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Taille du cercle de fond
    final double circleSize = size;
    final double iconSize = size * 0.8;

    // Dessiner le cercle de fond
    final Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(circleSize / 2, circleSize / 2),
      circleSize / 2,
      backgroundPaint,
    );

    // Ajouter une bordure blanche
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(
      Offset(circleSize / 2, circleSize / 2),
      circleSize / 2 - 1.5,
      borderPaint,
    );

    // Ajouter une ombre portée
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawCircle(
      Offset(circleSize / 2 + 1, circleSize / 2 + 1),
      circleSize / 2 - 1.5,
      shadowPaint,
    );

    // Dessiner l'icône
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final iconText = String.fromCharCode(iconData.codePoint);
    textPainter.text = TextSpan(
      text: iconText,
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 2,
            offset: Offset(1, 1),
          ),
        ],
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (circleSize - textPainter.width) / 2,
        (circleSize - textPainter.height) / 2,
      ),
    );

    // Convertir en image
    final ui.Image image = await pictureRecorder.endRecording().toImage(
          circleSize.toInt(),
          circleSize.toInt(),
        );

    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  // Icône par défaut basée sur la table
  static Future<BitmapDescriptor> _getDefaultIconForTable(String tableName) async {
    const defaultSize = 70.0;
    final cacheKey = 'default_$tableName';

    if (_iconCache.containsKey(cacheKey)) {
      return _iconCache[cacheKey]!;
    }

    final double hue = _getMarkerHueForTable(tableName);
    final icon = BitmapDescriptor.defaultMarkerWithHue(hue);

    _iconCache[cacheKey] = icon;
    return icon;
  }

  // Méthode pour nettoyer le cache si nécessaire
  static void clearCache() {
    print('🗑️ [ICON CACHE] Nettoyage du cache (${_iconCache.length} icônes)');
    _iconCache.clear();
  }

  // Méthode pour obtenir le nombre d'éléments en cache
  static int getCacheSize() {
    return _iconCache.length;
  }

  // Fallback pour les couleurs par défaut
  static double _getMarkerHueForTable(String tableName) {
    switch (tableName) {
      case 'localites':
        return BitmapDescriptor.hueBlue; // Bleu
      case 'ecoles':
        return BitmapDescriptor.hueGreen; // Vert
      case 'marches':
        return BitmapDescriptor.hueYellow; // Jaune
      case 'services_santes':
        return BitmapDescriptor.hueCyan; // Cyan
      case 'batiments_administratifs':
        return BitmapDescriptor.hueOrange; // Orange
      case 'infrastructures_hydrauliques':
        return BitmapDescriptor.hueAzure; // Bleu clair
      case 'autres_infrastructures':
        return BitmapDescriptor.hueViolet; // Violet
      case 'ponts':
        return BitmapDescriptor.hueBlue; // Bleu
      case 'buses':
        return BitmapDescriptor.hueGreen; // Vert
      case 'dalots':
        return BitmapDescriptor.hueMagenta; // Magenta froid
      case 'points_critiques':
        return BitmapDescriptor.hueCyan; // Bleu ciel
      case 'points_coupures':
        return BitmapDescriptor.hueYellow; // Jaune clair
      default:
        return BitmapDescriptor.hueAzure; // Couleur par défaut
    }
  }
}

class MarkerIconConfig {
  final IconData icon;
  final Color color;

  MarkerIconConfig({
    required this.icon,
    required this.color,
  });
}
