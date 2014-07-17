part of hammock_mapper_test;

testObjectToData () {
  describe("Object to Data", () {
    var m, pet, person;

    beforeEach(() {
      m = new Mappers();

      pet = new Pet()
          ..id = 1
          ..name = "Ruby";

      person = new Person()
          ..id = 2
          ..name = "Jim"
          ..pet = pet;
    });

    it("handles simple fields", () {
      final d = m.toData(pet);
      expect(d).toEqual({"id" : 1, "name" : "Ruby"});
    });

    it("handles mappable fields", () {
      final d = m.toData(person);
      expect(d["pet"]).toEqual({"id" : 1, "name" : "Ruby"});
    });

    it("handles lists", () {
      person.friends = [new Person()..id = 3];

      final d = m.toData(person);

      expect(d["friends"].first["id"]).toEqual(3);
    });

    it("uses global mappers", () {
      m.registerMapper(int, new IntMapper());

      final d = m.toData(pet);

      expect(d["id"]).toEqual("--1--");
    });

    it("renames fields", () {
      final obj = new CustomFields()..name = 'aaa';

      final d = m.toData(obj);

      expect(d["custom-name"]).toEqual('aaa');
    });

    it("skips fields", () {
      final obj = new CustomFields()..skipped = 'aaa';

      final d = m.toData(obj);

      expect(d["skipped"]).toBeNull();
    });

    it("uses custom field mappers", () {
      final obj = new CustomFields()..custom = 99;

      final d = m.toData(obj);

      expect(d["custom"]).toEqual('--99--');
    });

    it("serializes getters", () {
      final obj = new CustomFields()..prop = 'prop';

      final d = m.toData(obj);

      expect(d["prop"]).toEqual('prop');
    });
  });
}