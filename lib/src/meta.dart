part of hammock_mapper;

class Mappable {
  final Symbol constructor;
  const Mappable({this.constructor : const Symbol('')});
}

class Constructor {
  const Constructor();
}

class Field {
  final String name;
  final bool readOnly;
  final bool skip;
  final Mapper mapper;

  const Field({this.name, this.readOnly: false, this.skip: false, this.mapper});
}