part of hammock_mapper_test;

testScopedByType () {
  describe("Scoped by Type", () {

    it("returns a mapper for a given type", () {
      final m = new Mappers().mapperFor(Pet);
      final pet = new Pet()
          ..id = 1
          ..name = "Ruby";

      final data = m.toData(pet);
      final restoredPet = m.fromData(data);

      expect(restoredPet.name).toEqual("Ruby");
    });
  });
}