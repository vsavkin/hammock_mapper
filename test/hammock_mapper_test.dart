library hammock_mapper_test;

import 'package:hammock_mapper/hammock_mapper.dart';
import 'package:guinness/guinness.dart';

part 'src/data_to_object_test.dart';
part 'src/object_to_data_test.dart';
part 'src/scoped_by_type_test.dart';
part 'src/hammock_adapter_test.dart';

@Mappable()
class Pet {
  int id;
  String name;
}

@Mappable()
class Person {
  int id;
  String name;
  Pet pet;
  List<Person> friends;
}

@Mappable()
class CustomConstructor {
  String name;

  @Constructor()
  CustomConstructor.custom() {
    name = 'custom';
  }
}

@Mappable()
class CustomFields {
  @Field(name: 'custom-name') String name;
  @Field(readOnly: true)      String readOnly;
  @Field(skip: true)          String skipped;
  @Field(mapper: intMapper)   int custom;

  var _prop;
  @Field(name: 'prop') get prop => _prop;
  set prop(val) => _prop = val;
}


class IntMapper implements Mapper<int> {
  const IntMapper();
  toData(int t) => "--$t--";
  int fromData(s) => int.parse(s.substring(2, s.length - 2));
}
const intMapper = const IntMapper();

main () {
  testDataToObject();
  testObjectToData();
  testScopedByType();
  testHammockAdapter();
}