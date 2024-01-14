import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:MinuteIdeas/models/feed.dart';
import 'package:MinuteIdeas/models/idea.dart';
import 'package:MinuteIdeas/widgets/paging_scroll_physics.dart';

int countWords(String str) {
  var words = str.split(RegExp(r'\s+'));
  words = words.where((word) => word.isNotEmpty).toList();

  return words.length;
}

class Feed extends StatefulWidget {
  const Feed({Key? key}) : super(key: key);

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  int currentIndex = 0;
  static const nNewIdeas = 2;
  static const nQuestions = 2;

  final PagingController<int, Idea> _pagingController =
      PagingController(firstPageKey: 0, invisibleItemsThreshold: 1);

  Future<void> _fetchPage(int pageKey, FeedModel feedModel) async {
    List<Idea> feedItems = await feedModel.getFeedIdeas(nNewIdeas, nQuestions);

    while (feedItems.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 50));
      feedItems = await feedModel.getFeedIdeas(nNewIdeas, nQuestions);
    }

    try {
      final isLastPage = feedItems.length < nQuestions;
      if (isLastPage) {
        _pagingController.appendLastPage(feedItems);
      } else {
        final nextPageKey = pageKey + feedItems.length;
        _pagingController.appendPage(feedItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double cardHeight = (MediaQuery.of(context).size.height -
            MediaQuery.paddingOf(context).top -
            MediaQuery.paddingOf(context).bottom) -
        66 -
        48;
    return Consumer<FeedModel>(builder: (context, feedModel, child) {
      if (!feedModel.isInitialized) {
        return const Scaffold(
            backgroundColor: Colors.black,
            body:
                Center(child: CircularProgressIndicator(color: Colors.white)));
      }

      _pagingController.addPageRequestListener((pageKey) {
        _fetchPage(pageKey, feedModel);
      });
      return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PagedListView<int, Idea>(
                      itemExtent: cardHeight,
                      physics: PagingScrollPhysics(itemHeight: cardHeight),
                      pagingController: _pagingController,
                      builderDelegate: PagedChildBuilderDelegate<Idea>(
                          animateTransitions: true,
                          noItemsFoundIndicatorBuilder: (context) =>
                              const Center(
                                  child: Text('No ideas found :(',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white))),
                          itemBuilder: (context, idea, index) {
                            Stopwatch stopwatch = Stopwatch();

                            return VisibilityDetector(
                                key: Key(idea.id.toString()),
                                onVisibilityChanged: (visibilityInfo) {
                                  var visiblePercentage =
                                      visibilityInfo.visibleFraction * 100;

                                  if (visiblePercentage > 80 &&
                                      !stopwatch.isRunning) {
                                    stopwatch.start();
                                  } else if (stopwatch.isRunning) {
                                    stopwatch.stop();

                                    if (stopwatch.elapsed.inSeconds > 2) {
                                      int nWords = countWords(idea.content);

                                      double weight =
                                          stopwatch.elapsed.inSeconds / nWords;
                                      weight = 1 -
                                          (1 /
                                              (weight + 1)); // limit to below 1

                                      feedModel.weightedUpdateUserVector(
                                          idea.embedding, 0.1);
                                      stopwatch.reset();
                                    }
                                  }
                                },
                                child: IdeaCard(idea: idea));
                          })))));
    });
  }
}

class IdeaCard extends StatelessWidget {
  final Idea idea;

  const IdeaCard({Key? key, required this.idea}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(8)),
        height: MediaQuery.of(context).size.height,
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (idea.read == null) IdeaRegion(idea: idea),
                  if (idea.read != null) QuestionRegion(idea: idea),
                  const Divider(height: 16),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        GestureDetector(
                            onTap: () => launchUrl(Uri.parse(idea.source)),
                            child: const Text('Source',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500)))
                      ])
                ])));
  }
}

class IdeaRegion extends StatelessWidget {
  final Idea idea;

  const IdeaRegion({Key? key, required this.idea}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(idea.title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          const Divider(height: 16),
          Expanded(
              child: Text(idea.content, style: const TextStyle(fontSize: 16))),
        ]));
  }
}

class QuestionRegion extends StatelessWidget {
  final Idea idea;
  final ValueNotifier<int?> selectedAnswer = ValueNotifier<int?>(null);

  QuestionRegion({Key? key, required this.idea}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final random = Random();
    int questionIndex = random.nextInt(idea.questions.length);
    return Expanded(
        child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(idea.title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          const Divider(height: 16),
          Text(
              idea.questions[questionIndex].question ??
                  "Oops no question found, that's odd",
              style: const TextStyle(fontSize: 16)),
          const Spacer(),
          const Text("Which is correct?",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
          for (final (int choiceIndex, String choice)
              in idea.questions[questionIndex].choices!.indexed)
            ValueListenableBuilder<int?>(
                valueListenable: selectedAnswer,
                builder: (context, value, child) {
                  return Selector<FeedModel, Function>(
                      selector: (_, feedModel) => feedModel.markIdeaAsUnread,
                      builder: (_, markIdeaAsUnread, __) => GestureDetector(
                          onTap: () {
                            selectedAnswer.value = idea
                                .questions[questionIndex].choices
                                ?.indexOf(choice);

                            if (choiceIndex !=
                                idea.questions[questionIndex].answer) {
                              markIdeaAsUnread(idea);
                            }
                          },
                          child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                  color: choiceIndex ==
                                              idea.questions[questionIndex]
                                                  .answer &&
                                          value ==
                                              idea.questions[questionIndex]
                                                  .answer
                                      ? Colors.green
                                      : choiceIndex !=
                                                  idea.questions[questionIndex]
                                                      .answer &&
                                              value == choiceIndex
                                          ? CupertinoColors.destructiveRed
                                          : const Color.fromARGB(
                                              255, 59, 59, 59),
                                  borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: Text(choice,
                                  textAlign: TextAlign.center,
                                  style:
                                      const TextStyle(color: Colors.white)))));
                }),
        ]));
  }
}
