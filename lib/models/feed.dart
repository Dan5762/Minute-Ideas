import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:MinuteIdeas/models/idea.dart';

class FeedModel extends ChangeNotifier {
  FeedModel() {
    init();
  }

  List<double> userVector = List.filled(384, 0);
  Map<String, List<double>> categoryVectors = {};
  bool isInitialized = false;

  late Isar isar;

  void init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [IdeaSchema],
      directory: dir.path,
    );

    // Load ideas from assets
    final ideasJsonRaw = await rootBundle.loadString('assets/ideas.json');
    final ideasJson =
        List<Map<String, dynamic>>.from(json.decode(ideasJsonRaw));

    if (await isar.ideas.count() == 0) {
      await isar.writeTxn(() async {
        isar.ideas.importJson(ideasJson);
      });
    }

    isInitialized = true;

    final categoriesJsonRaw =
        await rootBundle.loadString('assets/categories.json');
    categoryVectors = (json.decode(categoriesJsonRaw) as Map)
        .map((key, value) => MapEntry(key, List<double>.from(value)));
    notifyListeners();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localUserVectorFile async {
    final path = await _localPath;
    return File('$path/user_vector.txt');
  }

  Future<void> updateUserVector(List<double> vector) async {
    final file = await _localUserVectorFile;
    file.writeAsString(vector.toString());
    userVector = vector;
    notifyListeners();
  }

  Future<void> weightedUpdateUserVector(
      List<double> newVector, double alpha) async {
    final newUserVector = List<double>.generate(userVector.length,
        (i) => (1 - alpha) * userVector[i] + alpha * newVector[i]);

    print("Updated user vector");
    print(newUserVector);
    updateUserVector(newUserVector);
    notifyListeners();
  }

  Future<List<double>?> readUserVector() async {
    try {
      final file = await _localUserVectorFile;
      final contents = await file.readAsString();
      return (json.decode(contents) as List)
          .map((item) => item as double)
          .toList();
    } catch (e) {
      return null;
    }
  }

  void loadUserVector() async {
    List<double>? loadedUserVector = await readUserVector();
    if (loadedUserVector != null && loadedUserVector.length == 1024) {
      userVector = loadedUserVector;
      notifyListeners();
    }
  }

  double cosineSimilarity(List<double> vectorA, List<double> vectorB) {
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
      normA += vectorA[i] * vectorA[i];
      normB += vectorB[i] * vectorB[i];
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  List<double> addNoiseToVector(List<double> vector, double noise) {
    final random = Random();
    return vector.map((e) => e + noise * random.nextDouble()).toList();
  }

  Future<List<Idea>> getFeedIdeas(int nRecomendations, int nQuestions) async {
    print("Getting feed ideas");
    if (isar.isOpen == false) {
      return [];
    }
    final readIdeas = await isar.ideas
        .filter()
        .readIsNotNull()
        .sortByRead()
        .findAll();

    final unReadIdeas = await isar.ideas.filter().readIsNull().findAll();

    userVector = addNoiseToVector(userVector, 0.05);

    unReadIdeas.sort((a, b) => cosineSimilarity(b.embedding, userVector)
        .compareTo(cosineSimilarity(a.embedding, userVector)));

    List<Idea> feedIdeas = unReadIdeas.take(nRecomendations).toList() +
        readIdeas.take(nQuestions).toList();

    feedIdeas.shuffle();

    List<Idea> updateReadFeedIdeas = feedIdeas
        .map((feedIdea) => feedIdea.copyWith(read: DateTime.now()))
        .toList();

    await isar.writeTxn(() async {
      for (Idea idea in updateReadFeedIdeas) {
        isar.ideas.put(idea);
      }
    });

    print(feedIdeas);

    return feedIdeas;
  }

  Map<String, double> getCategorySimilarities() {
    Map<String, double> categorySimilarities = {};
    categoryVectors.forEach((key, value) {
      categorySimilarities[key] = cosineSimilarity(userVector, value);
    });
    return categorySimilarities;
  }

  void markIdeaAsUnread(Idea idea) async {
    await isar.writeTxn(() async {
      print(idea.title);
      idea.read = null;
      isar.ideas.put(idea);
      print(idea.title);
    });
  }
}
