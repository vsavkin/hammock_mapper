part of hammock_mapper_test;

@Mappable()
class WithResourceId {
  @ResourceId() int resourceId;
}

@Mappable()
class NoId {
}

testHammockAdapter () {
  describe("HammockAdapter", () {
    final mappers = new Mappers();

    describe("serialize", () {
      it("serializes an object into a resource", () {
        final ha = new HammockAdapter(mappers, "pets", Pet);

        final r = ha.serialize(new Pet()..id=1..name="Ruby");

        expect(r.id).toEqual(1);
        expect(r.type).toEqual("pets");
        expect(r.content).toEqual({"id" : 1, "name" : "Ruby"});
      });

      it("uses @ResourceId when it is present", () {
        final ha = new HammockAdapter(mappers, "resource", WithResourceId);

        final r = ha.serialize(new WithResourceId()..resourceId=1);

        expect(r.id).toEqual(1);
      });

      it("throws an error when no @ResourceId and no id field", () {
        final ha = new HammockAdapter(mappers, "resource", NoId);

        expect(() => ha.serialize(new NoId())).toThrowWith(message: 'id field defined');
      });
    });
  });
}