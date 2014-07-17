part of hammock_mapper;

class HammockAdapter {
  Mappers ms;
  String resourceType;
  Type type;

  HammockAdapter(this.ms, this.resourceType, this.type);

  Resource serialize(obj) {
    return resource(resourceType, obj.id, ms.toData(obj));
  }

  Object deserialize(Resource res) {
    return ms.fromData(type, res.content);
  }

  Object update(obj, CommandResponse resp) {
    ms.updateMappableObject(obj, resp.content);
    return obj;
  }
}

class HammockConfigurationBuilder {
  Mappers ms;
  final List adapters = [];

  HammockConfigurationBuilder() {
    ms = new Mappers();
    ms.instantiator = new IdentityMapInstantiator();
  }

  HammockConfigurationBuilder resource(String resourceType, Type type) {
    adapters.add(new HammockAdapter(ms, resourceType, type));
    return this;
  }

  HammockConfigurationBuilder mapper(Type type, Mapper m) {
    ms.registerMapper(type, m);
    return this;
  }

  Map createHammockConfig() {
    return adapters.fold({}, (config, adapter) {
      config[adapter.resourceType] = {
          "type": adapter.type,
          "serializer" : adapter.serialize,
          "deserializer" : {
              "query" : adapter.deserialize,
              "commands" : adapter.update
          }
      };
      return config;
    });
  }
}

mappers() => new HammockConfigurationBuilder();