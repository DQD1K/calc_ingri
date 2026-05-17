import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '/model/ingridient.dart';
import '/model/recipe.dart';
import '/model/recipe_ingridient.dart';
import '/model/event.dart';
import '/model/event_recipe.dart';

class CalculatedIngredient {
  final Ingridient ingredient;
  final double totalQuantity;
  final String unit;
  final bool unitConflict;

  CalculatedIngredient({
    required this.ingredient,
    required this.totalQuantity,
    required this.unit,
    this.unitConflict = false,
  });
}

class _AggregatedData {
  final double sum;
  final String unit;
  final bool conflict;
  _AggregatedData({required this.sum, required this.unit, required this.conflict});
}

class IngridientsDataBase {
  static final IngridientsDataBase instance = IngridientsDataBase._init();
  static Database? _database;

  IngridientsDataBase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ingridients.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final stringType = 'TEXT NOT NULL';
    final textType = 'TEXT';
    final stringTypeNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE $tableIngridients(
        ${IngridientFields.id} $idType,
        ${IngridientFields.name} $stringType,
        ${IngridientFields.description} $stringTypeNullable,
        ${IngridientFields.picturePath} $stringTypeNullable
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableRecipes(
        ${RecipeFields.id} $idType,
        ${RecipeFields.title} $stringType,
        ${RecipeFields.description} $textType,
        ${RecipeFields.instructions} $textType,
        ${RecipeFields.servings} INTEGER NOT NULL DEFAULT 1,
        ${RecipeFields.imagePath} $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableRecipeIngredients(
        ${RecipeIngredientFields.id} $idType,
        ${RecipeIngredientFields.recipeId} INTEGER NOT NULL,
        ${RecipeIngredientFields.ingredientId} INTEGER NOT NULL,
        ${RecipeIngredientFields.quantity} TEXT NOT NULL,
        FOREIGN KEY (${RecipeIngredientFields.recipeId}) REFERENCES $tableRecipes(${RecipeFields.id}) ON DELETE CASCADE,
        FOREIGN KEY (${RecipeIngredientFields.ingredientId}) REFERENCES $tableIngridients(${IngridientFields.id}) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE events(
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        guests INTEGER NOT NULL,
        description TEXT,
        date INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE event_recipes(
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        recipe_id INTEGER NOT NULL,
        servings_override INTEGER,
        FOREIGN KEY (event_id) REFERENCES events(_id) ON DELETE CASCADE,
        FOREIGN KEY (recipe_id) REFERENCES recipes(_id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $tableRecipes(
          ${RecipeFields.id} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${RecipeFields.title} TEXT NOT NULL,
          ${RecipeFields.description} TEXT,
          ${RecipeFields.instructions} TEXT,
          ${RecipeFields.servings} INTEGER,
          ${RecipeFields.imagePath} TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE $tableRecipeIngredients(
          ${RecipeIngredientFields.id} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${RecipeIngredientFields.recipeId} INTEGER NOT NULL,
          ${RecipeIngredientFields.ingredientId} INTEGER NOT NULL,
          ${RecipeIngredientFields.quantity} TEXT NOT NULL,
          FOREIGN KEY (${RecipeIngredientFields.recipeId}) REFERENCES $tableRecipes(${RecipeFields.id}) ON DELETE CASCADE,
          FOREIGN KEY (${RecipeIngredientFields.ingredientId}) REFERENCES $tableIngridients(${IngridientFields.id}) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('BEGIN TRANSACTION;');
      try {
        await db.execute('ALTER TABLE $tableIngridients RENAME TO ${tableIngridients}_old;');
        final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
        final stringTypeNullable = 'TEXT';
        await db.execute('''
          CREATE TABLE $tableIngridients(
            ${IngridientFields.id} $idType,
            ${IngridientFields.name} TEXT NOT NULL,
            ${IngridientFields.description} $stringTypeNullable,
            ${IngridientFields.picturePath} $stringTypeNullable
          )
        ''');
        await db.execute('''
          INSERT INTO $tableIngridients (${IngridientFields.id}, ${IngridientFields.name}, ${IngridientFields.description}, ${IngridientFields.picturePath})
          SELECT ${IngridientFields.id}, ${IngridientFields.name}, ${IngridientFields.description}, ${IngridientFields.picturePath}
          FROM ${tableIngridients}_old
        ''');
        await db.execute('DROP TABLE ${tableIngridients}_old;');
        await db.execute('COMMIT;');
      } catch (e) {
        await db.execute('ROLLBACK;');
        rethrow;
      }
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE events(
          _id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          guests INTEGER NOT NULL,
          description TEXT,
          date INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE event_recipes(
          _id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          recipe_id INTEGER NOT NULL,
          servings_override INTEGER,
          FOREIGN KEY (event_id) REFERENCES events(_id) ON DELETE CASCADE,
          FOREIGN KEY (recipe_id) REFERENCES recipes(_id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // ===== CRUD для рецептов =====
  Future<Recipe> createRecipe(Recipe recipe) async {
    final db = await instance.database;
    final id = await db.insert(tableRecipes, recipe.toJson());
    return recipe.copy(id: id);
  }

  Future<Recipe> readRecipe(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableRecipes,
      where: '${RecipeFields.id} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Recipe.fromJson(maps.first);
    } else {
      throw Exception('Recipe with id $id not found');
    }
  }

  Future<List<Recipe>> readAllRecipes() async {
    final db = await instance.database;
    final orderBy = '${RecipeFields.title} ASC';
    final result = await db.query(tableRecipes, orderBy: orderBy);
    return result.map((json) => Recipe.fromJson(json)).toList();
  }

  Future<int> updateRecipe(Recipe recipe) async {
    final db = await instance.database;
    return db.update(
      tableRecipes,
      recipe.toJson(),
      where: '${RecipeFields.id} = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<int> deleteRecipe(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableRecipes,
      where: '${RecipeFields.id} = ?',
      whereArgs: [id],
    );
  }

  // ===== CRUD для связей рецепт-ингредиент =====
  Future<RecipeIngredient> addIngredientToRecipe(RecipeIngredient relation) async {
    final db = await instance.database;
    final id = await db.insert(tableRecipeIngredients, relation.toJson());
    return relation.copy(id: id);
  }

  Future<List<RecipeIngredient>> getIngredientsForRecipe(int recipeId) async {
    final db = await instance.database;
    final result = await db.query(
      tableRecipeIngredients,
      where: '${RecipeIngredientFields.recipeId} = ?',
      whereArgs: [recipeId],
    );
    return result.map((json) => RecipeIngredient.fromJson(json)).toList();
  }

  Future<int> removeIngredientFromRecipe(int relationId) async {
    final db = await instance.database;
    return await db.delete(
      tableRecipeIngredients,
      where: '${RecipeIngredientFields.id} = ?',
      whereArgs: [relationId],
    );
  }

  Future<int> updateRecipeIngredientQuantity(RecipeIngredient relation) async {
    final db = await instance.database;
    return db.update(
      tableRecipeIngredients,
      relation.toJson(),
      where: '${RecipeIngredientFields.id} = ?',
      whereArgs: [relation.id],
    );
  }

  Future<Ingridient> create(Ingridient ingridient) async {
    final db = await instance.database;
    final id = await db.insert(tableIngridients, ingridient.toJson());
    return ingridient.copy(id: id);
  }

  Future<Ingridient> readIngridient(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableIngridients,
      columns: IngridientFields.values,
      where: '${IngridientFields.id} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Ingridient.fromJson(maps.first);
    } else {
      throw Exception('ID: $id is not found');
    }
  }

  Future<List<Ingridient>> readAllIngridients() async {
    final db = await instance.database;
    final orderBy = '${IngridientFields.name} ASC';
    final result = await db.query(tableIngridients, orderBy: orderBy);
    return result.map((json) => Ingridient.fromJson(json)).toList();
  }

  Future<int> update(Ingridient ingridient) async {
    final db = await instance.database;
    return db.update(
      tableIngridients,
      ingridient.toJson(),
      where: '${IngridientFields.id} = ?',
      whereArgs: [ingridient.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableIngridients,
      where: '${IngridientFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // ========== Мероприятия ==========
  Future<Event> createEvent(Event event) async {
    final db = await instance.database;
    final id = await db.insert(tableEvents, event.toJson());
    return event.copy(id: id);
  }

  Future<List<Event>> readAllEvents() async {
    final db = await instance.database;
    final result = await db.query(tableEvents, orderBy: '${EventFields.name} ASC');
    return result.map((json) => Event.fromJson(json)).toList();
  }

  Future<Event> readEvent(int id) async {
    final db = await instance.database;
    final maps = await db.query(tableEvents, where: '${EventFields.id} = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Event.fromJson(maps.first);
    throw Exception('Event $id not found');
  }

  Future<int> updateEvent(Event event) async {
    final db = await instance.database;
    return db.update(tableEvents, event.toJson(), where: '${EventFields.id} = ?', whereArgs: [event.id]);
  }

  Future<int> deleteEvent(int id) async {
    final db = await instance.database;
    return await db.delete(tableEvents, where: '${EventFields.id} = ?', whereArgs: [id]);
  }

  // ========== Связи мероприятие-рецепт ==========
  Future<EventRecipe> addRecipeToEvent(EventRecipe er) async {
    final db = await instance.database;
    final id = await db.insert(tableEventRecipes, er.toJson());
    return er.copy(id: id);
  }

  Future<List<EventRecipe>> getRecipesForEvent(int eventId) async {
    final db = await instance.database;
    final result = await db.query(tableEventRecipes, where: '${EventRecipeFields.eventId} = ?', whereArgs: [eventId]);
    return result.map((json) => EventRecipe.fromJson(json)).toList();
  }

  Future<int> updateEventRecipe(EventRecipe er) async {
    final db = await instance.database;
    return db.update(tableEventRecipes, er.toJson(), where: '${EventRecipeFields.id} = ?', whereArgs: [er.id]);
  }

  Future<int> removeRecipeFromEvent(int eventRecipeId) async {
    final db = await instance.database;
    return await db.delete(tableEventRecipes, where: '${EventRecipeFields.id} = ?', whereArgs: [eventRecipeId]);
  }

  // ========== Калькуляция ингредиентов для мероприятия ==========
  Future<List<CalculatedIngredient>> calculateEventIngredients(int eventId) async {
    final event = await readEvent(eventId);
    final guests = event.guests;

    final eventRecipes = await getRecipesForEvent(eventId);
    if (eventRecipes.isEmpty) return [];

    final Map<int, _AggregatedData> aggregated = {};

    for (final er in eventRecipes) {
      final recipe = await readRecipe(er.recipeId);
      final baseServings = recipe.servings ?? 1;
      int overrideServings;
      if (er.servingsOverride != null && er.servingsOverride! > 0) {
        overrideServings = er.servingsOverride!;
      } else {
        overrideServings = (guests / baseServings).ceil();
      }
      final multiplier = overrideServings / baseServings;

      final recipeIngredients = await getIngredientsForRecipe(recipe.id!);
      for (final ri in recipeIngredients) {
        final ingredient = await readIngridient(ri.ingredientId);
        final parsed = _parseQuantity(ri.quantity);
        if (parsed == null) continue;
        final (value, unit) = parsed;
        final double totalForIngredient = value * multiplier;

        if (aggregated.containsKey(ingredient.id)) {
          final existing = aggregated[ingredient.id]!;
          if (existing.unit != unit) {
            aggregated[ingredient.id!] = _AggregatedData(
              sum: existing.sum + totalForIngredient,
              unit: existing.unit,
              conflict: true,
            );
          } else {
            aggregated[ingredient.id!] = _AggregatedData(
              sum: existing.sum + totalForIngredient,
              unit: unit,
              conflict: existing.conflict,
            );
          }
        } else {
          aggregated[ingredient.id!] = _AggregatedData(
            sum: totalForIngredient,
            unit: unit,
            conflict: false,
          );
        }
      }
    }

    final List<CalculatedIngredient> result = [];
    for (final entry in aggregated.entries) {
      final ingredient = await readIngridient(entry.key);
      result.add(CalculatedIngredient(
        ingredient: ingredient,
        totalQuantity: entry.value.sum,
        unit: entry.value.unit,
        unitConflict: entry.value.conflict,
      ));
    }
    return result;
  }
}

// Вспомогательная функция парсинга (вне класса)
(double, String)? _parseQuantity(String quantityStr) {
  final RegExp regex = RegExp(r'^([\d\.]+)\s*(\S+)$');
  final match = regex.firstMatch(quantityStr.trim());
  if (match == null) return null;
  final double value = double.tryParse(match.group(1)!) ?? 0.0;
  final String unit = match.group(2)!;
  return (value, unit);
}