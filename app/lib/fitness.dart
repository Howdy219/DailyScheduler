//diluxan's section

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // for date
import 'DatabaseHelper.dart'; // for database operations

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Portal',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,  
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,  
          secondary: Colors.blueAccent,  
        ),
      ),
      // theme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      //   useMaterial3: true,
      // ),
      home: const MyHomePage(title: 'Fitness'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? currentDay;
  final List<String> workouts = ['Squat', 'Deadlift', 'Bench'];
  late Future<List<Map<String, dynamic>>> dailyWorkouts; // store the workouts for the current day
  bool showPastWeights = false; // control the visibility of past 6 days weights

  
  bool isWeightEntered = false; 

  @override
  void initState() {
    super.initState();
    currentDay = _getCurrentDay();
    dailyWorkouts = _getDailyWorkouts(currentDay!); // get workouts from database for today
  }

  String _getCurrentDay() {
    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE').format(now); // 'EEEE' == full day name
    return dayOfWeek;
  }

  // get workouts for the current day
  Future<List<Map<String, dynamic>>> _getDailyWorkouts(String day) async {
    final dbHelper = DatabaseHelper.instance;
    final workouts = await dbHelper.getMostRecentWorkoutsForDay(day);
    return workouts; // rows for the current day
  }

  // to toggle the visibility of past 6 days' weights
  void _togglePastWeights() {
    setState(() {
      showPastWeights = !showPastWeights;
    });
  }

  // finish workout button handler method
  void _finishWorkout(
    List<Map<String, dynamic>> workoutsData,
    List<TextEditingController> setsRepsControllers,
    List<TextEditingController> weightControllers,
  ) async {
    final dbHelper = DatabaseHelper.instance;
    final currentDay = _getCurrentDay();

    // print the workouts table before inserting new data
    print("Table before insertion:");
    List<Map<String, dynamic>> existingWorkouts = await dbHelper.getMostRecentWorkoutsForDay(currentDay);
    _printWorkoutsTable(existingWorkouts);

    for (int i = 0; i < workoutsData.length; i++) {
      final workoutName = workoutsData[i]['workout_name'];
      final setsReps = setsRepsControllers[i].text;
      final weight = double.tryParse(weightControllers[i].text) ?? 0.0;

      // add the workout into the database
      await dbHelper.insertWorkout({
        'weekday': currentDay,
        'workout_name': workoutName,
        'weight': weight,
        'sets_reps': setsReps,
      });
    }

    // print the workouts table after inserting new data
    print("Table after insertion:");
    List<Map<String, dynamic>> updatedWorkouts = await dbHelper.getMostRecentWorkoutsForDay(currentDay);
    _printWorkoutsTable(updatedWorkouts);

    // after adding the workout, reload the workouts for the current day
    setState(() {
      dailyWorkouts = _getDailyWorkouts(currentDay); // reload workouts for the day
    });
  }

  void _printWorkoutsTable(List<Map<String, dynamic>> workouts) {
    if (workouts.isEmpty) {
      print("No workouts found.");
    } else {
      for (var workout in workouts) {
        print("Workout Name: ${workout['workout_name']}, Sets/Reps: ${workout['sets_reps']}, Weight: ${workout['weight']}");
      }
    }
  }

  // remove workout from the database and UI
  void _removeWorkout(int workoutId) async {
    final dbHelper = DatabaseHelper.instance;

    // remove workout from database
    await dbHelper.deleteWorkout(workoutId);

    // After removing, reload the workouts for the current day
    setState(() {
      dailyWorkouts = _getDailyWorkouts(currentDay!); // Reload workouts for the day
    });
  }

  // render all workouts in a dialog
  void _showAllWorkoutsDialog() async {
    final dbHelper = DatabaseHelper.instance;
    final allWorkouts = await dbHelper.getAllWorkouts(); // get all workouts from the database

    // group workouts by workout name and sorting alphabetically
    final Map<String, List<Map<String, dynamic>>> groupedWorkouts = {};

    for (var workout in allWorkouts) {
      final workoutName = workout['workout_name'];
      if (!groupedWorkouts.containsKey(workoutName)) {
        groupedWorkouts[workoutName] = [];
      }
      groupedWorkouts[workoutName]!.add(workout);
    }

    // sort the keys (workout names) alphabetically
    final sortedWorkoutNames = groupedWorkouts.keys.toList()..sort();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("All Workouts"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sortedWorkoutNames.map((workoutName) {
                // group workouts for the current workout name
                final workoutsForThisName = groupedWorkouts[workoutName]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: workoutsForThisName.map((workout) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '${workout['sets_reps']} - ${workout['weight']} lbs',
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            currentDay ?? 'Loading...', 
          ),
        ),
        actions: [
          // '!' icon with label
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: _showWeightPopup,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isWeightEntered ? Icons.check_circle : Icons.error_outline,  // Change to checkmark if weight is entered
                    color: isWeightEntered ? Colors.green : Colors.red,  // Green if weight is entered
                    size: 30,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Today\'s Weight',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dailyWorkouts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return Center(
                child: IconButton(
                  icon: const Icon(Icons.add, size: 100),
                  onPressed: () {
                    _showWorkoutSelectionDialog(context);
                  },
                ),
              );
            } else {
              return _buildWorkoutTable(snapshot.data!);
            }
          } else {
            return const Center(child: Text('No workouts found.'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showWorkoutSelectionDialog(context);
        },
        child: const Icon(Icons.add),
      ),
      persistentFooterButtons: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start, 
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: _showAllWorkoutsDialog,
                icon: const Icon(Icons.list),
                label: const Text("Show All Workouts"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: _showPreviousWeightsPopup, // to show the body weight data
                icon: const Icon(Icons.history),
                label: const Text("Previous"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkoutTable(List<Map<String, dynamic>> workoutsData) {
    // make controllers for each workout's sets_reps and weight
    List<TextEditingController> setsRepsControllers = [];
    List<TextEditingController> weightControllers = [];

    // initialize controllers for each workout
    workoutsData.forEach((_) {
      setsRepsControllers.add(TextEditingController()); // empty initially
      weightControllers.add(TextEditingController()); // empty initially
    });

    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Weekly Average Weight Row
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     const Text(
              //       'Weekly Average Weight', // Static for now
              //       style: TextStyle(fontSize: 16),
              //     ),
              //     const SizedBox(width: 8),
              //     GestureDetector(
              //       onTap: () => _showInfoPopup(context),
              //       child: Container(
              //         padding: const EdgeInsets.all(4.0),
              //         decoration: BoxDecoration(
              //           shape: BoxShape.circle,
              //           border: Border.all(color: Colors.black),
              //         ),
              //         child: const Icon(
              //           Icons.help_outline,
              //           color: Colors.black,
              //           size: 18,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 5),
              // const Text(
              //   '0.0 lbs', // Placeholder for weight
              //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 20),

              // Today's Workout Section
              ...List.generate(workoutsData.length, (index) {
                return _buildWorkoutRow(
                  workoutsData[index],
                  setsRepsControllers[index],
                  weightControllers[index],
                );
              }),

              // Finish Workout Button
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    _finishWorkout(workoutsData, setsRepsControllers, weightControllers);
                  },
                  child: const Text('Finish Workout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutRow(
    Map<String, dynamic> workoutData,
    TextEditingController setsRepsController,
    TextEditingController weightController,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Stack(  // stack to layer widgets on top of each other
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // left box (for pulled data)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0), // space between left and right boxes
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workoutData['workout_name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sets/Reps: ${workoutData['sets_reps'] ?? ''}', // show stored sets/reps or empty if none
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Weight: ${workoutData['weight'] ?? '0.0'} lbs', // show stored weight or default to '0.0'
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              // right box (for today's input fields)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0), // space between left and right boxes
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text(
                            'Today',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // set/reps textField
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: setsRepsController,
                              decoration: const InputDecoration(
                                hintText: 'Set x Reps',
                                border: OutlineInputBorder(),
                              ),
                              enabled: true, // always enabled
                            ),
                          ),
                          const SizedBox(width: 8),

                          // weight textField
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: weightController,
                              decoration: const InputDecoration(
                                hintText: 'Weight (lbs)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: true, // always enabled
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // trash icon
          Positioned(
            top: -8,  
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              onPressed: () {
                _showDeleteConfirmationDialog(workoutData['id']);
              },
            ),
          ),
        ],
      ),
    );
  }


  // show the previous weights popup
  void _showPreviousWeightsPopup() async {
    final bodyWeightRecords = await _getBodyWeightRecords();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Previous Weights'),
          content: bodyWeightRecords.isEmpty
              ? const Text('No body weight data available.')
              : SingleChildScrollView(
                  child: Column(
                    children: bodyWeightRecords.map((record) {
                      return ListTile(
                        title: Text('Date: ${record['date']}'),
                        subtitle: Text('Weight: ${record['body_weight']} lbs'),
                      );
                    }).toList(),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }


  // get previous body weights from the database
  Future<List<Map<String, dynamic>>> _getBodyWeightRecords() async {
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.getBodyWeight();  // get the records from the BodyWeight table
  }

  void _showWeightPopup() {
    final TextEditingController weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Today's Weight"),
          content: TextField(
            controller: weightController,
            decoration: const InputDecoration(
              hintText: 'Enter weight (lbs)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text);
                if (weight != null) {
                  final dbHelper = DatabaseHelper.instance;

                  // get today's date
                  final currentDate = DateTime.now().toIso8601String().split('T').first;

                  // add the body weight entry into the database
                  await dbHelper.insertBodyWeight({
                    'date': currentDate,
                    'body_weight': weight,
                  });

                  // update the state to change the icon to a green checkmark
                  setState(() {
                    isWeightEntered = true; // set to true once weight is entered
                  });

                  Navigator.pop(context); 

                } else {
                  // handle invalid input
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid weight')),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(int workoutId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Workout'),
          content: const Text('Are you sure you want to delete this workout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // delete the workout from the database
                final dbHelper = DatabaseHelper.instance;
                await dbHelper.deleteWorkout(workoutId);

                // remove the workout from the list (update UI)
                setState(() {
                  dailyWorkouts = _getDailyWorkouts(currentDay!); // reload workouts for the day
                });

                Navigator.pop(context); // close the confirmation dialog
              },
              child: const Text('Yes, Delete'),
            ),
          ],
        );
      },
    );
  }

  // function to show the info popup when the '?' icon is clicked
  void _showInfoPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Why Weekly Measurement?"),
        content: const Text(
          "Daily weight can be affected by momentary deviations from your diet such as salty foods that normally wouldn't be consumed daily. "
          "Getting a weekly measurement gives a much better picture of what's going on.",
          textAlign: TextAlign.center, // center the content text
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // popup for selecting the workout for the day
  void _showWorkoutSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Workout Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); 
                  _showWorkoutOptionsDialog(context, 'Upper'); // Show Upper workouts
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Upper',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); 
                  _showWorkoutOptionsDialog(context, 'Lower'); // Show Lower workouts
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Lower',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }


  void _showWorkoutOptionsDialog(BuildContext context, String category) {
    final List<String> upperWorkouts = [
      'Barbell Shrugs',
      'Dumbbell Military Press',
      'Bent Over Barbell Rows',
      'Dumbbell Lateral Raises',
      'Dumbbell Bicep Curls',
      'Cable Triceps Pushdown',
      'Bench Press',
    ];

    final List<String> lowerWorkouts = [
      'Squat',
      'Deadlift',
      'Stiff-Legged Deadlift',
      'Hip Thrusts',
      'Lunges',
      'Leg Extensions',
      'Calf Raises',
    ];

    final List<String> workouts = category == 'Upper' ? upperWorkouts : lowerWorkouts;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select $category Workout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: workouts.map((workout) {
                return GestureDetector(
                  onTap: () {
                    _showSetRepsDialog(context, workout); // Proceed to entering set/reps
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      workout,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // popup for entering sets and reps for a workout
  void _showSetRepsDialog(BuildContext context, String workoutName) {
    final TextEditingController repsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Set x Reps for $workoutName'),
          content: TextField(
            controller: repsController,
            decoration: const InputDecoration(hintText: 'Set x Reps'),
            keyboardType: TextInputType.text,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _addWorkoutToDatabase(workoutName, repsController.text);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Add workout to the database and reload the data
  Future<void> _addWorkoutToDatabase(String workoutName, String setsReps) async {
    final dbHelper = DatabaseHelper.instance;
    final currentDay = _getCurrentDay();

    await dbHelper.insertWorkout({
      'weekday': currentDay,
      'workout_name': workoutName,
      'sets_reps': setsReps,
      'weight': 0.0,
    });

    setState(() {
      dailyWorkouts = _getDailyWorkouts(currentDay); // Reload workouts for the day
    });
  }
}
