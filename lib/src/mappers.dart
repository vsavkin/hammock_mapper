part of hammock_mapper;

Field _findField(ClassMirror cm, Symbol fieldName) {
  final d = cm.declarations[fieldName];
  if (d == null) return null;
  return d.metadata.map((m) => m.reflectee).firstWhere((m) => m is Field, orElse: () => null);
}

class _FieldInfo {
  ClassMirror cm;
  Symbol fieldName;
  Field field;
  var accessor;

  _FieldInfo.getter(this.cm, this.accessor) {
    fieldName = this.accessor.simpleName;
    field = _findField(cm, fieldName);
  }

  _FieldInfo.setter(this.cm, this.accessor) {
    var name = MirrorSystem.getName(accessor.simpleName);
    fieldName = new Symbol(name.substring(0, name.length - 1));
    field = _findField(cm, fieldName);
  }

  bool get reserved => fieldName == #hashCode || fieldName == #runtimeType;
  bool get skip => field == null ? false : field.skip;
  bool get readOnly => field == null ? false : field.readOnly;
  bool get synthetic => accessor.isSynthetic;
  bool get hasFieldAnnotation => field != null;

  String get mappedName => field == null ? null : field.name;
  Mapper get mapper => field == null ? null : field.mapper;

  get setterTypeMirror => accessor.parameters.first.type;
}

class _MappableObjectToData {
  final Mappers ms;
  final obj;

  Type type;
  ClassMirror cm;
  InstanceMirror im;

  _MappableObjectToData(this.ms, this.obj) {
    type = obj.runtimeType;
    cm  = reflectClass(type);
    im  = reflect(obj);
  }

  call() {
    return publicFields.fold({}, (Map data, _FieldInfo f) {
      final name = mappedFieldName(f);
      final value = im.getField(f.fieldName).reflectee;
      data[name] = toData(f, value);
      return data;
    });
  }

  get publicFields => cm.instanceMembers.values
      .where((m) => m.isGetter && !m.isPrivate)
      .map((m) => new _FieldInfo.getter(cm, m))
      .where((f) => f.synthetic || f.hasFieldAnnotation)
      .where((f) => !f.reserved && !f.skip);

  String mappedFieldName(_FieldInfo f) {
    if (f.mappedName != null) {
       return f.mappedName;
    } else {
      return MirrorSystem.getName(f.fieldName);
    }
  }

  toData(_FieldInfo f, value) {
    if (f.mapper != null) {
      return f.mapper.toData(value);
    } else {
      return ms.toData(value);
    }
  }
}


class _UpdateMappableObject {
  Mappers ms;
  var obj;
  dynamic data;
  Type type;

  ClassMirror cm;
  InstanceMirror im;

  _UpdateMappableObject(this.ms, this.obj, this.data) {
    type = obj.runtimeType;
    cm  = reflectClass(type);
    im  = reflect(obj);
  }

  call() {
    publicFields.forEach((_FieldInfo f) {
      final dataName = mappedFieldName(f);
      if (data.containsKey(dataName)) {
        im.setField(f.fieldName, fromData(f, data[dataName]));
      }
    });
  }

  get publicFields => cm.instanceMembers.values
      .where((m) => m.isSetter && !m.isPrivate)
      .map((m) => new _FieldInfo.setter(cm, m))
      .where((f) => f.synthetic || f.hasFieldAnnotation)
      .where((f) => !f.skip && !f.readOnly);

  String mappedFieldName(_FieldInfo f) {
    if (f.mappedName != null) {
      return f.mappedName;
    } else {
      return MirrorSystem.getName(f.fieldName);
    }
  }

  fromData(_FieldInfo f, value) {
    if (f.mapper != null) {
      return f.mapper.fromData(value);
    } else {
      final setterTypeMirror = f.setterTypeMirror;
      final setterType = setterTypeMirror.reflectedType;
      return ms._fromData(setterType, value, setterTypeMirror);
    }
  }
}

class _ScopedMappers implements Mapper {
  Mappers _hammockMapper;
  Type _type;

  _ScopedMappers(this._hammockMapper, this._type);

  toData(obj) => _hammockMapper.toData(obj);
  fromData(data) => _hammockMapper.fromData(_type, data);
}

class Mappers {
  final _globalMappers = {};
  var instantiator = simpleInstantiator;

  void registerMapper(Type type, Mapper mapper) {
    _globalMappers[type] = mapper;
  }

  toData(obj) {
    final type = obj.runtimeType;
    listToData() => obj.map(toData).toList();

    if (obj == null) return null;
    if (obj is List) return listToData();
    if (_globalMappers.containsKey(type)) return _globalMappers[type].toData(obj);
    if (_mappable(obj.runtimeType)) return new _MappableObjectToData(this, obj)();
    return obj;
  }

  fromData(Type type, data) {
    return _fromData(type, data, reflectClass(type));
  }

  updateMappableObject(obj, data) {
    new _UpdateMappableObject(this, obj, data)();
  }

  _fromData(Type type, data, ClassMirror classMirror) {
    listToObjects() {
      final tm = classMirror.typeArguments.first;
      return data.map((d) => fromData(tm.reflectedType, d)).toList();
    }
    if (data == null) return null;
    if (data is List) return listToObjects();
    if (_globalMappers.containsKey(type)) return _globalMappers[type].fromData(data);

    if (_mappable(type)) {
      final obj = instantiator(type, _constructor(type), data["id"]);
      updateMappableObject(obj, data);
      return obj;
    }

    return data;
  }

  Mapper mapperFor(Type type) =>
  _globalMappers.containsKey(type) ?
  _globalMappers[type] :
  new _ScopedMappers(this, type);

  bool _mappable(type) {
    final cm = reflectClass(type);
    return cm.metadata.map((m) => m.reflectee).any((m) => m is Mappable);
  }

  Symbol _constructor(type) {
    isConstructor(m) => m is MethodMirror && m.isConstructor;
    isSelectedConstructor(c) => c.metadata.any((m) => m.reflectee is Constructor);

    final cm = reflectClass(type);
    final allConstructors = cm.declarations.values.where(isConstructor);
    final rightConstructor = allConstructors.firstWhere(isSelectedConstructor, orElse: () => null);

    return rightConstructor == null ? const Symbol('') : rightConstructor.constructorName;
  }
}