import 'package:flutter/material.dart';
import '../../models/beach_model.dart';
import 'map_element_renderer.dart';

/// Central registry for map element metadata (label, section, colour, icon)
/// and the superadmin-replaceable SVG library.
///
/// The palette shows a live [preview] of each element (the real painter, or the
/// superadmin's SVG), so the icon in the palette always matches the object that
/// appears on the map.
class MapElementCatalog {
  MapElementCatalog._();

  /// Superadmin overrides: element type -> raw SVG markup.
  /// In-memory for the demo; a real backend would persist these.
  static final Map<MapElementType, String> svgOverrides = {};

  static bool hasSvg(MapElementType type) {
    final v = svgOverrides[type];
    return v != null && v.trim().isNotEmpty;
  }

  static void setSvg(MapElementType type, String svg) {
    if (svg.trim().isEmpty) {
      svgOverrides.remove(type);
    } else {
      svgOverrides[type] = svg;
    }
  }

  static void clearSvg(MapElementType type) => svgOverrides.remove(type);

  /// A live preview of the element as it will appear on the map.
  static Widget preview(MapElementType type, {double size = 40}) {
    final element = MapElement(
      id: 'preview',
      type: type,
      x: 0,
      y: 0,
      width: 0.05,
      height: 0.05,
      color: defaultColor(type),
    );
    return SizedBox(
      width: size,
      height: size,
      child: mapElementVisual(element, showUmbrellaLabel: false),
    );
  }

  static String label(MapElementType type) => switch (type) {
        MapElementType.sand => 'Sabbia',
        MapElementType.sea => 'Mare',
        MapElementType.rock => 'Scogli',
        MapElementType.walkway => 'Passerella',
        MapElementType.grass => 'Prato',
        MapElementType.wc => 'WC',
        MapElementType.wcDisabled => 'WC disabili',
        MapElementType.playground => 'Parco giochi',
        MapElementType.lifeguardTower => 'Torre bagnino',
        MapElementType.lighthouse => 'Faro',
        MapElementType.ticketOffice => 'Biglietteria',
        MapElementType.kiosk => 'Chiosco',
        MapElementType.bar => 'Bar',
        MapElementType.restaurant => 'Ristorante',
        MapElementType.lounge => 'Lounge',
        MapElementType.umbrella => 'Ombrellone',
        MapElementType.sunbed => 'Lettino',
        MapElementType.deckchair => 'Sdraio',
        MapElementType.pedalo => 'Pedalò',
        MapElementType.canoe => 'Canoa',
        MapElementType.boat => 'Barca',
        MapElementType.surf => 'Surf',
        MapElementType.windsurf => 'Windsurf',
        MapElementType.bungalow => 'Bungalow',
        MapElementType.pagoda => 'Pagoda',
        MapElementType.canopy => 'Tettoia',
        MapElementType.kingSizeBed => 'Letto King',
        MapElementType.dock => 'Molo',
        MapElementType.wall => 'Muro',
        MapElementType.palm => 'Palma',
        MapElementType.plant => 'Pianta',
        MapElementType.flower => 'Fiori',
        MapElementType.bench => 'Panchina',
        MapElementType.shower => 'Doccia',
        MapElementType.cabin => 'Cabina',
        MapElementType.gazebo => 'Gazebo',
        MapElementType.umbrellaStand => 'Portaombrelloni',
        MapElementType.fence => 'Recinzione',
        MapElementType.firstAid => 'Pronto soccorso',
        MapElementType.parking => 'Parcheggio',
        MapElementType.entrance => 'Ingresso',
        MapElementType.zone => 'Zona',
      };

  /// Fallback Material icon (used only where a live preview isn't practical,
  /// e.g. the SVG-library management list). Chosen to resemble the object.
  static IconData icon(MapElementType type) => switch (type) {
        MapElementType.sand => Icons.grain,
        MapElementType.sea => Icons.waves,
        MapElementType.rock => Icons.landscape,
        MapElementType.walkway => Icons.directions_walk,
        MapElementType.grass => Icons.grass,
        MapElementType.wc => Icons.wc,
        MapElementType.wcDisabled => Icons.accessible,
        MapElementType.playground => Icons.toys,
        MapElementType.lifeguardTower => Icons.tour,
        MapElementType.lighthouse => Icons.light_mode,
        MapElementType.ticketOffice => Icons.confirmation_number,
        MapElementType.kiosk => Icons.storefront,
        MapElementType.bar => Icons.local_bar,
        MapElementType.restaurant => Icons.restaurant,
        MapElementType.lounge => Icons.weekend,
        MapElementType.umbrella => Icons.beach_access,
        MapElementType.sunbed => Icons.airline_seat_flat,
        MapElementType.deckchair => Icons.deck,
        MapElementType.pedalo => Icons.pedal_bike,
        MapElementType.canoe => Icons.kayaking,
        MapElementType.boat => Icons.sailing,
        MapElementType.surf => Icons.surfing,
        MapElementType.windsurf => Icons.kitesurfing,
        MapElementType.bungalow => Icons.house,
        MapElementType.pagoda => Icons.temple_buddhist,
        MapElementType.canopy => Icons.roofing,
        MapElementType.kingSizeBed => Icons.king_bed,
        MapElementType.dock => Icons.anchor,
        MapElementType.wall => Icons.rectangle,
        MapElementType.palm => Icons.park,
        MapElementType.plant => Icons.local_florist,
        MapElementType.flower => Icons.yard,
        MapElementType.bench => Icons.chair_alt,
        MapElementType.shower => Icons.shower,
        MapElementType.cabin => Icons.meeting_room,
        MapElementType.gazebo => Icons.roofing,
        MapElementType.umbrellaStand => Icons.umbrella,
        MapElementType.fence => Icons.fence,
        MapElementType.firstAid => Icons.medical_services,
        MapElementType.parking => Icons.local_parking,
        MapElementType.entrance => Icons.login,
        MapElementType.zone => Icons.crop_square,
      };

  static Color defaultColor(MapElementType type) => switch (type) {
        MapElementType.sand => const Color(0xFFE6C288),
        MapElementType.sea => const Color(0xFF90CAF9),
        MapElementType.rock => Colors.grey,
        MapElementType.walkway => const Color(0xFF8D6E63),
        MapElementType.grass => Colors.green,
        MapElementType.wc => Colors.blue.shade700,
        MapElementType.wcDisabled => Colors.blue.shade700,
        MapElementType.playground => Colors.orange,
        MapElementType.lifeguardTower => Colors.red,
        MapElementType.lighthouse => Colors.yellow.shade700,
        MapElementType.ticketOffice => Colors.purple,
        MapElementType.kiosk => Colors.brown,
        MapElementType.bar => Colors.brown,
        MapElementType.restaurant => Colors.red.shade800,
        MapElementType.lounge => Colors.indigo,
        MapElementType.umbrella => Colors.red,
        MapElementType.sunbed => Colors.orange,
        MapElementType.deckchair => Colors.orange.shade800,
        MapElementType.pedalo => Colors.cyan.shade700,
        MapElementType.canoe => Colors.teal,
        MapElementType.boat => Colors.blue.shade800,
        MapElementType.surf => Colors.lightBlue,
        MapElementType.windsurf => Colors.cyan.shade800,
        MapElementType.bungalow => Colors.brown.shade700,
        MapElementType.pagoda => Colors.red.shade700,
        MapElementType.canopy => Colors.blue.shade600,
        MapElementType.kingSizeBed => Colors.blueGrey,
        MapElementType.dock => Colors.blueGrey.shade700,
        MapElementType.wall => Colors.grey.shade700,
        MapElementType.palm => Colors.green,
        MapElementType.plant => Colors.green.shade600,
        MapElementType.flower => Colors.pink.shade700,
        MapElementType.bench => Colors.brown.shade600,
        MapElementType.shower => Colors.lightBlue.shade700,
        MapElementType.cabin => Colors.brown.shade700,
        MapElementType.gazebo => Colors.brown.shade800,
        MapElementType.umbrellaStand => Colors.deepOrange,
        MapElementType.fence => Colors.brown.shade500,
        MapElementType.firstAid => Colors.red.shade700,
        MapElementType.parking => Colors.blue.shade900,
        MapElementType.entrance => Colors.green.shade800,
        MapElementType.zone => Colors.purple,
      };

  /// Ordered sections for the palette.
  static const Map<String, List<MapElementType>> sections = {
    'Terreno': [
      MapElementType.sand,
      MapElementType.sea,
      MapElementType.rock,
      MapElementType.walkway,
      MapElementType.grass,
    ],
    'Servizi': [
      MapElementType.bar,
      MapElementType.restaurant,
      MapElementType.lounge,
      MapElementType.wc,
      MapElementType.wcDisabled,
      MapElementType.firstAid,
      MapElementType.playground,
      MapElementType.kiosk,
      MapElementType.ticketOffice,
    ],
    'Sicurezza': [
      MapElementType.lifeguardTower,
      MapElementType.lighthouse,
    ],
    'Noleggi': [
      MapElementType.umbrella,
      MapElementType.sunbed,
      MapElementType.deckchair,
      MapElementType.pedalo,
      MapElementType.canoe,
      MapElementType.boat,
      MapElementType.surf,
      MapElementType.windsurf,
      MapElementType.bungalow,
      MapElementType.pagoda,
      MapElementType.canopy,
      MapElementType.kingSizeBed,
    ],
    'Infrastrutture': [
      MapElementType.dock,
      MapElementType.wall,
      MapElementType.parking,
      MapElementType.entrance,
    ],
    'Decorazioni': [
      MapElementType.palm,
      MapElementType.plant,
      MapElementType.flower,
      MapElementType.bench,
    ],
    'Strutture': [
      MapElementType.shower,
      MapElementType.cabin,
      MapElementType.gazebo,
      MapElementType.umbrellaStand,
      MapElementType.fence,
    ],
    'Aree': [
      MapElementType.zone,
    ],
  };
}
