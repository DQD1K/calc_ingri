import 'package:flutter/material.dart';
import '/db/ingridients_database.dart';
import '/model/recipe.dart';
import '/model/ingridient.dart';


class RecipePage extends StatefulWidget {
  final int recipeId;
  const RecipePage({super.key, required this.recipeId});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  Recipe? _recipe;
  List<_IngredientWithQuantity> _ingredients = [];
  bool _isLoading = true;
  bool _isEditing = false;

  // Контроллеры для редактирования
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _instructionsController;
  late TextEditingController _servingsController;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final recipe = await IngridientsDataBase.instance.readRecipe(widget.recipeId);
      final relations = await IngridientsDataBase.instance.getIngredientsForRecipe(widget.recipeId);
      
      // Загружаем полные объекты ингредиентов
      List<_IngredientWithQuantity> ingredientsWithQty = [];
      for (var relation in relations) {
        final ingredient = await IngridientsDataBase.instance.readIngridient(relation.ingredientId);
        ingredientsWithQty.add(_IngredientWithQuantity(
          ingredient: ingredient,
          quantity: relation.quantity,
          relationId: relation.id,
        ));
      }
      
      setState(() {
        _recipe = recipe;
        _ingredients = ingredientsWithQty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }

  void _startEditing() {
    _titleController = TextEditingController(text: _recipe!.title);
    _descriptionController = TextEditingController(text: _recipe!.description ?? '');
    _instructionsController = TextEditingController(text: _recipe!.instructions ?? '');
    _servingsController = TextEditingController(text: _recipe!.servings?.toString() ?? '');
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _saveRecipe() async {
    final updatedRecipe = _recipe!.copy(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      instructions: _instructionsController.text.trim(),
      servings: int.tryParse(_servingsController.text.trim()),
    );
    await IngridientsDataBase.instance.updateRecipe(updatedRecipe);
    setState(() {
      _recipe = updatedRecipe;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Рецепт сохранён')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? const Text('Редактирование рецепта')
            : Text(_recipe?.title ?? 'Рецепт'),
        actions: [
          if (!_isLoading && _recipe != null)
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _startEditing,
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveRecipe,
              ),
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: _cancelEditing,
              ),
            ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipe == null
              ? const Center(child: Text('Рецепт не найден'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название
                      if (_isEditing)
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Название рецепта',
                            border: OutlineInputBorder(),
                          ),
                        )
                      else
                        Text(
                          _recipe!.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 16),
                      
                      // Описание
                      if (_isEditing)
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Описание',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        )
                      else if (_recipe!.description != null && _recipe!.description!.isNotEmpty)
                        Text(
                          _recipe!.description!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      const SizedBox(height: 16),
                      
                      // Порции
                      if (_isEditing)
                        TextFormField(
                          controller: _servingsController,
                          decoration: const InputDecoration(
                            labelText: 'Количество порций',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        )
                      else if (_recipe!.servings != null)
                        Text('Порций: ${_recipe!.servings}'),
                      const SizedBox(height: 16),
                      
                      // Ингредиенты
                      const Text(
                        'Ингредиенты:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_ingredients.isEmpty)
                        const Text('Нет ингредиентов')
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _ingredients.length,
                          itemBuilder: (context, index) {
                            final item = _ingredients[index];
                            return ListTile(
                              leading: const Icon(Icons.food_bank),
                              title: Text(item.ingredient.name),
                              subtitle: Text('Количество: ${item.quantity}'),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      
                      // Инструкция
                      const Text(
                        'Инструкция:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_isEditing)
                        TextFormField(
                          controller: _instructionsController,
                          decoration: const InputDecoration(
                            labelText: 'Инструкция',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 10,
                        )
                      else if (_recipe!.instructions != null && _recipe!.instructions!.isNotEmpty)
                        Text(_recipe!.instructions!),
                    ],
                  ),
                ),
    );
  }
}

// Вспомогательный класс для хранения ингредиента с количеством
class _IngredientWithQuantity {
  final Ingridient ingredient;
  final String quantity;
  final int? relationId;
  _IngredientWithQuantity({
    required this.ingredient,
    required this.quantity,
    this.relationId,
  });
}