final String tableEventRecipes = 'event_recipes';

class EventRecipeFields {
  static final List<String> values = [id, eventId, recipeId, servingsOverride];
  static const String id = '_id';
  static const String eventId = 'event_id';
  static const String recipeId = 'recipe_id';
  static const String servingsOverride = 'servings_override';
}

class EventRecipe {
  final int? id;
  final int eventId;
  final int recipeId;
  final int? servingsOverride;

  const EventRecipe({this.id, required this.eventId, required this.recipeId, this.servingsOverride});

  static EventRecipe fromJson(Map<String, Object?> json) => EventRecipe(
    id: json[EventRecipeFields.id] as int?,
    eventId: json[EventRecipeFields.eventId] as int,
    recipeId: json[EventRecipeFields.recipeId] as int,
    servingsOverride: json[EventRecipeFields.servingsOverride] as int?,
  );

  Map<String, Object?> toJson() => {
    EventRecipeFields.id: id,
    EventRecipeFields.eventId: eventId,
    EventRecipeFields.recipeId: recipeId,
    EventRecipeFields.servingsOverride: servingsOverride,
  };

  EventRecipe copy({int? id, int? eventId, int? recipeId, int? servingsOverride}) => EventRecipe(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    recipeId: recipeId ?? this.recipeId,
    servingsOverride: servingsOverride ?? this.servingsOverride,
  );
}