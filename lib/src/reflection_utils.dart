part of hammock_mapper;

class _FieldInfo {
  ClassMirror cm;
  Symbol fieldName;
  Field field;
  var accessor;

  _FieldInfo.getter(this.cm, this.accessor) {
    fieldName = this.accessor.simpleName;
    field = findField();
  }

  _FieldInfo.setter(this.cm, this.accessor) {
    var name = MirrorSystem.getName(accessor.simpleName);
    fieldName = new Symbol(name.substring(0, name.length - 1));
    field = findField();
  }

  String get mappedName =>
      (field == null || field.name == null) ? MirrorSystem.getName(fieldName) : field.name;

  Mapper get mapper => field == null ? null : field.mapper;

  get setterTypeMirror => accessor.parameters.first.type;

  bool get isUsedToGenerateData =>
      accessor.isGetter && publicFieldWithAnnotation && notReserved && notSkipped;

  bool get isUsedToUpdateObject =>
      accessor.isSetter && publicFieldWithAnnotation && notReadOnly && notSkipped;



  Field findField () {
    final d = cm.declarations[fieldName];
    if (d == null) return null;
    return d.metadata.map((m) => m.reflectee).firstWhere((m) => m is Field, orElse: () => null);
  }

  ResourceId findResourceId () {
    final d = cm.declarations[fieldName];
    if (d == null) return null;
    return d.metadata.map((m) => m.reflectee).firstWhere((m) => m is ResourceId, orElse: () => null);
  }

  bool get publicFieldWithAnnotation =>
      !accessor.isPrivate && (accessor.isSynthetic || field != null);

  bool get notReserved => fieldName != #hashCode && fieldName != #runtimeType;

  bool get notSkipped => field == null ? true : !field.skip;

  bool get notReadOnly => field == null ? true : !field.readOnly;
}

class _TypeInfo {
  ClassMirror cm;
  Type type;

  _TypeInfo(this.cm, this.type);

  _TypeInfo.fromObject(obj) {
    type = obj.runtimeType;
    cm = reflectClass(type);
  }

  bool get isMappable =>
      cm.metadata.map((m) => m.reflectee).any((m) => m is Mappable);

  Symbol get constructor {
    isConstructor(m) => m is MethodMirror && m.isConstructor;
    isSelectedConstructor(c) => c.metadata.any((m) => m.reflectee is Constructor);

    final allConstructors = cm.declarations.values.where(isConstructor);
    final rightConstructor = allConstructors.firstWhere(isSelectedConstructor, orElse: () => null);
    return rightConstructor == null ? null : rightConstructor.constructorName;
  }

  Symbol get resourceId =>
      cm.instanceMembers.values
        .map((m) => new _FieldInfo.getter(cm, m))
        .where((f) => f.isUsedToGenerateData)
        .map((f) => f.findResourceId() != null ? f.fieldName : null)
        .firstWhere((f) => f != null, orElse: () => null);

  Symbol get id =>
      cm.instanceMembers.values
        .map((m) => new _FieldInfo.getter(cm, m))
        .where((f) => f.isUsedToGenerateData)
        .map((f) => f.fieldName == #id ? #id : null)
        .firstWhere((f) => f != null, orElse: () => null);
}
