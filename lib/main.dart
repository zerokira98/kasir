import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:catatbeli/bloc/stock/insertstock_bloc.dart';
import 'package:catatbeli/bloc/stockview/stockview_bloc.dart';
import 'package:catatbeli/page/insert_stock/insert_stock.dart';
import 'package:catatbeli/msc/bloc_observer.dart';
import 'package:catatbeli/msc/db_moor.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:sqlite3/open.dart';

main() {
  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.linux, _openOnWindows);
    final db = sql.sqlite3.openInMemory();
    db.dispose();
  }
  WidgetsFlutterBinding.ensureInitialized();
  // Bloc = NewBlocObserver();
  BlocOverrides.runZoned(
    () => runApp(App()),
    blocObserver: NewBlocObserver(),
  );
  // runApp(App());
  if (Platform.isWindows) {
    doWhenWindowReady(() {
      appWindow.size = Size(480, 720);
      appWindow.minSize = Size(480, 720);
      appWindow.maximize();
      appWindow.show();
    });
  }
}

ffi.DynamicLibrary _openOnWindows() {
  final script = File(Platform.script.toFilePath(windows: true));
  print(script.path);
  final libraryNextToScript = File('${script.path}/sqlite3.dll');
  return ffi.DynamicLibrary.open(libraryNextToScript.path);
}

class App extends StatelessWidget {
  App({
    Key? key,
  }) : super(key: key);

  final pageC = PageController();

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => MyDatabase(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                InsertstockBloc(RepositoryProvider.of<MyDatabase>(context))
                  ..add(Initiate()),
          ),
          BlocProvider(
              create: (context) =>
                  StockviewBloc(RepositoryProvider.of<MyDatabase>(context))
                    ..add(InitiateView())),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          // themeMode: ThemeMode.dark,
          darkTheme: ThemeData.dark(),
          theme: ThemeData(fontFamily: 'OpenSans'),
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    if (snapshot.data!.getBool('firstStart') == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        // Add Your Code here.

                        showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Text(
                                      'It\'s my first app. Lots of bugs is expected. :)'),
                                ),
                              );
                            });
                        snapshot.data!.setBool('firstStart', false);
                      });
                    }
                  }
                  return Container(
                    // decoration: BoxDecoration(
                    //     borderRadius:
                    //         BorderRadius.only(topLeft: Radius.circular(18.0))),
                    child: (Platform.isWindows)
                        ? CustomWindow(
                            child: PageView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: 1,
                                controller: pageC,
                                itemBuilder: (context, i) {
                                  if (i == 0) return InsertProductPage();
                                  // if (i == 1) return MorePage();
                                  return CircularProgressIndicator();
                                }),
                          )
                        : InsertProductPage(),
                  );
                }),
          ),
        ),
      ),
    );
  }
}

class Bottoms extends StatefulWidget {
  final PageController pc;
  const Bottoms({Key? key, required this.pc}) : super(key: key);

  @override
  _BottomsState createState() => _BottomsState();
}

class _BottomsState extends State<Bottoms> {
  int navIndex = 0;
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          setState(() {
            navIndex = i;
          });
          widget.pc.animateToPage(i,
              duration: Duration(milliseconds: 500), curve: Curves.ease);
        },
        currentIndex: navIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add New'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'More'),
        ]);
  }
}

class WindowButtons extends StatelessWidget {
  WindowButtons({Key? key}) : super(key: key);
  final col =
      WindowButtonColors(iconNormal: Colors.white, mouseOver: Colors.black54);
  final colex = WindowButtonColors(
    iconNormal: Colors.white,
    mouseOver: Colors.red,
  );
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(
          colors: col,
        ),
        MaximizeWindowButton(
          colors: col,
        ),
        CloseWindowButton(
          colors: colex,
        ),
      ],
    );
  }
}

class CustomWindow extends StatelessWidget {
  final Widget child;
  const CustomWindow({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WindowTitleBarBox(
            child: Container(
          // color: Colors.blue,
          decoration: BoxDecoration(
            // borderRadius:
            //     BorderRadius.only(topLeft: Radius.circular(18.0)),
            gradient: LinearGradient(
                colors: [
                  Colors.black,
                  Colors.grey.shade900,
                  Colors.grey.shade900,
                ],
                // stops: [],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
          ),
          child:
              Row(children: [Expanded(child: MoveWindow()), WindowButtons()]),
        )),
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
