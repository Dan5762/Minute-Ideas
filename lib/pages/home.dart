import 'package:flutter/material.dart';

import 'package:MinuteIdeas/pages/idea.dart';
import 'package:MinuteIdeas/widgets/button.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Center(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      const Spacer(flex: 2),
                      SizedBox(
                          height: 144,
                          width: 144,
                          child: Stack(children: [
                            Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                    height: 72,
                                    width: 72,
                                    decoration: BoxDecoration(
                                        color: Colors.purple[900],
                                        shape: BoxShape.circle))),
                            Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                    height: 72,
                                    width: 72,
                                    decoration: BoxDecoration(
                                        color: Colors.cyan[900],
                                        shape: BoxShape.circle))),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                    height: 72,
                                    width: 72,
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle))),
                            Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                    height: 72,
                                    width: 72,
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle)))
                          ])),
                      const Text('Minute Ideas',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold)),
                      const Spacer(flex: 1),
                      Button(
                          text: 'New Idea',
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const IdeaPage()))),
                      const Spacer()
                    ])))));
  }
}
