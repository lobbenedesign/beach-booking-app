import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/beach_model.dart';
import '../custom_painters.dart';
import 'map_element_catalog.dart';

/// Single source of truth for how a [MapElement] is drawn on the map.
///
/// Both the editor, the customer booking map and the operator's daily map use
/// this so the palette preview always matches the real object.
///
/// If a superadmin has registered a custom SVG for the element's type via
/// [MapElementCatalog.svgOverrides], that SVG is rendered instead of the
/// built-in painter — this is the hook for the replaceable graphics library.
Widget mapElementVisual(
  MapElement element, {
  double waveAnimationValue = 0.0,
  bool showUmbrellaLabel = true,
}) {
  // A per-element photo (set on this specific umbrella/table/etc. in the
  // editor's properties panel) is the most specific override and wins over
  // both the catalog SVG and the built-in painter.
  if (element.type != MapElementType.zone && element.iconImage != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.memory(
        base64Decode(element.iconImage!.split(',').last),
        fit: BoxFit.cover,
      ),
    );
  }

  // Superadmin SVG override wins for every non-area element.
  if (element.type != MapElementType.zone &&
      MapElementCatalog.hasSvg(element.type)) {
    return _svgVisual(element);
  }

  switch (element.type) {
    // Terrain
    case MapElementType.sand:
      return Container(color: element.color ?? const Color(0xFFE6C288));
    case MapElementType.sea:
      return CustomPaint(
        painter: WavePainter(
          color: element.color ?? const Color(0xFF90CAF9),
          animationValue: waveAnimationValue,
        ),
        size: Size.infinite,
      );
    case MapElementType.rock:
      return CustomPaint(painter: RockPainter(color: element.color ?? Colors.grey));
    case MapElementType.walkway:
      return CustomPaint(
          painter: WalkwayPainter(color: element.color ?? const Color(0xFF8D6E63)));
    case MapElementType.grass:
      return CustomPaint(painter: GrassPainter(color: element.color ?? Colors.green));

    // Rentals
    case MapElementType.umbrella:
      return _umbrella(element, showLabel: showUmbrellaLabel);
    case MapElementType.sunbed:
      return CustomPaint(painter: SunbedPainter(color: element.color ?? Colors.orange));
    case MapElementType.deckchair:
      return CustomPaint(painter: DeckchairPainter(color: element.color ?? Colors.orange));
    case MapElementType.pedalo:
      return CustomPaint(painter: PedaloPainter(color: element.color ?? Colors.cyan));
    case MapElementType.canoe:
      return CustomPaint(painter: CanoePainter(color: element.color ?? Colors.teal));
    case MapElementType.boat:
      return CustomPaint(painter: BoatPainter(color: element.color ?? Colors.blue));
    case MapElementType.surf:
      return CustomPaint(painter: SurfPainter(color: element.color ?? Colors.lightBlue));
    case MapElementType.windsurf:
      return CustomPaint(painter: WindsurfPainter(color: element.color ?? Colors.cyan));
    case MapElementType.bungalow:
      return CustomPaint(painter: BungalowPainter(color: element.color ?? Colors.brown));
    case MapElementType.pagoda:
      return CustomPaint(painter: PagodaPainter(color: element.color ?? Colors.red));
    case MapElementType.canopy:
      return CustomPaint(painter: CanopyPainter(color: element.color ?? Colors.blue));
    case MapElementType.kingSizeBed:
      return CustomPaint(painter: KingSizeBedPainter(color: element.color ?? Colors.white));

    // Facilities
    case MapElementType.bar:
      return CustomPaint(painter: BarPainter(color: element.color ?? Colors.brown));
    case MapElementType.restaurant:
      return CustomPaint(painter: RestaurantPainter(color: element.color ?? Colors.red));
    case MapElementType.lounge:
      return CustomPaint(painter: LoungePainter(color: element.color ?? Colors.indigo));
    case MapElementType.wc:
    case MapElementType.wcDisabled:
      return Icon(
        element.type == MapElementType.wcDisabled ? Icons.accessible : Icons.wc,
        color: element.color ?? Colors.blue,
        size: 30,
      );
    case MapElementType.playground:
      return CustomPaint(painter: PlaygroundPainter(color: element.color ?? Colors.orange));
    case MapElementType.lifeguardTower:
      return CustomPaint(painter: LifeguardTowerPainter(color: element.color ?? Colors.red));
    case MapElementType.lighthouse:
      return CustomPaint(painter: LighthousePainter(color: element.color ?? Colors.yellow));
    case MapElementType.ticketOffice:
      return CustomPaint(painter: TicketOfficePainter(color: element.color ?? Colors.purple));
    case MapElementType.kiosk:
      return CustomPaint(painter: KioskPainter(color: element.color ?? Colors.brown));
    case MapElementType.firstAid:
      return CustomPaint(painter: FirstAidPainter(color: element.color ?? Colors.white));

    // Infrastructure
    case MapElementType.dock:
      return CustomPaint(painter: DockPainter(color: element.color ?? Colors.blueGrey));
    case MapElementType.wall:
      return CustomPaint(painter: WallPainter(color: element.color ?? Colors.grey));
    case MapElementType.parking:
      return CustomPaint(painter: ParkingPainter(color: element.color ?? Colors.blue));
    case MapElementType.entrance:
      return CustomPaint(painter: EntrancePainter(color: element.color ?? Colors.green));

    // Decorations
    case MapElementType.palm:
      return CustomPaint(painter: PalmPainter(color: element.color ?? Colors.green));
    case MapElementType.plant:
      return CustomPaint(painter: PlantPainter(color: element.color ?? Colors.green));
    case MapElementType.flower:
      return CustomPaint(painter: FlowerPainter(color: element.color ?? Colors.pink));
    case MapElementType.bench:
      return CustomPaint(painter: BenchPainter(color: element.color ?? Colors.brown));

    // Structures
    case MapElementType.shower:
      return CustomPaint(painter: ShowerPainter(color: element.color ?? Colors.blueGrey));
    case MapElementType.cabin:
      return CustomPaint(painter: CabinPainter(color: element.color ?? Colors.blue));
    case MapElementType.gazebo:
      return CustomPaint(painter: GazeboPainter(color: element.color ?? Colors.brown));
    case MapElementType.umbrellaStand:
      return CustomPaint(
          painter: UmbrellaStandPainter(color: element.color ?? Colors.deepOrange));
    case MapElementType.fence:
      return CustomPaint(painter: FencePainter(color: element.color ?? Colors.brown));

    // Zones
    case MapElementType.zone:
      return CustomPaint(
        painter: ZonePainter(
          borderColor: element.borderColor ?? Colors.purple,
          borderWidth: element.borderWidth,
          fillColor: element.fillColor ?? Colors.purple.withOpacity(0.2),
          fillOpacity: element.fillOpacity,
          title: element.zoneTitle ?? element.label,
          customPath: element.customPath,
        ),
      );
  }
}

Widget _svgVisual(MapElement element) {
  final svg = MapElementCatalog.svgOverrides[element.type]!;
  return Padding(
    padding: const EdgeInsets.all(2),
    child: SvgPicture.string(
      svg,
      fit: BoxFit.contain,
      colorFilter: element.color != null
          ? ColorFilter.mode(element.color!, BlendMode.srcIn)
          : null,
    ),
  );
}

Widget _umbrella(MapElement element, {required bool showLabel}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(
        child: Icon(Icons.beach_access, color: element.color ?? Colors.red, size: 30),
      ),
      if (showLabel && (element.label != null || element.row != null))
        Container(
          padding: const EdgeInsets.all(2),
          color: Colors.white.withOpacity(0.8),
          child: Text(
            element.label ?? '${element.row}-${element.number}',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
    ],
  );
}
