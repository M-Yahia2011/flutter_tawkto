import 'package:flutter/material.dart';
import 'package:flutter_tawkto/flutter_tawk.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Tawk'),
          backgroundColor: const Color(0XFFF7931E),
          elevation: 0,
        ),
        body: Tawk(
          directChatLink: '',
          user: TawkUser(
            id: '123456789',
            userName: 'Ayoub AMINE',
            phone: '0658745632',
          ),
          onLoad: () {
            debugPrint('Hello Tawk!');
          },
          onLinkTap: (String url) {
            debugPrint(url);
          },
          placeholder: const Center(
            child: Text('Loading...'),
          ),
        ),
      ),
    );
  }
}
