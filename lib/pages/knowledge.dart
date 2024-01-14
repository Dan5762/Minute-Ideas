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

class Knowledge extends StatefulWidget {
  const Knowledge({Key? key}) : super(key: key);

  @override
  State<Knowledge> createState() => _KnowledgeState();
}

class _KnowledgeState extends State<Knowledge> {
  int currentIndex = 0;
  static const _pageSize = 5;

  final PagingController<int, Idea> _pagingController =
      PagingController(firstPageKey: 0, invisibleItemsThreshold: 3);

  Future<void> _fetchPage(int pageKey, FeedModel feedModel) async {
    List<Idea> knowledgeIdeas = await feedModel.getKnowledgeIdeas(_pageSize);

    while (knowledgeIdeas.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 50));
      knowledgeIdeas = await feedModel.getKnowledgeIdeas(_pageSize);
    }

    try {
      final newItems = knowledgeIdeas;
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
                          itemBuilder: (context, idea, _) =>
                              IdeaCard(idea: idea))))));
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
