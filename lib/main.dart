import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'App name',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class HistoryItem {
  final WordPair favorite;
  bool isFavorite;

  HistoryItem({required this.favorite, required this.isFavorite});
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var history = <HistoryItem>[];
  var historyKey = GlobalKey<AnimatedListState>();
  var historyAnimatedListController = ScrollController();

  void historyAnimatedListToBottom() {
    historyAnimatedListController.animateTo(
      historyAnimatedListController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void getNext() {
    // 记录上一次的current 并且查询是否喜欢
    history.add(
      HistoryItem(favorite: current, isFavorite: isFavorite(current)),
    );
    historyKey.currentState!.insertItem(history.length - 1);

    current = WordPair.random();
    notifyListeners();
    // 在渲染完成后滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      historyAnimatedListToBottom();
    });
  }

  void removeHistory(HistoryItem item) {
    final index = history.indexOf(item);
    if (index != -1) {
      history.removeAt(index);
      historyKey.currentState?.removeItem(
        index,
        (context, animation) => Center(child: Text('正在删除')),
      );
    }
  }

  void totalHistory(HistoryItem item) {
    // item.isFavorite=isFavorite()
    toggleFavorite(item.favorite);
    item.isFavorite = isFavorite(item.favorite);
    print(isFavorite(item.favorite));
  }

  var favorites = <WordPair>[];

  void toggleFavorite(WordPair favorite) {
    if (isFavorite(favorite)) {
      favorites.remove(favorite);
    } else {
      favorites.add(favorite);
    }
    notifyListeners();
  }

  void removeFavorite(WordPair favorite) {
    favorites.remove(favorite);
    notifyListeners();
  }

  bool isFavorite(WordPair favorite) {
    return favorites.contains(favorite);
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        SafeArea menu = SafeArea(
          child: NavigationRail(
            extended: constraints.maxWidth >= 600,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.favorite),
                label: Text('Favorites'),
              ),
            ],
            selectedIndex: selectedIndex,
            onDestinationSelected: (value) {
              print('selected: $value');
              setState(() {
                selectedIndex = value;
              });
            },
          ),
        );
        BottomNavigationBar bottomNavigationBar = BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (value) {
            setState(() {
              selectedIndex = value;
            });
          },
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
          ],
        );
        Expanded main = Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: page,
          ),
        );

        if (constraints.maxWidth < 450) {
          return Scaffold(body: main, bottomNavigationBar: bottomNavigationBar);
        } else {
          return Scaffold(body: Row(children: [menu, main]));
        }
      },
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(child: Text('No Favorites yet.'));
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have ${appState.favorites.length} favorites'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Row(
              children: [
                Text(pair.asSnakeCase),
                ElevatedButton(
                  onPressed: () {
                    print('remove favorite');
                    appState.removeFavorite(pair);
                  },
                  child: Icon(Icons.delete),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(flex: 3, child: HistoryListView()),
          SizedBox(height: 10),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                BigCard(pair: pair),
                SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        appState.toggleFavorite(appState.current);
                      },
                      icon: Icon(icon),
                      label: Text('Like'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        appState.getNext();
                      },
                      child: Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({super.key, required this.pair});

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: Colors.pink[600],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asSnakeCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

// 历史列表
class HistoryListView extends StatefulWidget {
  const HistoryListView({Key? key}) : super(key: key);

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
          stops: [0.0, 0.2],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        controller: appState.historyAnimatedListController,
        key: appState.historyKey,
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          var item = appState.history[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 10,
                  ),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          appState.totalHistory(item);
                        },
                        icon:
                            item.isFavorite
                                ? Icon(Icons.favorite)
                                : SizedBox.shrink(),
                        label: Text(item.favorite.asSnakeCase),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          appState.removeHistory(item);
                        },
                        child: Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
