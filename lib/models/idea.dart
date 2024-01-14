import 'package:isar/isar.dart';

part 'idea.g.dart';

@collection
class Idea {
  Id id = Isar.autoIncrement;
  late String title;
  late String content;
  late String source;
  late List<double> embedding;
  late List<Question> questions;

  @Index()
  late DateTime? read;

  Idea copyWith({DateTime? read}) {
    return Idea()
      ..id = id
      ..title = title
      ..content = content
      ..source = source
      ..embedding = embedding
      ..questions = questions
      ..read = read;
  }
}

@embedded
class Question {
  String? question;
  List<String>? choices;
  int? answer;

  Question({this.question, this.choices, this.answer});

  factory Question.fromJson(Map<String, dynamic> json) => Question(
      question: json['question'],
      choices: List<String>.from(json['choices']),
      answer: json['answer']);

  Map<String, dynamic> toJson() =>
      {'question': question, 'choices': choices, 'answer': answer};
}
