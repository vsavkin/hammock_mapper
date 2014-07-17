part of hammock_mapper_test;

testDataToObject () {
  describe("Data to Object", () {
    Mappers m;

    beforeEach(() {
      m = new Mappers();
    });

    it("handles simple fields", () {
      final p = m.fromData(Pet, {"id" : 1, "name" : "Ruby"});

      expect(p.id).toEqual(1);
      expect(p.name).toEqual("Ruby");
    });

    it("skip fields when not found", () {
      final p = new Pet()
          ..id = 1
          ..name = 'Invlaid';

      m.updateMappableObject(p, {"name" : "Ruby"});

      expect(p.id).toEqual(1);
      expect(p.name).toEqual("Ruby");
    });

    it("handles mappable fields", () {
      final p = m.fromData(Person, {"id" : 2, "pet" : {"id": 1}});

      expect(p.pet.id).toEqual(1);
    });

    it("handles lists", () {
      final p = m.fromData(Person, {"id" : 2, "friends" : [{"id": 1}]});

      expect(p.friends.first.id).toEqual(1);
    });

    it("uses global mappers", () {
      m.registerMapper(int, new IntMapper());

      final p = m.fromData(Pet, {
          "id" : "--1--"
      });

      expect(p.id).toEqual(1);
    });

    it("uses a custom instantiator", () {
      m.instantiator = new IdentityMapInstantiator();

      final p1 = m.fromData(Pet, {"id" : 1, "name" : "Ruby"});
      final p2 = m.fromData(Pet, {"id" : 1, "name" : "Ruby"});

      expect(p1).toBe(p2);
    });

    it("uses a custom constructor", () {
      final c = m.fromData(CustomConstructor, {});
      expect(c.name).toBe('custom');
    });

    it("renames fields", () {
      final obj = m.fromData(CustomFields, {"custom-name" : "aaa"});

      expect(obj.name).toEqual('aaa');
    });

    it("skips fields", () {
      final obj = m.fromData(CustomFields, {"skipped" : "aaa"});

      expect(obj.skipped).toBeNull();
    });

    it("skips read-only fields", () {
      final obj = m.fromData(CustomFields, {"readOnly" : "aaa"});

      expect(obj.readOnly).toBeNull();
    });

    it("uses custom field mappers", () {
      final obj = m.fromData(CustomFields, {"custom" : "--99--"});

      expect(obj.custom).toEqual(99);
    });
  });
}