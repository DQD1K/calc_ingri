final String tableRecipes = 'recipes';

class RecipeFields {
  static final List<String> values = [
    id, title, description, instructions, servings, imagePath
  ];
  static final String id = '_id';
  static final String title = 'title';
  static final String description = 'description';
  static final String instructions = 'instructions';
  static final String servings = 'servings';
  static final String imagePath = 'imagePath';
}

class Recipe {
  final int? id;
  final String title;
  final String? description;
  final String? instructions;
  final int? servings;
  final String? imagePath;

  const Recipe({
    this.id,
    required this.title,
    this.description,
    this.instructions,
    this.servings,
    this.imagePath,
  });

  static Recipe fromJson(Map<String, Object?> json) => Recipe(
    id: json[RecipeFields.id] as int?,
    title: json[RecipeFields.title] as String,
    description: json[RecipeFields.description] as String?,
    instructions: json[RecipeFields.instructions] as String?,
    servings: json[RecipeFields.servings] as int?,
    imagePath: json[RecipeFields.imagePath] as String?,
  );

  Map<String, Object?> toJson() => {
    RecipeFields.id: id,
    RecipeFields.title: title,
    RecipeFields.description: description,
    RecipeFields.instructions: instructions,
    RecipeFields.servings: servings,
    RecipeFields.imagePath: imagePath,
  };

  Recipe copy({
    int? id,
    String? title,
    String? description,
    String? instructions,
    int? servings,
    String? imagePath,
    int? defaultServings,
  }) => Recipe(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    instructions: instructions ?? this.instructions,
    servings: servings ?? this.servings,
    imagePath: imagePath ?? this.imagePath,
  );
}