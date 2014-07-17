part of hammock_mapper;

Object simpleInstantiator(Type type, Symbol constructor, id) =>
    reflectClass(type).newInstance(constructor, []).reflectee;

class IdentityMapInstantiator {
  final Map<Type, Map> instances = {};

  Object call(Type type, Symbol constructor, id) {
    instances.putIfAbsent(type, () => {});

    final instMap = instances[type];
    instMap.putIfAbsent(id, () => simpleInstantiator(type, constructor, id));

    return instMap[id];
  }
}
