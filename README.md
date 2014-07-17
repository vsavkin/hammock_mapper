# Hammock.Mapper

Hammock.Mapper uses conventions and a bit of meta information to generate all the serialization and deserialization functions required by Hammock. Read more about Hammock [here](https://github.com/vsavkin/hammock).


## Hammock

First, let's look at a small example of using Hammock.

Suppose we have the following model defined:

```dart
class Post {
  int id;
  String title;
  Post(this.id, this.title);
}
```

You can configure Hammock to work with this model:

```dart
config.set({
    "posts" : {
        "type" : Post,
        "serializer" : serializePost,
        "deserializer" : {
            "query" : deserializerPost,
            "command" : {
              "success" : updatePost,
              "error" : parseErrors
            }
        }
    }
});

Resource serializePost(Post post) =>
      resource("posts", post.id, {"id" : post.id, "title" : post.title});

Post updatePost(Post post, CommandResponse resp) {
  post.id = resp.content["id"];
  post.title = resp.content["title"];
  return post;
}

deserializePost(Resource r) => new Post(r.id, r.content["title"]);

parseErrors(obj, CommandResponse resp) => resp.content["errors"];
```

Having this configuration in place, we can use `ObjectStore` to load and save post objects. 

```dart
ObjectStore store; //get injected

Future<Post> p = store.one(Post, 123);
p.title = 'new title';
store.update(p);
```

Hammock does not assume anything about the objects it works with, and as a result, you have to provide all the serialization and deserialization functions. This flexibility can be useful, especially when dealing with legacy APIs, or APIs that you do not control.

Implementing all these functions, however, can be quite tedious, especially when dealing with nested objects (e.g., a post with many comments). That's where Hammock.Mapper comes into play. With Hammock.Mapper we can annotate our classes with a little bit of extra information and the library will take care of generating all the required serialization and deserialization functions.


## Hammock.Mapper

Let's look at our example again, but this time using Hammock.Mapper.

```dart
@Mappable()
class Post {
  int id;
  String title;

  Post(this.id, this.title);
  @Constructor() Post.blank();
}
```

First, you need to annotate your models with `Mappable`. The model has to have a constructor without arguments. We can choose the construtor we want to use. 

```dart
config.set(
    mappers()
      .resource("posts", Post)
      .createHammockConfig()
);
```

That's all the configuration that you have to provide.


## Nested Objects and Lists

Let's look at a more complicated example:

```dart
@Mappable()
class Post {
  int id;
  String title;
  List<Comment> comments;

  Post(this.id, this.title, this.comments);
  @Constructor() Post.blank();
}

@Mappable()
class Comment {
  int id;
  String text;

  Comment(this.id, this.text);
  @Constructor() Comment.blank();
}

config.set(
    mappers()
      .resource("posts", Post)
      .resource("comments", Comment)
      .createHammockConfig()
);
```

With this configuration, you can load and save comments and posts. Note, that the list property will be handled properly.

## Configuring Mappers

```dart
@Mappable()
class Post {
  @Field(name: 'custom-id')   int id;
  @Field(skip: true)          String skip;
  @Field(readOnly: true)      String readOnly;
  @Field(mapper: someMapper)  String customMapper;
}
```


## Global Mappers

There are types, however, you cannot add meta information to (e.g., DateTime) using annotations. For those types mappers have to be registered explicitly.

```dart
@Mappable()
class Post {
  int id;
  String title;
  DateTime publishedAt;

  Post(this.id, this.title, this.publishedAt);
  @Constructor() Post.blank();
}

class DateTimeMapper implements Mapper<DateTime> {
  String toData(DateTime d) => d.toString();
  DateTime fromData(String s) => DateTime.parse(s);
}

config.set(
    mappers()
      .resource("posts", Post)
      .mapper(DateTime, new DateTimeMapper())
      .createHammockConfig()
);
```

## Identity Map

There is another problem that the code at the beginning of this document has. 

```dart
//WITHOUT Hammock.Mapper

//somewhere in Component1
final p1 = store.one(Post, 123);
//display p1

//somewhere in Component2
final p2 = store.one(Post, 123);
p2.title = 'new title';  
//p1 still has the old title because p1 != p2
```

The `Component1` will not see the changed title because it has a different instance of `Post(123)`. Hammock.Mapper solves this problem by using an identity map. So when using `Hammock.Mapper` both of the components will get the same object.

```dart
  //WITH Hammock.Mapper

  //somewhere in Component1
  final p1 = store.one(Post, 123);
  //display p1

  //somewhere in Component2
  final p2 = store.one(Post, 123);
  p2.title = 'new title';  
  //p1 has the new title because p1 == p2
```

You can disable it:

```dart
config.set(
    mappers()
      .resource("posts", Post)
      .instantiator(simpleInstantiator)
      .createHammockConfig()
);
```

## You Can Always Go Low-Level

Note, that Hammock.Mapper just creates a configuration map for Hammock. You can always change the configuration or add new items to it. 

```dart
Map m = mappers()
      .resource("posts", Post)
      .mapper(DateTime, new DateTimeMapper())
      .createHammockConfig();

m["special-resource"] = ...;

config.set(m);
```

## Use Mappers Directly

You can use the mapper piece of library without Hammock:

```dart
final mappers = new Mappers();
Map data = mappers.toData(post);
Post restoredPost = mappers.fromData(Post, data);
```