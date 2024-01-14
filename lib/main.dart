import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';

import 'package:MinuteIdeas/pages/feed.dart';
import 'package:MinuteIdeas/models/feed.dart';
import 'package:MinuteIdeas/pages/profile.dart';

void main() {
  runApp(ChangeNotifierProvider(
      create: (context) => FeedModel(), child: const MyApp()));
}

final ValueNotifier<bool> showProfile = ValueNotifier<bool>(false);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
        title: 'Minute Ideas',
        home: CupertinoTabScaffold(
            tabBar: CupertinoTabBar(
                currentIndex: 0,
                backgroundColor: const Color.fromARGB(255, 36, 36, 36),
                activeColor: Colors.white,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.lightbulb), label: 'Facts'),
                  BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.profile_circled),
                      label: 'Profile')
                ]),
            tabBuilder: (BuildContext context, int index) {
              return CupertinoTabView(builder: (BuildContext context) {
                switch (index) {
                  case 1:
                    return const Profile();
                  default:
                    return const Feed();
                }
              });
            }),
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(brightness: Brightness.light));
  }
}

const int _blackPrimaryValue = 0xFF000000;
const MaterialColor primaryBlack =
    MaterialColor(_blackPrimaryValue, <int, Color>{
  50: Color(0xFF000000),
  100: Color(0xFF000000),
  200: Color(0xFF000000),
  300: Color(0xFF000000),
  400: Color(0xFF000000),
  500: Color(_blackPrimaryValue),
  600: Color(0xFF000000),
  700: Color(0xFF000000),
  800: Color(0xFF000000),
  900: Color(0xFF000000)
});
