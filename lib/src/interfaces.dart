part of hammock_mapper;

abstract class Mapper<T> {
  toData(T t);
  T fromData(data);
}

typedef Instantiator(Type type, Symbol constructor, id);