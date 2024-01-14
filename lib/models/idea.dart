import 'package:isar/isar.dart';

part 'idea.g.dart';

@collection
class Idea {
  Id id = Isar.autoIncrement;

  late String title;

  late String description;

  late String source;

  late List<double> embedding;

  @Index()
  late DateTime? read;
}
