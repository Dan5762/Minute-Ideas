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

    await isar.writeTxn(() async {
      isar.ideas.importJson(ideasJson);
    });

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

  Future<List<Idea>> getRecomendedIdeas(int nRecomendations) async {
    if (isar.isOpen == false) {
      return [];
    }
    final ideas = await isar.ideas.filter().readIsNull().findAll();

    userVector = addNoiseToVector(userVector, 0.05);

    ideas.sort((a, b) => cosineSimilarity(b.embedding, userVector)
        .compareTo(cosineSimilarity(a.embedding, userVector)));

    List<Idea> recomendedIdeas = ideas.take(nRecomendations).toList();

    await isar.writeTxn(() async {
      for (Idea recomendedIdea in recomendedIdeas) {
        recomendedIdea.read = DateTime.now();
        isar.ideas.put(recomendedIdea);
      }
    });

    return recomendedIdeas;
  }

  Future<List<Idea>> getKnowledgeIdeas(int nKnowledgeIdeas) async {
    if (isar.isOpen == false) {
      return [];
    }
    final ideas = await isar.ideas.filter().readIsNotNull().sortByRead().findAll();

    List<Idea> knowledgeIdeas = ideas.take(nKnowledgeIdeas).toList();

    return knowledgeIdeas;
  }

  Map<String, double> getCategorySimilarities() {
    Map<String, double> categorySimilarities = {};
    categoryVectors.forEach((key, value) {
      categorySimilarities[key] = cosineSimilarity(userVector, value);
    });
    return categorySimilarities;
  }
}
