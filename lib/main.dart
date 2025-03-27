import 'dart:math';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// 主入口
void main() {
  // 运行myapp
  runApp(MyApp());
}

/*
  StatelessWidget 创建一个widget 部件
 */
class MyApp extends StatelessWidget {
  const MyApp({super.key}); //集成父级的key 提高渲染性能，就跟vue for循环的key标记一样

  @override //重写父类
  //构建方法，返回一个widget 部件
  Widget build(BuildContext context) {
    //创建一个provider 提供数据
    return ChangeNotifierProvider(
      create: (context) => MyAppState(), //创建时运行 初始状态类
      child: MaterialApp(
        //一般放在顶级 提供MaterialDesign风格的UI组件
        title: 'App name', //APP标题 显示在顶部
        theme: ThemeData(
          //主题，使用MaterialDesign风格的UI组件
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(), //内容渲染
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

/*
  主要内容渲染
  StateFulWidget 用于需要维护状态的组件
  进行UI和状态分离，这样渲染时不会让组件内的状态丢失
 */
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/*
  状态类，用于维护状态
  渲染时会调用build方法，返回一个widget 部件
 */
class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page; //定义一个部件变量 用于存储目前渲染的部件
    switch (selectedIndex) {
      // 根据变量渲染不同的部件
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError();
    }

    // 布局容器，用于自适应布局
    return LayoutBuilder(
      builder: (context, constraints) {
        /*
          SafeArea 用于防止内容被状态栏遮挡
          NavigationRail 用于显示导航栏
          NavigationRailDestination 用于显示导航栏项
         */
        SafeArea menu = SafeArea(
          child: NavigationRail(
            extended: constraints.maxWidth >= 600, //宽度大于600时会展开
            destinations: [
              //导航栏
              NavigationRailDestination(
                icon: Icon(Icons.home), //图标
                label: Text('Home'), //在展开的时候显示文字
              ),
              NavigationRailDestination(
                icon: Icon(Icons.favorite),
                label: Text('Favorites'),
              ),
            ],
            selectedIndex: selectedIndex, //导航栏显示的索引 0是第一个
            onDestinationSelected: (value) {
              //点击导航栏 更新索引
              print('selected: $value');
              setState(() {
                selectedIndex = value;
              });
            },
          ),
        );
        // 底部tab栏
        BottomNavigationBar bottomNavigationBar = BottomNavigationBar(
          currentIndex: selectedIndex, //当前选中的索引
          onTap: (value) {
            //点击tab栏 更新索引
            setState(() {
              selectedIndex = value;
            });
          },
          // 底部tab栏项
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ), //图标和文字
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
          ],
        );
        // 主体部分
        Expanded main = Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: page,
          ),
        );

        if (constraints.maxWidth < 450) {
          //大小小于450时的骨架 有body和底部栏
          return Scaffold(
            body: main,
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                print('add favorite');
              },
              child: Icon(Icons.add),
            ),
          );
        } else {
          //其他比较大的时候 就主体部分 然后分左右两个
          return Scaffold(body: Row(children: [menu, main]));
        }
      },
    );
  }
}

/*
  收藏页面
  显示喜欢的列表
  点击删除按钮 从列表中删除
 */
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

/*
  生成页面
  显示随机的单词对
  点击喜欢按钮 加入收藏
 */
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

/*
  大卡片 中间的大红卡片
  显示随机的单词对
 */
class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  }); //集成父级的key 提高渲染性能，就跟vue for循环的key标记一样 required表示必须传递

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

/*
  历史列表 显示历史记录
  点击删除按钮 从列表中删除
 */
class HistoryListView extends StatefulWidget {
  const HistoryListView({Key? key}) : super(key: key);

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

/*
  历史列表的状态类 用于维护状态
  渲染时会调用build方法，返回一个widget 部件
  点击删除按钮 触发removeHistory方法
  点击喜欢按钮 触发totalHistory方法
 */
class _HistoryListViewState extends State<HistoryListView> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    /*
      构建喜欢的单项
      参数是一个HistoryItem对象 表示一个历史记录
      返回一个widget 部件
    */
    Widget buildFavoriteItem(HistoryItem item, Animation<double> animation) {
      return SizeTransition(
        sizeFactor: animation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
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
    }

    /*
      有动画的列表
      列表项为AnimatedList中的每一项，使用Animation<double>来表示列表项的动画状态
      列表项的动画状态由appState.historyAnimatedListController来控制
      列表项的key为appState.historyKey
    */
    AnimatedList favoriteList = AnimatedList(
      controller: appState.historyAnimatedListController,
      key: appState.historyKey,
      initialItemCount: appState.history.length,
      itemBuilder: (context, index, animation) {
        var item = appState.history[index];
        return buildFavoriteItem(item, animation); //渲染每一项
      },
    );

    /*
      遮罩层
      用于将列表项的动画状态应用到列表项上
      遮罩层的shaderCallback方法用于创建一个渐变效果
      遮罩层的blendMode属性用于指定混合模式
     */
    ShaderMask shaderMask = ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black], //第一个是透明 第二个是黑色
          stops: [
            0.0,
            0.2,
          ], //这里两个 就是上面的colors两个 指的是 第一个颜色从0.0开始 到0.2的时候开始渲染第二个颜色 渐变过来的
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn, //这个模式 就是黑色的部分会显示出来 其他的部分会透明
      child: favoriteList,
    );
    return shaderMask;
  }
}
