import 'dart:math';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:MinuteIdeas/widgets/button.dart';
import 'package:MinuteIdeas/data/ideas.dart';

class IdeaPage extends StatefulWidget {
  const IdeaPage({Key? key}) : super(key: key);

  @override
  _IdeaPageState createState() => _IdeaPageState();
}

var rng = Random();
int firstIndex = rng.nextInt(ideas.length);

class _IdeaPageState extends State<IdeaPage> {
  int currentIndex = firstIndex;
  List<int> remainingIndexes = List.generate(ideas.length, (index) => index)
      .where((index) => index != firstIndex)
      .toList();
  List<int> previousIndexes = [];

  void goToPreviousIdea() {
    if (previousIndexes.isEmpty) return;
    setState(() {
      remainingIndexes.add(currentIndex);
      currentIndex = previousIndexes.last;
      previousIndexes.removeLast();
    });
  }

  void goToNextIdea() {
    if (remainingIndexes.isEmpty) {
      previousIndexes.clear();
      remainingIndexes = List.generate(ideas.length, (index) => index)
          .where((index) => index != currentIndex)
          .toList();
    }

    int nextIndex = remainingIndexes[rng.nextInt(remainingIndexes.length)];
    setState(() {
      previousIndexes.add(currentIndex);
      remainingIndexes.remove(nextIndex);
      currentIndex = nextIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  Expanded(
                      child: Card(
                          child: Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(ideas[currentIndex].title,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500)),
                                      const Spacer(),
                                      GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          child: const Icon(Icons.close))
                                    ]),
                                    const Divider(height: 16),
                                    Expanded(
                                        child: SingleChildScrollView(
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            child: Text(
                                                ideas[currentIndex].content,
                                                style: const TextStyle(
                                                    fontSize: 16)))),
                                    const Spacer(),
                                    const Divider(height: 16),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          GestureDetector(
                                              onTap: () => launchUrl(Uri.parse(
                                                  ideas[currentIndex].source)),
                                              child: const Text('Source',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500)))
                                        ])
                                  ])))),
                  const SizedBox(height: 16),
                  Row(mainAxisSize: MainAxisSize.max, children: [
                    Expanded(
                        child: Button(
                            onPressed: goToPreviousIdea, text: 'Previous')),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Button(onPressed: goToNextIdea, text: 'Next'))
                  ])
                ]))));
  }
}
