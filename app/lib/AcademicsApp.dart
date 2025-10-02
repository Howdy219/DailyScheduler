import 'package:flutter/material.dart';
import 'academicsDatabase.dart';
import 'package:intl/intl.dart';

class AcademicsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AcademicsScreen(),
    );
  }
}

class AcademicsScreen extends StatefulWidget {
  @override
  _AcademicsScreenState createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Map<String, dynamic>> courses = [];
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  

  void _loadEventsForSelectedDate() async {
      List<Map<String, dynamic>> events = await _databaseService.getEvents(
        _selectedDate.month,
        _selectedDate.day,
        _selectedDate.year,
      );

      setState(() {
          _events[_selectedDate] = events.map((event) {
              return {
                  "title": event['eventName'],
                  "description": event['eventDescription'],
                  "important": event['importance'] == 1, 
                  "day": _selectedDate.day,  
                  "month": _selectedDate.month,  
                  "year": _selectedDate.year,  
              };
          }).toList();
      });
  }


  void _printDatabaseState() {
    
    print("Courses: ");
    for (var course in courses) {
      print("Course: ${course['name']}");
      print("  Credits: ${course['credits']}");
      print("  Grade: ${course['grade']?.toString() ?? 'N/A'}");
      print("  Assignments: ");
      for (var assignment in course['assignments']) {
        print("    Assignment: ${assignment['name']}");
        print("      Grade: ${assignment['grade']}");
        print("      Worth: ${(assignment['worth'] * 100)}%");
      }
    }

    
    print("Events for ${DateFormat.yMMMd().format(_selectedDate)}: ");
    var eventsForSelectedDate = _events[_selectedDate];
    if (eventsForSelectedDate != null) {
      for (var event in eventsForSelectedDate) {
        print("  Event: ${event['title']}");
        print("    Description: ${event['description']}");
        print("    Important: ${event['important']}");
        print("    Date: ${event['day']}");
        print("    Date: ${event['month']}");
        print("    Date: ${event['year']}");
      }
    } else {
      print("  No events for this date.");
    }
}


  void _addEvent() {
  TextEditingController eventController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  bool isImportant = false; 

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Add Event", style: TextStyle(color: Color.fromARGB(255, 20, 18, 24))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: eventController,
                  decoration: InputDecoration(hintText: "Enter event title"),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(hintText: "Enter event description"),
                ),
                CheckboxListTile(
                  title: Text("Mark as Important"),
                  value: isImportant,
                  onChanged: (newValue) {
                    setStateDialog(() {
                      isImportant = newValue ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {
                  if (eventController.text.trim().isNotEmpty) {
                    
                    _databaseService.addTask(
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedDate.year,
                      eventController.text.trim(),
                      descriptionController.text.trim(),
                      isImportant ? 1 : 0,
                    ).then((id) {

                      setState(() {
                          DateTime dateKey = DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                          );

                          List<Map<String, dynamic>> updatedEvents = List.from(_events[dateKey] ?? []);
                          updatedEvents.add({
                              "title": eventController.text.trim(),
                              "description": descriptionController.text.trim(),
                              "important": isImportant,
                              "day": _selectedDate.day,  
                              "month": _selectedDate.month,  
                              "year": _selectedDate.year,  
                          });

                          _events[dateKey] = updatedEvents;
                      });


                      Navigator.pop(context);
                     
                      Future.delayed(Duration(milliseconds: 100), () {
                        setState(() {
                          _selectedDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                          );
                           _printDatabaseState();
                        });
                      });
                    });
                  }
                },
                child: Text("Add Event"),
              ),
            ],
          );
        },
      );
    },
  );
}


  void _removeEvent(Map<String, dynamic> event) {
    setState(() {
      _events[_selectedDate]?.remove(event);
    });
  }

  double? _calculateAverageGrade() {
    bool hasValidGrades = false;
    int reverseCourseCounter = 0;
    if (courses.isEmpty) return null;

    double totalGrade = 0.0;
    for (var course in courses) {
      if (course['grade'] != null) {
        totalGrade += course['grade'];
        hasValidGrades = true;
      } else {
        reverseCourseCounter += 1;
      }
    }
    return hasValidGrades ? (totalGrade / (courses.length - reverseCourseCounter)) : null;
  }

  void _addCourse() {
    TextEditingController nameController = TextEditingController();
    TextEditingController creditsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Course"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(hintText: "Enter course name"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: creditsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: "Enter credits"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                String name = nameController.text.trim();
                double credits = double.tryParse(creditsController.text) ?? 0.0;
                

                if (name.isNotEmpty && credits > 0) {
                  

                  setState(() {
                    courses.add({
                      "name": name,
                      "credits": credits,
                      "grade": null,
                      "assignments": [],
                    });
                    _printDatabaseState();
                  });

                  Navigator.pop(context);
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }


  void _addAssignment(int index) {
    TextEditingController assignmentNameController = TextEditingController();
    TextEditingController assignmentWorthController = TextEditingController();
    TextEditingController assignmentGradeController = TextEditingController();
    _databaseService.deleteDatabaseFile();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Assignment to ${courses[index]['name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: assignmentNameController, decoration: InputDecoration(hintText: "Enter assignment name")),
            TextField(controller: assignmentWorthController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: "Enter assignment worth (%)")),
            TextField(controller: assignmentGradeController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: "Enter grade (0-100)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              String assignmentName = assignmentNameController.text;
              double worth = double.tryParse(assignmentWorthController.text) ?? 0.0;
              double grade = double.tryParse(assignmentGradeController.text) ?? 0.0;
              //String courseName = courses[index]['name'];
              //_calculateCourseGrade(index);
              //int id = await _databaseService.addAssignment(assignmentName, worth, courseName, courses[index]['grade'].toDouble());

              setState(() {
                courses[index]['assignments'].add({
                  "name": assignmentName,
                  "worth": worth/100,
                  "grade": grade,
                });
                _calculateCourseGrade(index);

              });

              Navigator.pop(context);
            },
            child: Text("Add Assignment"),
          ),
        ],
      ),
    );
}

  void _calculateCourseGrade(int index) {
    double totalWorth = 0.0;
    double weightedGrade = 0.0;

    for (var assignment in courses[index]['assignments']) {
      double? grade = assignment['grade'];
      double worth = assignment['worth'];

      if (grade != null && grade >= 0.0) {
        totalWorth += worth;
        weightedGrade += (grade * (worth));
      }
    }

    double grade = totalWorth > 0 ? (weightedGrade / totalWorth) : 0.0;

    setState(() {
      courses[index]['grade'] = grade.round();
      _calculateGPA();
    });
  }

  double? _calculateGPA() {
    double totalCredits = 0;
    double totalPoints = 0;
    bool hasValidGrades = false;

    for (var course in courses) {
      if (course['grade'] != null) {
        double grade = (course['grade'] as num).toDouble();
        double gradePoint = _convertToGradePoint(grade);
        double credits = (course['credits'] as num).toDouble();

        totalCredits += credits;
        totalPoints += gradePoint * credits;
        hasValidGrades = true;
      }
    }

    return hasValidGrades ? (totalPoints / totalCredits) : null;
  }

  double _convertToGradePoint(double score) {
    if (score >= 90) return 4.0;
    if (score >= 85) return 3.9;
    if (score >= 80) return 3.7;
    if (score >= 75) return 3.3;
    if (score >= 70) return 3.0;
    if (score >= 65) return 2.7;
    if (score >= 60) return 2.3;
    if (score >= 55) return 2.0;
    if (score >= 50) return 1.7;
    return 0.0;
  }

  String _convertToLetterGrade(double score) {
    if (score >= 90) return "A+";
    if (score >= 85) return "A";
    if (score >= 80) return "A-";
    if (score >= 77) return "B+";
    if (score >= 73) return "B";
    if (score >= 70) return "B-";
    if (score >= 65) return "C+";
    if (score >= 60) return "C";
    if (score >= 55) return "C-";
    if (score >= 50) return "D";
    return "F";
  }

  void _editAssignment(int courseIndex, int assignmentIndex) {
    TextEditingController newGradeController = TextEditingController();
    TextEditingController newWorthController = TextEditingController();

    newGradeController.text = courses[courseIndex]['assignments'][assignmentIndex]['grade'].toString();
    newWorthController.text =
        (courses[courseIndex]['assignments'][assignmentIndex]['worth'] * 100).toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Grade and new Worth"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newGradeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: "Enter new grade (0-100)"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: newWorthController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: "Enter new worth (%)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              setState(() {
                double newGrade = double.tryParse(newGradeController.text) ?? 0.0;
                double newWorth = (double.tryParse(newWorthController.text) ?? 0.0) / 100;
                courses[courseIndex]['assignments'][assignmentIndex]['grade'] = newGrade;
                courses[courseIndex]['assignments'][assignmentIndex]['worth'] = newWorth;

                _calculateCourseGrade(courseIndex);
              });
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _removeAssignment(int courseIndex, int assignmentIndex) {
    setState(() {
      courses[courseIndex]['assignments'].removeAt(assignmentIndex);
      _calculateCourseGrade(courseIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    double? averageGrade = _calculateAverageGrade();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Academics",
          style: TextStyle(color: Colors.white), // Title text color
        ),
        backgroundColor: Color.fromARGB(255, 20, 18, 24), // Custom background color
      ),
      backgroundColor: Color.fromARGB(255, 20, 18, 24),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                "Average Grade: ${averageGrade != null ? averageGrade.toStringAsFixed(2) : "N/A"}",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                "GPA: ${averageGrade != null ? _convertToGradePoint(averageGrade).toStringAsFixed(2) : "N/A"} | "
                "Letter Grade: ${averageGrade != null ? _convertToLetterGrade(averageGrade) : "N/A"}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Courses:", style: TextStyle(fontSize: 18, color: Colors.white)),
                  SizedBox(height: 10),
                  ListView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: courses.map((course) {
                      return Card(
                        color: Color.fromARGB(255, 50, 48, 54),
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${course['name']} - ${course['credits']} credits - Grade: ${course['grade']?.toStringAsFixed(2) ?? 'N/A'}",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color:Colors.white),
                              ),
                              SizedBox(height: 10),
                              SingleChildScrollView(
                                child: Column(
                                  children: course['assignments'].map<Widget>((assignment) {
                                    return ListTile(
                                      title: Text(assignment['name'], style:TextStyle(color: Colors.white)),
                                      subtitle: Text(
                                          "Grade: ${assignment['grade']}%, Worth: ${(assignment['worth'] * 100).toStringAsFixed(2)}%",style:TextStyle(color: Colors.white)) ,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                            onPressed: () => _editAssignment(
                                                courses.indexOf(course),
                                                course['assignments'].indexOf(assignment)),
                                            child: Text("Edit"),
                                          ),
                                          SizedBox(width: 5),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                            onPressed: () => _removeAssignment(
                                                courses.indexOf(course),
                                                course['assignments'].indexOf(assignment)),
                                            child: Text("Remove"),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                onPressed: () => _addAssignment(courses.indexOf(course)),
                                child: Text("Add Assignment",style:TextStyle(color: Color.fromARGB(255, 20, 18, 24))),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: _addCourse,
                    child: Text("Add Course", style:TextStyle(color: Color.fromARGB(255, 20, 18, 24))),
                  ),
                  SizedBox(height: 20),
                  Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Colors.white, // Change selected date highlight color
                        onPrimary: Color.fromARGB(255, 20, 18, 24), // Change text color on selected date
                        surface: Colors.white, // Background color
                        onSurface: Colors.white, // Default text color
                      ),
                      textTheme: TextTheme(
                        bodyLarge: TextStyle(color: Colors.white), // General text color
                        bodyMedium: TextStyle(color: Colors.white),
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDate = DateTime(date.year, date.month, date.day);
                        });
                        _loadEventsForSelectedDate(); 
                      },
                    ),
                  ),

                  SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: (){
                      
                      _addEvent();
                      setState((){});
                    } ,
                    child: Text("Add Event",style:TextStyle(color: Color.fromARGB(255, 20, 18, 24))),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Events for ${DateFormat.yMMMd().format(_selectedDate)}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _events[_selectedDate]?.length ?? 0,
                    itemBuilder: (context, index) {
                      var event = _events[_selectedDate]![index];
                      return Dismissible(
                        key: Key(event['title'] ?? "No Title"),
                        onDismissed: (direction) {
                          _removeEvent(event);
                        },
                        background: Container(color: Colors.red),
                        child: ListTile(
                          leading: event["important"] == true
                              ? Icon(Icons.error, color: Colors.red)
                              : null,
                          title: Text(event["title"] ?? "No Title",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          subtitle: Text(event["description"] ?? "No Description", style: TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}

