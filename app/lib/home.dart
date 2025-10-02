import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
 import 'package:intl/intl.dart';
import 'dart:developer' as developer;

import 'fitness.dart';
import 'AcademicsApp.dart';  
import 'diet.dart';
import 'main.dart';

import 'dart:async';
import 'dart:convert';


/* 
NOTE:
THIS FILE DEPENDS ON DATA TO BE RETRIEVED 
FROM THE SQL DATABASE CREATED IN ACADEMICSAPP.DART
*/

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


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather & Events App',
      home: const OutsideHome(),
    );
  }
}

int getCurrentDay() {
  return DateTime.now().day;
}

class OutsideHome extends StatefulWidget {
  const OutsideHome({super.key});

  @override
  State<OutsideHome> createState() => _OutsideHomeState();
}

class _OutsideHomeState extends State<OutsideHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future fetchWeather() async {
    var data = await http.get(Uri.parse('http://api.weatherapi.com/v1/current.json?key=5679697ff4944115b9d30933251801&q=43.52762494,-80.22396808'));
    var parsed = jsonDecode(data.body);
    return parsed;
  }

  Map<String, Color> eventColors = {
    "Meeting": Colors.red[500]!,
    "Workout": Colors.green[500]!,
    "Class": Colors.blue[500]!, 
    "Study": Colors.orange[500]!,
    "Exam": Colors.purple[500]!, 
  };

  List<Map<String, String>> events = [
    {"title": "Gym Session", "desc": "Goodlife Fitness", "time": "9:30am", "month": "April", "day": "4", "type": "Workout", "critical": "false"},
    {"title": "Exam Prep - CIS 3750", "desc": "System Analysis and Design in Applications", "time": "10:00am", "month": "April", "day": "4", "type": "Study", "critical": "false"},
    {"title": "CIS 4030", "desc": "Project Meeting - Milestone 2", "time": "11:30am", "month": "April", "day": "4", "type": "Meeting", "critical": "false"},
    {"title": "CIS 3750", "desc": "System Analysis", "time": "2:00pm", "month": "April", "day": "4", "type": "Class", "critical": "false"},
    {"title": "STAT 2040", "desc": "Statistics 1", "time": "4:00pm", "month": "April", "day": "3", "type": "Class", "critical": "false"},
    {"title": "Cryptography Exam", "desc": "exam", "time": "8:30am", "month": "April", "day": "8", "type": "Exam", "critical": "true"},

  ];

  //NOTE: GET DATA FROM DATABASE
  Future<void> loadFitnessData(String weekday) async {
    final database = openDatabase(
      join(await getDatabasesPath(), 'fitness.db'),
    );

    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'Fitness',
      where: 'weekday = ?',
      whereArgs: [weekday],
    );
    
    for (var row in results) {
      events.add({
        "title": row["workout_name"] ?? "Workout",
        "desc": "Sets/Reps: ${row["sets_reps"]}, Weight: ${row["weight"]}kg",
        "time": "TBD",
        "type": "Workout",
        "critical": "false"
      });
    }
  }

  Future<void> loadAcademicData(int month, int day, int year) async {
    final database = openDatabase(
      join(await getDatabasesPath(), 'events.db'),
    );

    final db = await database;

    final List<Map<String, dynamic>> eventResults = await db.query(
      'events',
      where: 'month = ? AND day = ? AND year = ?',
      whereArgs: [month, day, year],
    );
    
    for (var row in eventResults) {
      
      bool eventExists = events.any((event) =>
        event["title"] == (row["eventName"] ?? "Event") &&
        event["desc"] == "${row["eventDescription"]}"
      );
      
      if (!eventExists) {
        setState(() {
          events.add({
          "title": row["eventName"] ?? "Event",
          "desc": "${row["eventDescription"]}",
          "time": "TBD",
          "type": "Event",
          "critical": row["importance"] == 1 ? "true" : "false"
        });
        });
      }
    }
  }

  Future<void> clearEventsTable() async {
    final database = openDatabase(
      join(await getDatabasesPath(), 'events.db'),
    );

    final db = await database;
    await db.delete('events'); // Deletes all rows but keeps the table
  }

  void loadData() {
    loadFitnessData("April 2nd");
    loadAcademicData(4, 2, 2025);
  }

  @override
  Widget build(BuildContext context) {
    loadData();
    return Scaffold(
      key: _scaffoldKey,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // weather information
            FutureBuilder(
              future: fetchWeather(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Error loading weather"),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Current Weather in Guelph:",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Image.network(
                          "https:${snapshot.data["current"]["condition"]["icon"]}", // icon representing weather status
                          width: 50,
                          height: 50,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${snapshot.data["current"]["temp_c"]}°C",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            // "Legend" section with curved border
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 5)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 16.0,
                        runSpacing: 8.0,
                        children: eventColors.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: entry.value,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.key, // Event name like "Meeting", "Workout", etc.
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // "Critical" section with red border
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red), // Red border
                  boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 5)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Critical",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 100,  // Smaller height to show only 3 events
                        child: ListView.builder(
                          itemCount: (events.where((event) =>
                                              event["critical"] == "true")
                                              .length / 3).ceil(),
                          itemBuilder: (context, pageIndex) {
                            List<Map<String, String>> criticalEvents = events.where((event) => event["critical"] == "true").toList();
                            int start = pageIndex * 3;
                            int end = (start + 3 > criticalEvents.length) ? criticalEvents.length : start + 3;
                            List<Map<String, String>> eventsToShow = criticalEvents.sublist(start, end);

                            return Column(
                              children: eventsToShow.map((event) {
                                
                                String eventType = event["type"]!;
                                String desc = event["desc"]!;
                                String time = event["time"]!;
                                Color eventColor = eventColors[eventType] ?? Colors.grey[200]!;

                                return Card(
                                  margin: const EdgeInsets.all(8.0),
                                  color: eventColor,
                                  child: ListTile(
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          event["title"]!,
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        Text(
                                          time,
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      "Description: $desc",
                                      style: TextStyle(color: Colors.black),
                                      ),
                                    onTap: () => _showHackathonPopup(context),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 5)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Upcoming",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // List of events, excluding the Hackathon, shown here
                      Container(
                        height: 200,  // Smaller height to show only 3 events
                        child: ListView.builder(
                          itemCount: (events.where((event) =>
                                              event["day"] == getCurrentDay().toString() &&
                                              event["month"] == DateFormat.MMMM().format(DateTime.now()))
                                              .length / 3).ceil(),  // Show multiple pages
                          itemBuilder: (context, pageIndex) {
                            List<Map<String, String>> currentEvents = events.where((event) => 
                                                                      event["day"] == getCurrentDay().toString() &&
                                                                      event["month"] == DateFormat.MMMM().format(DateTime.now()))
                                                                      .toList();
                            int start = pageIndex * 3;
                            int end = (start + 3 > currentEvents.length) ? currentEvents.length : start + 3;
                            List<Map<String, String>> eventsToShow = currentEvents.sublist(start, end);

                            return Column(
                              children: eventsToShow.map((event) {
                                String eventType = event["type"]!;
                                String desc = event["desc"]!;
                                String time = event["time"]!;
                                Color eventColor = eventColors[eventType] ?? Colors.grey[200]!;

                                return Card(
                                  margin: const EdgeInsets.all(8.0),
                                  color: eventColor,
                                  child: ListTile(
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          event["title"]!,
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        Text(
                                          time,
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      "Description: $desc",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Grid of icons (Academics, Fitness, Dieting)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _gridItem(Icons.school, "Academics", context, true), // Show popup for Academics
                  _gridItem(Icons.fitness_center, "Fitness", context, false), // Navigate to FitnessPage
                  _gridItem(Icons.fastfood, "Dieting", context, true), // Show popup for Dieting
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridItem(IconData icon, String title, BuildContext context, bool isPopup) {
    return GestureDetector(
      onTap: () {
        if (isPopup) {
          if (title == "Academics") {
            _showAcademicsPopup(context); // Trigger the Academics popup
          } else if (title == "Dieting") {
            _showDietingPopup(context); // Trigger the Dieting popup
          }
        } else {
          if (title == "Academics") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AcademicsApp()), // Navigate to academics
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FitnessPage()), // Navigate to fintess
            );
          }
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

void _showAcademicsPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.all(20.0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "CIS4030 M3 Due Sat, March 22 at 11:59 PM",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("-> Academics"),
            ),
          ],
        ),
      );
    },
  );
}

// Show Dieting Popup
void _showDietingPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.all(20.0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "2 days worth of meals remaining.",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("-> Dieting"),
            ),
          ],
        ),
      );
    },
  );
}

// Show Hackathon Signup Popup
void _showHackathonPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.all(20.0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Sign Up: https://lu.ma/xzuzu2me",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    },
  );
}

