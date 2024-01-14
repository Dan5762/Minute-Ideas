import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:MinuteIdeas/models/feed.dart';
import 'package:MinuteIdeas/models/idea.dart';

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
  static const _pageSize = 5;

  final PagingController<int, Idea> _pagingController =
      PagingController(firstPageKey: 0, invisibleItemsThreshold: 3);

  Future<void> _fetchPage(int pageKey, FeedModel feedModel) async {
    List<Idea> recomendedIdeas = await feedModel.getRecomendedIdeas(_pageSize);

    while (recomendedIdeas.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 50));
      recomendedIdeas = await feedModel.getRecomendedIdeas(_pageSize);
    }

    try {
      final newItems = recomendedIdeas;
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
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
                      pagingController: _pagingController,
                      builderDelegate: PagedChildBuilderDelegate<Idea>(
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
                                      int nWords = countWords(idea.description);

                                      double weight =
                                          stopwatch.elapsed.inSeconds / nWords;
                                      weight = 1 -
                                          (1 /
                                              (weight + 1)); // limit to below 1

                                      feedModel.weightedUpdateUserVector(
                                          idea.embedding, 0.2);
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
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(idea.title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500)),
                      const Divider(height: 16),
                      Text(idea.description,
                          style: const TextStyle(fontSize: 16)),
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)))
                          ])
                    ]))));
  }
}
