# json_serializable | Dart package
[![Pub Package](https://img.shields.io/pub/v/json_serializable.svg)](https://pub.dev/packages/json_serializable)

Provides [Dart Build System](https://github.com/dart-lang/build) builders for handling JSON.

The builders generate code when they find members annotated with classes defined in [package:json\_annotation](https://pub.dev/packages/json_annotation).

*   To generate to/from JSON code for a class, annotate it with [`JsonSerializable`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonSerializable-class.html). You can provide arguments to [`JsonSerializable`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonSerializable-class.html) to configure the generated code. You can also customize individual fields by annotating them with [`JsonKey`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonKey-class.html) and providing custom arguments. See the table below for details on the [annotation values](#annotation-values).
    
*   To generate a Dart field with the contents of a file containing JSON, use the [`JsonLiteral`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonLiteral-class.html) annotation.
    

To configure your project for the latest released version of `json_serializable`, see the [example](https://github.com/google/json_serializable.dart/tree/master/example).

Given a library `example.dart` with an `Person` class annotated with [`JsonSerializable`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonSerializable-class.html):

```
import 'package:json_annotation/json_annotation.dart';

part 'example.g.dart';

@JsonSerializable(createJsonSchema: true)
class Person {
  final String firstName, lastName;

  final DateTime? dateOfBirth;

  Person({required this.firstName, required this.lastName, this.dateOfBirth});

  /// Connect the generated [_$PersonFromJson] function to the `fromJson`
  /// factory.
  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PersonToJson(this);

  /// The JSON Schema for this class.
  static const jsonSchema = _$PersonJsonSchema;
}

```


Building creates the corresponding part `example.g.dart`:

```
part of 'example.dart';

Person _$PersonFromJson(Map<String, dynamic> json) => Person(
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  dateOfBirth: json['dateOfBirth'] == null
      ? null
      : DateTime.parse(json['dateOfBirth'] as String),
);

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
};

const _$PersonJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'firstName': {'type': 'string'},
    'lastName': {'type': 'string'},
    'dateOfBirth': {'type': 'string', 'format': 'date-time'},
  },
  'required': ['firstName', 'lastName'],
};

```


Once you have added the annotations to your code you then need to run the code generator to generate the missing `.g.dart` generated dart files.

Run `dart run build_runner build` in the package directory.

The only annotation required to use this package is [`JsonSerializable`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonSerializable-class.html). When applied to a class (in a correctly configured package), `toJson` and `fromJson` code will be generated when you build. There are three ways to control how code is generated:

1.  Setting properties on [`JsonKey`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonKey-class.html) annotating the target field.
2.  Set properties on [`JsonSerializable`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonSerializable-class.html) annotating the target type.
3.  Add configuration to `build.yaml` – [see below](#build-configuration).

Every [`JsonSerializable`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonSerializable-class.html) field is configurable via `build.yaml`. If you find you want all or most of your classes with the same configuration, it may be easier to specify values once in the YAML file. Values set explicitly on [`JsonSerializable`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonSerializable-class.html) take precedence over settings in `build.yaml`.

There is some overlap between settings on [`JsonKey`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonKey-class.html) and [`JsonSerializable`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonSerializable-class.html). In these cases, the property on [`JsonKey`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonKey-class.html) takes precedence over any value set on [`JsonSerializable`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonSerializable-class.html).

Annotate `enum` types with [`JsonEnum`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonEnum-class.html) (new in `json_annotation` 4.2.0) to:

1.  Specify the default rename logic for each enum value using `fieldRename`. For instance, use `fieldRename: FieldRename.kebab` to encode `enum` value `noGood` as `"no-good"`.
2.  Force the generation of the `enum` helpers, even if the `enum` is not referenced in code. This is an edge scenario, but useful for some.

Annotate `enum` values with [`JsonValue`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonValue-class.html) to specify the encoded value to map to target `enum` entries. Values can be of type [`String`](https://api.dart.dev/dart-core/String-class.html) or [`int`](https://api.dart.dev/dart-core/int-class.html).

```
enum StatusCode {
  @JsonValue(200)
  success,
  @JsonValue(301)
  movedPermanently,
  @JsonValue(302)
  found,
  @JsonValue(500)
  internalServerError,
}

```


If you are annotating an [enhanced enum](https://dart.dev/guides/language/language-tour#declaring-enhanced-enums), you can use [`JsonEnum.valueField`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonEnum/valueField.html) to specify the field to use for the serialized value.

```
@JsonEnum(valueField: 'code')
enum StatusCodeEnhanced {
  success(200),
  movedPermanently(301),
  found(302),
  internalServerError(500);

  const StatusCodeEnhanced(this.code);
  final int code;
}

```


Out of the box, `json_serializable` supports many common types in the [dart:core](https://api.dart.dev/dart-core/dart-core-library.html) library: [`BigInt`](https://api.dart.dev/dart-core/BigInt-class.html), [`bool`](https://api.dart.dev/dart-core/bool-class.html), [`DateTime`](https://api.dart.dev/dart-core/DateTime-class.html), [`double`](https://api.dart.dev/dart-core/double-class.html), [`Duration`](https://api.dart.dev/dart-core/Duration-class.html), [`Enum`](https://api.dart.dev/dart-core/Enum-class.html), [`int`](https://api.dart.dev/dart-core/int-class.html), [`Iterable`](https://api.dart.dev/dart-core/Iterable-class.html), [`List`](https://api.dart.dev/dart-core/List-class.html), [`Map`](https://api.dart.dev/dart-core/Map-class.html), [`num`](https://api.dart.dev/dart-core/num-class.html), [`Object`](https://api.dart.dev/dart-core/Object-class.html), [`Record`](https://api.dart.dev/dart-core/Record-class.html), [`Set`](https://api.dart.dev/dart-core/Set-class.html), [`String`](https://api.dart.dev/dart-core/String-class.html), [`Uri`](https://api.dart.dev/dart-core/Uri-class.html)

The collection types – [`Iterable`](https://api.dart.dev/dart-core/Iterable-class.html), [`List`](https://api.dart.dev/dart-core/List-class.html), [`Map`](https://api.dart.dev/dart-core/Map-class.html), [`Record`](https://api.dart.dev/dart-core/Record-class.html), [`Set`](https://api.dart.dev/dart-core/Set-class.html) – can contain values of all the above types.

For [`Map`](https://api.dart.dev/dart-core/Map-class.html), the key value must be one of [`BigInt`](https://api.dart.dev/dart-core/BigInt-class.html), [`DateTime`](https://api.dart.dev/dart-core/DateTime-class.html), [`Enum`](https://api.dart.dev/dart-core/Enum-class.html), [`int`](https://api.dart.dev/dart-core/int-class.html), [`Object`](https://api.dart.dev/dart-core/Object-class.html), [`String`](https://api.dart.dev/dart-core/String-class.html), [`Uri`](https://api.dart.dev/dart-core/Uri-class.html)

Custom types and custom encoding [#](#custom-types-and-custom-encoding)
-----------------------------------------------------------------------

If you want to use types that are not supported out-of-the-box or if you want to customize the encoding/decoding of any type, you have a few options.

1.  If you own/control the desired type, add a `fromJson` constructor and/or a `toJson()` function to the type. Note: while you can use `json_serializable` for these types, you don't have to! The generator code only looks for these methods. It doesn't care how they were created.
    
    ```
@JsonSerializable()
class Sample1 {
  Sample1(this.value);

  factory Sample1.fromJson(Map<String, dynamic> json) =>
      _$Sample1FromJson(json);

  // Sample2 is NOT annotated with @JsonSerializable(), but that's okay
  // The class has a `fromJson` constructor and a `toJson` method, which is
  // all that is required.
  final Sample2 value;

  Map<String, dynamic> toJson() => _$Sample1ToJson(this);
}

class Sample2 {
  Sample2(this.value);

  // The convention is for `fromJson` to take a single parameter of type
  // `Map<String, dynamic>` but any JSON-compatible type is allowed.
  factory Sample2.fromJson(int value) => Sample2(value);
  final int value;

  // The convention is for `toJson` to take return a type of
  // `Map<String, dynamic>` but any JSON-compatible type is allowed.
  int toJson() => value;
}

```

    
2.  Use the [`JsonKey.toJson`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonKey/toJson.html) and [`JsonKey.fromJson`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonKey/fromJson.html) properties to specify custom conversions on the annotated field. The functions specified must be top-level or static. See the documentation of these properties for details.
    
    ```
@JsonSerializable()
class Sample3 {
  Sample3(this.value);

  factory Sample3.fromJson(Map<String, dynamic> json) =>
      _$Sample3FromJson(json);

  @JsonKey(toJson: _toJson, fromJson: _fromJson)
  final DateTime value;

  Map<String, dynamic> toJson() => _$Sample3ToJson(this);

  static int _toJson(DateTime value) => value.millisecondsSinceEpoch;
  static DateTime _fromJson(int value) =>
      DateTime.fromMillisecondsSinceEpoch(value);
}

```

    
3.  Create an implementation of [`JsonConverter`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonConverter-class.html) and annotate either the corresponding field or the containing class. [`JsonConverter`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonConverter-class.html) is convenient if you want to use the same conversion logic on many fields. It also allows you to support a type within collections. Check out [these examples](https://github.com/google/json_serializable.dart/blob/master/example/lib/json_converter_example.dart).
    
    ```
@JsonSerializable()
class Sample4 {
  Sample4(this.value);

  factory Sample4.fromJson(Map<String, dynamic> json) =>
      _$Sample4FromJson(json);

  @EpochDateTimeConverter()
  final DateTime value;

  Map<String, dynamic> toJson() => _$Sample4ToJson(this);
}

class EpochDateTimeConverter implements JsonConverter<DateTime, int> {
  const EpochDateTimeConverter();

  @override
  DateTime fromJson(int json) => DateTime.fromMillisecondsSinceEpoch(json);

  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch;
}

```

    

You can generate [JSON Schema](https://json-schema.org/) definitions for your annotated classes. This is useful for validation, documentation, or defining APIs.

To enable this feature, set `createJsonSchema: true` on the [`JsonSerializable`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonSerializable-class.html) annotation:

```
@JsonSerializable(createJsonSchema: true)
class Person {
  // ...
  /// The JSON Schema for this class.
  static const jsonSchema = _$PersonJsonSchema;
}

```


The generator will create a `static const` field named `_$ClassNameJsonSchema` containing the schema as a `Map<String, dynamic>`.

Key features of the generated schema:

*   **Separation of Concerns:** The schema generation logic is handled by a dedicated `JsonSchemaGenerator`.
*   **Idiomatic Dart:** The output uses single quotes (`'`) for string literals.
*   **Type Mapping:**
    *   [`int`](https://api.dart.dev/dart-core/int-class.html) maps to `integer`.
    *   [`DateTime`](https://api.dart.dev/dart-core/DateTime-class.html) maps to `string` with `format: date-time`.
    *   [`List`](https://api.dart.dev/dart-core/List-class.html)/[`Set`](https://api.dart.dev/dart-core/Set-class.html) map to `array`.
    *   [`Map`](https://api.dart.dev/dart-core/Map-class.html) maps to `object`.
    *   Nested objects use `$ref` to reference their schema definitions.
*   **Documentation:** Comments (`///`) on fields are included as `description` fields in the schema.
*   **Defaults:** `defaultValue` from [`JsonKey`](https://pub.dev/documentation/json_annotation/4.11.0/json_annotation/JsonKey-class.html) is reflected in the schema.

See the [Example](#example) above for a complete code sample.

Aside from setting arguments on the associated annotation classes, you can also configure code generation by setting values in `build.yaml`.

```
targets:
  $default:
    builders:
      json_serializable:
        options:
          # Options configure how source code is generated for every
          # `@JsonSerializable`-annotated class in the package.
          #
          # The default value for each is listed.
          any_map: false
          checked: false
          constructor: ""
          create_factory: true
          create_field_map: false
          create_json_keys: false
          create_json_schema: false
          create_per_field_to_json: false
          create_to_json: true
          date_time_utc: false
          disallow_unrecognized_keys: false
          explicit_to_json: false
          field_rename: none
          generic_argument_factories: false
          ignore_unannotated: false
          include_if_null: true

```


To exclude generated files from coverage, you can further configure `build.yaml`.

```
targets:
  $default:
    builders:
      source_gen:combining_builder:
        options:
          preamble: |
            // coverage:ignore-file

```
