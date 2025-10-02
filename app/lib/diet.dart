import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

// * Popup for adding food, cycles between two tabs for the saved foods and new foods

class _AddFoodDialog extends StatefulWidget {
  final List<Map<String, dynamic>> commonFoods;
  final Function(String name, int calories, int carbs, int protein, bool saveDefinition) onFoodAdded;

  const _AddFoodDialog({
    required this.commonFoods,
    required this.onFoodAdded,
  });

  @override
  _AddFoodDialogState createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<_AddFoodDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  bool _shouldSaveDefinition = false; 

  final _formKey = GlobalKey<FormState>(); 

  @override
  // Initializes the tab controller when opening the widget
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); 
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() {
        });
      }
    });
  }


  //Updates garbage collector so nothing breaks
  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  //Adding food manually
  void _submitManualEntry() {
    if (_formKey.currentState!.validate()) {
      widget.onFoodAdded(
        _nameController.text.trim(),
        int.tryParse(_caloriesController.text) ?? 0,
        int.tryParse(_carbsController.text) ?? 0,
        int.tryParse(_proteinController.text) ?? 0,
        _shouldSaveDefinition,
      );
      Navigator.of(context).pop(); 
    }
  }

  //Adding saved food
  void _addFromSaved(Map<String, dynamic> food) {
    widget.onFoodAdded(
      food['name'],
      food['calories'],
      food['carbs'], 
      food['protein'],
      false, //making sure that food doesn't get added twice
    );
    Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context) {
    // Making sure that the popup scales properly
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final contentWidth = screenWidth * 0.9;
    final contentHeight = screenHeight * 0.5;

    return AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      contentPadding: const EdgeInsets.all(0),
      title: TabBar(
        controller: _tabController,
        labelColor: Color.fromARGB(255, 172, 155, 210), // ! Maybe save color for later
        unselectedLabelColor: Colors.grey,
        indicatorColor: Color.fromARGB(255, 172, 155, 210),
        tabs: const [
          Tab(text: 'Manual Entry'),
          Tab(text: 'Saved Foods'),
        ],
      ),
      content: Container(
        width: contentWidth,
        height: contentHeight,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildManualEntryTab(),
            _buildSavedFoodsTab(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        Visibility(
          visible: _tabController.index == 0,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: TextButton(
            onPressed: _submitManualEntry,
            child: Text('Add'),
          ),
        ),
      ],
    );
  }

  //* The manual entry tab
  Widget _buildManualEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0), 
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Food Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a food name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _caloriesController,
              decoration: InputDecoration(labelText: 'Calories'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter calories';
                }
                final calories = int.tryParse(value);
                if (calories == null || calories <= 0) {
                  return 'Please enter a positive number';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _carbsController,
              decoration: InputDecoration(labelText: 'Carbs (g)'),
              keyboardType: TextInputType.numberWithOptions(decimal: false),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  _carbsController.text = '0'; 
                  return null;
                }
                final carbs = int.tryParse(value);
                if (carbs == null || carbs < 0) {
                  return 'Must be 0 or greater';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _proteinController,
              decoration: InputDecoration(labelText: 'Protein (g)'),
              keyboardType: TextInputType.numberWithOptions(decimal: false),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  _proteinController.text = '0'; 
                  return null;
                }
                final protein = int.tryParse(value);
                if (protein == null || protein < 0) {
                  return 'Must be 0 or greater';
                }
                return null;
              },
            ),
            SizedBox(height: 15),
            CheckboxListTile(
              title: Text("Save definition for later"),
              value: _shouldSaveDefinition,
              onChanged: (bool? newValue) {
                setState(() { 
                  _shouldSaveDefinition = newValue ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      )
    );
  }

  // * Saved foods tab
  Widget _buildSavedFoodsTab() {
    final foods = widget.commonFoods;

    if (foods.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("No food definitions saved yet."),
        ),
      );
    }


    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0), 
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return Card(
          child: ListTile(
                  title: Text(food['name']),
                  subtitle: Text("${food['calories']} cal, ${food['carbs']}g F, ${food['protein']}g P"), 
                  trailing: Icon(Icons.add_circle_outline, color: Color.fromARGB(255, 172, 155, 210)),
                  tileColor: Theme.of(context).primaryColor,
                  onTap: () {
                    _addFromSaved(food);
                  },
                ),
        );
      },
    );
  }
}



// * Main widget for the diet page

class dietPage extends StatefulWidget {
  const dietPage({super.key});

  @override
  State<StatefulWidget> createState() => _dietPageState();
}

// Checking to see if two dates are the same
bool _isSameDate(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
}


class _dietPageState extends State<dietPage> {
  List<Map<String, dynamic>> foodItems = [];
  List<Map<String, dynamic>> commonFoodItems = [];

  // * Goal values, subject to change maybe
  int currentWeight = 70, desiredWeight = 65;
  int calorieGoal = 2300;
  int carbsGoal = 250; 
  int proteinGoal = 165;

  // * Current goals for macros
  int currentCals = 0;
  int currentCarbs = 0;
  int currentProtein = 0;

  // *SQL database and check if it's initialized
  late Database database;
  bool _dbInitialized = false;

  // Currently selected date
  late DateTime _selectedDate;

  // Helper to get a specific date string
  String _formatDateString(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  // Function to format date for the date selector and food lists
  String _formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selected = DateTime(date.year, date.month, date.day);

    //Checking the day to see if you need the full date or not
    if (_isSameDate(selected, today)) {
      return 'Today';
    } else if (_isSameDate(selected, yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  // Calculating percentages for goals
  double get calGoalPercentage => calorieGoal > 0 ? currentCals / calorieGoal : 0;
  double get carbsGoalPercentage => carbsGoal > 0 ? currentCarbs / carbsGoal : 0;
  double get proteinGoalPercentage => proteinGoal > 0 ? currentProtein / proteinGoal : 0;


  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDatabase(); // ! CALLES FOR INITIALIZING THE DATABASE ON OPENING THE PAGE
    });
  }


  // ! INITIALIZED THE DATABASES

  Future<void> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'foods.db');
      print('Database path: $path');

      database = await openDatabase(
        path,
        version: 3, 
        onCreate: (db, version) async {
          print('Creating database tables (Version $version)...');
          await db.execute(
            'CREATE TABLE foods(id INTEGER PRIMARY KEY, name TEXT UNIQUE, calories INTEGER, carbs INTEGER, protein INTEGER)',
          );
          await db.execute(
            '''CREATE TABLE daily_log(
                log_id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT,
                name TEXT,
                calories INTEGER,
                carbs INTEGER,
                protein INTEGER
              )'''
          );
          print('Database tables created.');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          print('Upgrading database from version $oldVersion to $newVersion...');
          if (oldVersion < 2) {
            print('Adding daily_log table (migration v1->v2/v3)...');
            await db.execute(
            '''CREATE TABLE daily_log(
                  log_id INTEGER PRIMARY KEY AUTOINCREMENT,
                  date TEXT,
                  name TEXT,
                  calories INTEGER,
                  carbs INTEGER,
                  protein INTEGER
                 )''' // Create with 'carbs' directly if target is v3+
            );
            print('daily_log table added.');
          }
          if (oldVersion < 3) {
            print('Ensuring carbs column exists and renaming/dropping fibre (migration v2->v3)...');
            try {
              var columnsFoods = await db.rawQuery('PRAGMA table_info(foods)');
              bool carbsExistsFoods = columnsFoods.any((col) => col['name'] == 'carbs');
              bool fibreExistsFoods = columnsFoods.any((col) => col['name'] == 'fibre');

              if (fibreExistsFoods && !carbsExistsFoods) {
                print('Renaming foods.fibre to foods.carbs...');
                await db.execute('ALTER TABLE foods RENAME COLUMN fibre TO carbs;');
              } else if (fibreExistsFoods && carbsExistsFoods) {
                print('Warning: Both fibre and carbs columns exist in foods table. Handling defensively.');
              }

              var columnsLog = await db.rawQuery('PRAGMA table_info(daily_log)');
              bool carbsExistsLog = columnsLog.any((col) => col['name'] == 'carbs');
              bool fibreExistsLog = columnsLog.any((col) => col['name'] == 'fibre');

              if (fibreExistsLog && !carbsExistsLog) {
                print('Renaming daily_log.fibre to daily_log.carbs...');
                await db.execute('ALTER TABLE daily_log RENAME COLUMN fibre TO carbs;');
              } else if (fibreExistsLog && carbsExistsLog) {
                print('Warning: Both fibre and carbs columns exist in daily_log table. Handling defensively.');
              }
              print('Column migration v2->v3 complete.');

            } catch (e) {
                print('Error during column migration v2->v3: $e');
            }
          }
        },
        onOpen: (db) async {
          final currentVersion = await db.getVersion();
          print('Database opened successfully (Version $currentVersion)');
        },
      );
      setState(() {
        _dbInitialized = true;
      });
      print('Database initialized successfully.');

      await _loadCommonFoods();
      await _loadFoodLogForDate(_selectedDate);

    } catch (e, stacktrace) {
      print('Error initializing database: $e');
      print('Stacktrace: $stacktrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing database: $e')),
        );
      }
      setState(() {
        _dbInitialized = false;
      });
    }
  }

  // Load saved food definitions
  Future<void> _loadCommonFoods() async {
    if (!_dbInitialized || !database.isOpen) {
      print("Database not ready in _loadCommonFoods");
      return;
    }
    try {
      // Query using 'carbs' column
      final List<Map<String, dynamic>> foods = await database.query('foods');
      // Ensure uniqueness based on 'name'
      final uniqueFoods = { for (var food in foods) food['name'] as String : food }.values.toList();
      setState(() {
        commonFoodItems = uniqueFoods;
      });
      print('Common foods loaded: ${commonFoodItems.length} items');
    } catch (e) {
      print('Error loading common foods: $e');
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading saved foods: $e')),
          );
      }
    }
  }

  // Loading food list for a specific date
  // For the date switcher
  Future<void> _loadFoodLogForDate(DateTime date) async {
    if (!_dbInitialized || !database.isOpen) {
      print("Database not ready in _loadFoodLogForDate");
      return;
    }
    try {
      final String dateString = _formatDateString(date);
      print("Loading food log for date: $dateString");
      final List<Map<String, dynamic>> loggedItems = await database.query(
        'daily_log',
        where: 'date = ?',
        whereArgs: [dateString],
      );

      print("Found ${loggedItems.length} items logged for $dateString.");

      List<Map<String, dynamic>> loadedFoodItems = [];
      int loadedCals = 0;
      int loadedCarbs = 0;
      int loadedProtein = 0;

      for (var item in loggedItems) {
        final mutableItem = Map<String, dynamic>.from(item);
        loadedFoodItems.add(mutableItem);
        loadedCals += (item['calories'] as int?) ?? 0;
        loadedCarbs += (item['carbs'] as int?) ?? 0;
        loadedProtein += (item['protein'] as int?) ?? 0;
      }

      setState(() {
        foodItems = loadedFoodItems;
        currentCals = loadedCals;
        currentCarbs = loadedCarbs;
        currentProtein = loadedProtein;
        _selectedDate = date;
      });
      print("Food log for $dateString loaded successfully.");

    } catch (e) {
      print('Error loading food log for $date: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading food log for date: $e')),
        );
      }
    }
  }

  // Saving food to database for potential reuse
  Future<void> _saveFoodToDatabase(String name, int calories, int carbs, int protein) async {
    if (!_dbInitialized || !database.isOpen) return;
    try {
      await database.insert(
        'foods',
        // Use 'carbs' key
        {'name': name, 'calories': calories, 'carbs': carbs, 'protein': protein},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      print("Saved '$name' definition to database.");
      await _loadCommonFoods(); 
    } catch (e) {
      print("Error saving food definition '$name' to database: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving food definition: $e')),
        );
      }
    }
  }

  // Logging food to the daily food table
  Future<int> _logFoodToDailyTable(Map<String, dynamic> foodItem, DateTime date) async {
    if (!_dbInitialized || !database.isOpen) return -1;
    try {
      final String dateString = _formatDateString(date);
      final dataToInsert = {
        'date': dateString,
        'name': foodItem['name'],
        'calories': foodItem['calories'],
        'carbs': foodItem['carbs'],
        'protein': foodItem['protein'],
      };
      final id = await database.insert(
        'daily_log',
        dataToInsert,
      );
      print("Logged '${foodItem['name']}' to daily log with id $id for date $dateString.");
      return id;
    } catch (e) {
      print("Error logging food '${foodItem['name']}' to daily table for date $date: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging food: $e')),
        );
      }
      return -1;
    }
  }

  // Option to remove food entries from the daily table
  Future<void> _removeFoodLogFromDatabase(int logId) async {
    if (!_dbInitialized || !database.isOpen || logId <= 0) return;
    try {
      final count = await database.delete(
        'daily_log',
        where: 'log_id = ?',
        whereArgs: [logId],
      );
      print("Removed log entry with id $logId from daily table. Count: $count");
    } catch (e) {
      print("Error removing log entry id $logId from daily table: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing food log entry: $e')),
        );
      }
    }
  }


  // Handles the data received from "add food" popup
  void _handleFoodAdded(String name, int calories, int carbs, int protein, bool saveDefinition) async {
    final newItem = {'name': name, 'calories': calories, 'carbs': carbs, 'protein': protein};

    final logId = await _logFoodToDailyTable(newItem, _selectedDate);

    if (logId != -1) {
      newItem['log_id'] = logId;

      if (_isSameDate(_selectedDate, this._selectedDate))
      {
        setState(() {
          foodItems.add(newItem);
          currentCals += calories;
          currentCarbs += carbs;
          currentProtein += protein;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${newItem['name']} added to log for ${_formatDateForDisplay(_selectedDate)}"))
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log food item.')),
        );
      }
      return;
    }

    if (saveDefinition && _dbInitialized) {
      print("Attempting to save '$name' definition to database because checkbox was checked.");
      await _saveFoodToDatabase(name, calories, carbs, protein);
    } else if (saveDefinition && !_dbInitialized) {
      print("Checkbox checked for '$name', but database is not initialized.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot save food definition, database not ready.')),
        );
      }
    } else {
        print("Did not save '$name' definition to database (checkbox unchecked or DB issue).");
    }
  }


  // Calls the add food dialog
  void _showCombinedAddFoodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AddFoodDialog(
          commonFoods: commonFoodItems,
          onFoodAdded: _handleFoodAdded,
        );
      },
    );
  }


  //Navigation for moving between days
  void _goToPreviousDay() {
    final previousDay = _selectedDate.subtract(const Duration(days: 1));
    setState(() {
      _selectedDate = previousDay;
    });
    _loadFoodLogForDate(_selectedDate);
  }
  void _goToNextDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_isSameDate(_selectedDate, today)) {
      return;
    }

    final nextDay = _selectedDate.add(const Duration(days: 1));
    if (nextDay.isAfter(today)) {
      setState(() { _selectedDate = today;});
      _loadFoodLogForDate(today);
    } else {
      setState(() {
        _selectedDate = nextDay;
      });
      _loadFoodLogForDate(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bool isTodaySelected = _isSameDate(_selectedDate, today);

    return Scaffold(
      appBar: AppBar(
        title: Text('Diet Tracker'),
        actions: [
          IconButton(
            onPressed: () {
                showDialog(
                  context: context, 
                  builder: (BuildContext context){
                    return AlertDialog(
                      title: Text("Notice"),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: SingleChildScrollView(
                          child: Text("Tracking macronutrients is a complex process and not all measurements will be accurate (factors include the food's origin, processing, and so on). \n\nYou must always measure your weight periodically (weighing at the same time/in the same situation to get an accurate reading) and adjust according to your goals."
                          ),
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: (){
                            Navigator.of(context).pop();
                          }, 
                          child: Text("OK")
                        ),
                      ],
                    );
                  },
                );
              }, 
            icon: Icon(Icons.help_outline)
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Text('Current Weight:'),
            //     Text('Desired Weight:'),
            //   ],
            // ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Text("$currentWeight KG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0)),
            //     Text("$desiredWeight KG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0)),
            //   ],
            // ),
            SizedBox(height: 10.0),

            _buildGoalIndicator("Calories", currentCals, calorieGoal, calGoalPercentage, const Color.fromARGB(255, 255, 0, 0)), // Shout out Darth Vader
            SizedBox(height: 10.0),
            _buildGoalIndicator("Carbs", currentCarbs, carbsGoal, carbsGoalPercentage, Colors.purpleAccent), //Shout out Mace Windu
            SizedBox(height: 10.0), 
            _buildGoalIndicator("Protein", currentProtein, proteinGoal, proteinGoalPercentage, Colors.lightBlueAccent), // Shout out Obi-Wan Kenobi

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  tooltip: 'Previous Day',
                  onPressed: _dbInitialized ? _goToPreviousDay : null,
                ),
                Text(
                  _formatDateForDisplay(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  tooltip: 'Next Day',
                  onPressed: _dbInitialized && !isTodaySelected ? _goToNextDay : null,
                  color: _dbInitialized && !isTodaySelected ? Theme.of(context).iconTheme.color : Colors.grey,
                ),
              ],
            ),

            SizedBox(height: 10),

            // List Header Text
            Text(
              "Food for ${_formatDateForDisplay(_selectedDate)}:",
              style: Theme.of(context).textTheme.titleMedium
            ),
            Expanded(
              child: foodItems.isEmpty
                ? Center(child: Text("No food logged for ${_formatDateForDisplay(_selectedDate)}."))
                : ListView.builder(
                  itemCount: foodItems.length,
                  itemBuilder: (context, index) {
                    final item = foodItems[index];
                    final logId = item['log_id'] as int?;
                    // * Animation for swiping to delete
                    return Dismissible(
                        key: ValueKey(logId ?? UniqueKey()),
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20.0),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          // Remove from DB
                          if (logId != null) { _removeFoodLogFromDatabase(logId); }
                          else { print("Error: Cannot remove item, log_id is missing."); }
                          setState(() {
                            currentCals -= item['calories'] as int;
                            currentCarbs -= item['carbs'] as int;
                            currentProtein -= item['protein'] as int;
                            foodItems.removeAt(index);
                          });
                          if(mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("${item['name']} removed"))
                            );
                          }
                        },
                        child: Card(
                          child: ListTile(
                            title: Text(item['name']),
                            subtitle: Column (
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item['calories']} calories'),
                                // Display carbs
                                Text('${item['carbs']}g carbs'),
                                Text('${item['protein']}g protein'),
                              ],
                            ),
                            trailing: Text('${item['calories']} cal', style: TextStyle(color: Colors.grey[600])),
                          ),
                        ),
                    );
                  },
                ),
          ),
          SizedBox(height: 10),
            // Add Food Button
            Center(
              child: ElevatedButton.icon(
                  onPressed: _dbInitialized ? _showCombinedAddFoodDialog : null,
                  icon: Icon(Icons.add),
                  label: Text('Add Food Item'),
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

   // Helper widget for goal indicators
  Widget _buildGoalIndicator(String label, int current, int goal, double percentage, Color color) {
    final safePercentage = (goal > 0) ? (current / goal) : 0.0;
    final clampedPercentage = safePercentage.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: $current / $goal ${label == 'Calories' ? 'kcal' : 'g'}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: clampedPercentage.isNaN || clampedPercentage.isInfinite ? 0 : clampedPercentage,
          color: color,
          backgroundColor: color.withOpacity(0.2),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }


  @override
  void dispose() {
    if (_dbInitialized && database.isOpen) {
      database.close().then((_) => print("Database closed"));
    }
    super.dispose();
  }
} // End of _dietPageState