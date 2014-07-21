library hammock_mapper;

import 'dart:mirrors';
import 'package:hammock/hammock_core.dart';

part 'src/reflection_utils.dart';
part 'src/instantiators.dart';
part 'src/hammock_config.dart';
part 'src/meta.dart';
part 'src/interfaces.dart';
part 'src/mappers.dart';

_default(obj, defaultValue) =>
    obj == null ? defaultValue : obj;