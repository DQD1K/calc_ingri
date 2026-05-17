final String tableRecipeIngredients = 'recipe_ingredients';

class RecipeIngredientFields {
  static final List<String> values = [
    id, recipeId, ingredientId, quantity
  ];
  static final String id = '_id';
  static final String recipeId = 'recipe_id';
  static final String ingredientId = 'ingredient_id';
  static final String quantity = 'quantity';
}

class RecipeIngredient {
  final int? id;
  final int recipeId;
  final int ingredientId;
  final String quantity; // например "100 г", "2 шт"

  const RecipeIngredient({
    this.id,
    required this.recipeId,
    required this.ingredientId,
    required this.quantity,
  });

  static RecipeIngredient fromJson(Map<String, Object?> json) => RecipeIngredient(
    id: json[RecipeIngredientFields.id] as int?,
    recipeId: json[RecipeIngredientFields.recipeId] as int,
    ingredientId: json[RecipeIngredientFields.ingredientId] as int,
    quantity: json[RecipeIngredientFields.quantity] as String,
  );

  Map<String, Object?> toJson() => {
    RecipeIngredientFields.id: id,
    RecipeIngredientFields.recipeId: recipeId,
    RecipeIngredientFields.ingredientId: ingredientId,
    RecipeIngredientFields.quantity: quantity,
  };

  RecipeIngredient copy({
    int? id,
    int? recipeId,
    int? ingredientId,
    String? quantity,
  }) => RecipeIngredient(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    ingredientId: ingredientId ?? this.ingredientId,
    quantity: quantity ?? this.quantity,
  );
}