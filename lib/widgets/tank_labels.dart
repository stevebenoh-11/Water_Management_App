import 'package:flutter/material.dart';

import '../models/tank_profile.dart';
import '../models/user_settings.dart';

/// Strings-file keys and icons for tank / area enums.
String tankTypeKey(TankType t) => 'tankType_${t.name}';
String tankMaterialKey(TankMaterial m) => 'material_${m.name}';
String tankShapeKey(TankShape s) => 'shape_${s.name}';
String areaKey(AreaType a) => 'area_${a.name}';

IconData materialIcon(TankMaterial m) => switch (m) {
      TankMaterial.plastic => Icons.local_drink_outlined,
      TankMaterial.concrete => Icons.foundation,
      TankMaterial.stainlessSteel => Icons.kitchen_outlined,
      TankMaterial.galvanisedIron => Icons.hardware_outlined,
      TankMaterial.ferroCement => Icons.layers_outlined,
      TankMaterial.brick => Icons.grid_view,
      TankMaterial.other => Icons.propane_tank_outlined,
    };

IconData areaIcon(AreaType a) => switch (a) {
      AreaType.city => Icons.location_city,
      AreaType.town => Icons.holiday_village_outlined,
      AreaType.village => Icons.agriculture_outlined,
    };
