import 'package:flutter/material.dart';
import 'cooking_page.dart';
import 'party_page.dart';
import 'ingridients_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final route = MaterialPageRoute(builder: (context) => IngriPage());

    @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: const Text('Калькулятор игридиентов'),
                actions: <Widget>[
                  Builder(
                    builder: (context) {
                      return IconButton(
                        onPressed: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => const IngriPage()),
                            );
                        },
                        tooltip: 'settings',
                        icon: const Icon(Icons.settings),
                      );
                    }
                  ),
                ],
                bottom: const TabBar(
                  tabs: [
                    Tab(child: Text('Рецепты')),
                    Tab(child: Text('Мероприятия')),
                  ],
                ),
              ),
              body: SizedBox(
                height: 640.0,
                child: TabBarView(
                  children: [
                    CookingPage(),
                    PartyPage()
                  ],
                ),
              ),
            ),
            ],
        ),
      ),
    );
  }
}
 