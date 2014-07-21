part of hammock_mapper;

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
    return getters.fold({}, (Map data, _FieldInfo f) {
      data[f.mappedName] = toData(f);
      return data;
    });
  }

  get getters {
    return cm.instanceMembers.values
        .map((m) => new _FieldInfo.getter(cm, m))
        .where((f) => f.isUsedToGenerateData);
  }

  toData(_FieldInfo f) {
    final value = im.getField(f.fieldName).reflectee;
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
    setters.forEach((_FieldInfo f) {
      if (data.containsKey(f.mappedName)) {
        im.setField(f.fieldName, fromData(f, data[f.mappedName]));
      }
    });
  }

  get setters {
    return cm.instanceMembers.values
        .map((m) => new _FieldInfo.setter(cm, m))
        .where((f) => f.isUsedToUpdateObject);
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
  final Map<Type, Mapper> _globalMappers = {};
  Instantiator instantiator = simpleInstantiator;

  void registerMapper(Type type, Mapper mapper) {
    _globalMappers[type] = mapper;
  }

  Mapper mapperFor(Type type) =>
      _globalMappers.containsKey(type) ?
        _globalMappers[type] :
        new _ScopedMappers(this, type);

  toData(obj) {
    final t = new _TypeInfo.fromObject(obj);

    if (obj == null) return null;
    if (obj is List) return _listToData(obj);
    if (_hasGlobalMapper(t)) return _globalMapperToData(t, obj);
    if (t.isMappable) return new _MappableObjectToData(this, obj)();
    return obj;
  }

  fromData(Type type, data) {
    return _fromData(type, data, reflectClass(type));
  }

  updateMappableObject(obj, data) {
    new _UpdateMappableObject(this, obj, data)();
  }



  _fromData(Type type, data, ClassMirror classMirror) {
    final t = new _TypeInfo(classMirror, type);

    if (data == null) return null;
    if (data is List) return _listToObjects(data, classMirror);
    if (_hasGlobalMapper(t)) return _globalMapperFromData(t, data);
    if (t.isMappable) return _mappableFromData(t, data);

    return data;
  }

  _hasGlobalMapper(_TypeInfo t) => _globalMappers.containsKey(t.type);

  _globalMapperToData(_TypeInfo t, obj) => _globalMappers[t.type].toData(obj);

  _globalMapperFromData(_TypeInfo t, data) => _globalMappers[t.type].fromData(data);

  List _listToData(List obj) => obj.map(toData).toList();

  List _listToObjects(List data, ClassMirror classMirror) {
    final tm = classMirror.typeArguments.first;
    return data.map((d) => fromData(tm.reflectedType, d)).toList();
  }

  _mappableFromData(_TypeInfo t, data) {
    final constructor = _default(t.constructor, const Symbol(''));
    final obj = instantiator(t.type, constructor, data["id"]);
    updateMappableObject(obj, data);
    return obj;
  }
}