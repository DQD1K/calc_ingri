import 'package:flutter/material.dart';
import '/db/ingridients_database.dart';
import '/model/ingridient.dart';
import '/model/recipe.dart';
import '/model/recipe_ingridient.dart';

class CreateCookingPage extends StatefulWidget {
  const CreateCookingPage({super.key});

  @override
  State<CreateCookingPage> createState() => _CreateCookingPageState();
}

class _CreateCookingPageState extends State<CreateCookingPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Поля рецепта
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();

  // Список ингредиентов: каждый элемент содержит название (для отображения) и количество
  // А также ID ингредиента (после создания/выбора)
  List<_IngredientInput> _ingredients = [];

  // Список всех ингредиентов из БД для автозаполнения
  List<Ingridient> _allIngredients = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
    _addIngredientField(); // начальное пустое поле
  }

  Future<void> _loadIngredients() async {
    final ingredients = await IngridientsDataBase.instance.readAllIngridients();
    setState(() {
      _allIngredients = ingredients;
    });
  }

  void _addIngredientField() {
    setState(() {
      _ingredients.add(_IngredientInput());
    });
  }

  void _removeIngredientField(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  // Проверка существования ингредиента по имени, если нет – создаём
  Future<Ingridient> _getOrCreateIngredient(String name) async {
    name = name.trim();
    if (name.isEmpty) throw Exception('Название не может быть пустым');
    
    // Ручной поиск с nullable результатом
    Ingridient? existing;
    for (var ing in _allIngredients) {
      if (ing.name.toLowerCase() == name.toLowerCase()) {
        existing = ing;
        break;
      }
    }
    if (existing != null) return existing;
    
    // Не найден – создаём новый
    final newIngredient = Ingridient(name: name);
    final created = await IngridientsDataBase.instance.create(newIngredient);
    setState(() {
      _allIngredients.add(created);
    });
    return created;
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // 1. Создаём рецепт
      final servings = int.tryParse(_servingsController.text.trim());
      final recipe = Recipe(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        instructions: _instructionsController.text.trim(),
        servings: servings,
      );
      final createdRecipe = await IngridientsDataBase.instance.createRecipe(recipe);
      final recipeId = createdRecipe.id!;
      
      // 2. Добавляем каждый ингредиент
      for (var input in _ingredients) {
        if (input.nameController.text.trim().isEmpty) continue;
        // Получаем или создаём ингредиент
        final ingredient = await _getOrCreateIngredient(input.nameController.text.trim());
        final quantity = input.quantityController.text.trim();
        if (quantity.isEmpty) continue;
        
        final relation = RecipeIngredient(
          recipeId: recipeId,
          ingredientId: ingredient.id!,
          quantity: quantity,
        );
        await IngridientsDataBase.instance.addIngredientToRecipe(relation);
      }
      
      // Возвращаем успех на предыдущий экран
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить новый рецепт'),
        actions: [
          IconButton(
            onPressed: _saveRecipe,
            icon: const Icon(Icons.save),
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Название рецепта
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название рецепта',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 12),
                  
                  // Описание
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  
                  // Инструкция по приготовлению
                  TextFormField(
                    controller: _instructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Инструкция',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  
                  // Количество порций
                  TextFormField(
                    controller: _servingsController,
                    decoration: const InputDecoration(
                      labelText: 'Количество порций',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      if (int.tryParse(value) == null) return 'Введите число';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Заголовок секции ингредиентов
                  Row(
                    children: [
                      const Text(
                        'Ингредиенты',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _addIngredientField,
                        icon: const Icon(Icons.add),
                        tooltip: 'Добавить ингредиент',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Динамический список полей для ингредиентов
                  ..._buildIngredientFields(),
                  
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveRecipe,
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Сохранить рецепт'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  List<Widget> _buildIngredientFields() {
    List<Widget> widgets = [];
    for (int i = 0; i < _ingredients.length; i++) {
      final input = _ingredients[i];
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Autocomplete<Ingridient>(
                  optionsBuilder: (TextEditingValue textValue) {
                    if (textValue.text.isEmpty) return const Iterable<Ingridient>.empty();
                    return _allIngredients.where((ing) =>
                        ing.name.toLowerCase().contains(textValue.text.toLowerCase()));
                  },
                  displayStringForOption: (Ingridient option) => option.name,
                  onSelected: (Ingridient selection) {
                    input.nameController.text = selection.name;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // Привязываем внешний контроллер
                    input.nameController = controller;
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Название ингредиента',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // При изменении текста обновляем контроллер
                        input.nameController.text = value;
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: input.quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Количество (г, мл, шт.)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _removeIngredientField(i),
              ),
            ],
          ),
        ),
      );
    }
    if (_ingredients.isEmpty) {
      widgets.add(const Text('Добавьте хотя бы один ингредиент'));
    }
    return widgets;
  }
}

// Вспомогательный класс для хранения данных об ингредиенте в форме
class _IngredientInput {
  late TextEditingController nameController;
  final TextEditingController quantityController;
  
  _IngredientInput({
    TextEditingController? nameController,
    TextEditingController? quantityController,
  })  : nameController = nameController ?? TextEditingController(),
        quantityController = quantityController ?? TextEditingController();
}