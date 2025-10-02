import 'package:flutter/material.dart';
import 'fitness.dart';
import 'AcademicsApp.dart';
import 'diet.dart';
import 'home.dart';
import 'DatabaseHelper.dart';
import 'package:sqflite/sqflite.dart'; 

class AcademicsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AcademicsApp(),
    );
  }
}

class FitnessPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const MyHomePage(title: 'Fitness Tracker'),
    );
  }
}

class DietingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const dietPage(),
    );
  }
}

Map<String, Color> eventColors = {
  "Meeting": Colors.red[100]!,
  "Workout": Colors.green[100]!,
  "Class": Colors.blue[100]!,
};

List<Map<String, String>> events = [
  {"title": "CIS 4030", "desc": "Mobile Computing", "time": "8:30am", "type": "Class"},
  {"title": "Gym Session", "desc": "Leg Day", "time": "9:30am", "type": "Workout"},
  {"title": "CIS 4030", "desc": "Project Meeting - Milestone 2", "time": "11:30am", "type": "Meeting"},
  {"title": "CIS 3750", "desc": "System Analysis", "time": "2:00pm", "type": "Class"},
  {"title": "STAT 2040", "desc": "Statistics 1", "time": "4:00pm", "type": "Class"},
];

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// to test if the database is persisting data (can be used elsewhere)
Future<void> testDatabase() async {
  var db = await DatabaseHelper.instance.database;

  await db.insert(
    'Fitness', 
    {'name': 'Running', 'duration': '30min'}, 
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  
  var result = await db.query('Fitness');
  print('Database Test Query Result: $result');  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather & Events App',
      // theme: ThemeData(
      //   primarySwatch: Colors.blue,
      // ),
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color.fromARGB(255, 20, 18, 24),
        primaryColor: Color.fromARGB(255, 50, 48, 54),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 20, 18, 24)
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: Color.fromARGB(255, 50, 48, 54),
        )
      ),
      //preferred for mine
      // themeMode: ThemeMode.dark,  // Forces dark mode
      // theme: ThemeData.dark().copyWith(
      //   colorScheme: ColorScheme.dark(
      //     primary: Colors.blue,  // Primary color for your theme
      //     secondary: Colors.blueAccent,  // Secondary color (replaces accentColor)
      //   ),
      // ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPage = 0;

  final List<Widget> pages = [
    OutsideHome(),  // Navigate to OutsideHome (Home Page)
    AcademicsPage(), // Navigate to academics
    FitnessPage(),   // Navigate to fitness
    DietingPage(),   // Navigate to dieting
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void selectPage(int index) {
    setState(() {
      currentPage = index;
    });
    Navigator.pop(context);  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "The Student Blueprint",
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            _drawerItem(Icons.home, "Home", context, 0),
            _drawerItem(Icons.school, "Academics", context, 1),
            _drawerItem(Icons.fitness_center, "Fitness", context, 2),
            _drawerItem(Icons.fastfood, "Dieting", context, 3),
          ],
        ),
      ),
      body: FutureBuilder<Database>(
        future: DatabaseHelper.instance.database, // database called asynchronously
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            // database has been initialized, now can proceed to other actions
            return IndexedStack(
              index: currentPage,
              children: pages,
            );
          } else {
            return const Center(child: Text('Unknown error occurred'));
          }
        },
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, BuildContext context, int pageIndex) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        selectPage(pageIndex);  // change to selected page
      },
    );
  }
}
