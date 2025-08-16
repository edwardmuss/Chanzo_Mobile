import 'package:hive/hive.dart';

// part 'test_hive_model.g.dart';

@HiveType(typeId: 0)
class TestModel {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int age;

  TestModel(this.name, this.age);
}