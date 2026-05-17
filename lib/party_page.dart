import 'package:flutter/material.dart';
import 'package:calc_ingri/db/ingridients_database.dart';
import 'package:calc_ingri/model/event.dart';
import 'package:calc_ingri/model/event_recipe.dart';
import 'package:calc_ingri/model/recipe.dart';
import 'create_cooking_page.dart';
import 'event_ingredients_page.dart';

class PartyPage extends StatefulWidget {
  const PartyPage({super.key});

  @override
  State<PartyPage> createState() => _PartyPageState();
}

class _PartyPageState extends State<PartyPage> {
  // Текущее мероприятие (если null — режим создания нового)
  Event? _currentEvent;
  List<Recipe> _allRecipes = [];
  List<_EventRecipeItem> _eventRecipes = []; // список блюд с количеством порций
  bool _isLoading = false;
  bool _isNewEvent = true;

  // Контроллеры для полей
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _guestsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    _allRecipes = await IngridientsDataBase.instance.readAllRecipes();
    setState(() => _isLoading = false);
  }

  Future<void> _loadEvent(int eventId) async {
    setState(() => _isLoading = true);
    try {
      final event = await IngridientsDataBase.instance.readEvent(eventId);
      final relations = await IngridientsDataBase.instance.getRecipesForEvent(eventId);
      final items = <_EventRecipeItem>[];
      for (var rel in relations) {
        final recipe = _allRecipes.firstWhere((r) => r.id == rel.recipeId);
        items.add(_EventRecipeItem(
          eventRecipeId: rel.id!,
          recipe: recipe,
          servingsOverride: rel.servingsOverride,
        ));
      }
      setState(() {
        _currentEvent = event;
        _eventNameController.text = event.name;
        _guestsController.text = event.guests.toString();
        _eventRecipes = items;
        _isNewEvent = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки мероприятия: $e')));
    }
  }

  Future<void> _saveEvent() async {
    final name = _eventNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите название мероприятия')));
      return;
    }
    final guests = int.tryParse(_guestsController.text.trim());
    if (guests == null || guests <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите корректное количество гостей')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      Event savedEvent;
      if (_isNewEvent) {
        final newEvent = Event(name: name, guests: guests);
        savedEvent = await IngridientsDataBase.instance.createEvent(newEvent);
        _currentEvent = savedEvent;
        _isNewEvent = false;
      } else {
        final updatedEvent = _currentEvent!.copy(name: name, guests: guests);
        await IngridientsDataBase.instance.updateEvent(updatedEvent);
        savedEvent = updatedEvent;
        setState(() => _currentEvent = savedEvent);
      }

      // Сохраняем связи с рецептами (удаляем старые и добавляем новые)
      // Для простоты: удалим все старые связи и добавим текущие
      final oldRelations = await IngridientsDataBase.instance.getRecipesForEvent(savedEvent.id!);
      for (var rel in oldRelations) {
        await IngridientsDataBase.instance.removeRecipeFromEvent(rel.id!);
      }
      for (var item in _eventRecipes) {
        final er = EventRecipe(
          eventId: savedEvent.id!,
          recipeId: item.recipe.id!,
          servingsOverride: item.servingsOverride,
        );
        await IngridientsDataBase.instance.addRecipeToEvent(er);
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Мероприятие сохранено')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openExistingPlan() async {
    final events = await IngridientsDataBase.instance.readAllEvents();
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет сохранённых мероприятий')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите мероприятие'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                title: Text(event.name),
                subtitle: Text('Гостей: ${event.guests}'),
                onTap: () {
                  Navigator.pop(context);
                  _loadEvent(event.id!);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _addRecipeToEvent() async {
  if (_allRecipes.isEmpty) {
    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Нет рецептов'),
        content: const Text('Сначала создайте хотя бы один рецепт. Создать сейчас?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Создать')),
        ],
      ),
    );
    if (shouldCreate == true) {
      await _createNewRecipeAndRefresh();
      if (_allRecipes.isNotEmpty) {
        _showRecipeSelectionDialog();
      }
    }
    return;
  }
  _showRecipeSelectionDialog();
}

Future<void> _showRecipeSelectionDialog() async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Добавить блюдо'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _allRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = _allRecipes[index];
                  return ListTile(
                    title: Text(recipe.title),
                    subtitle: Text(recipe.description ?? ''),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _eventRecipes.add(_EventRecipeItem(
                          recipe: recipe,
                          servingsOverride: null,
                        ));
                      });
                    },
                  );
                },
              ),
            ),
            const Divider(),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _createNewRecipeAndRefresh();
                if (_allRecipes.isNotEmpty) {
                  _showRecipeSelectionDialog();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Создать новый рецепт'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _createNewRecipeAndRefresh() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const CreateCookingPage()),
  );
  if (result == true) {
    await _loadRecipes();
  }
}

  void _removeRecipe(int index) {
    setState(() {
      _eventRecipes.removeAt(index);
    });
  }

  void _updateServings(int index, int newValue) {
    setState(() {
      _eventRecipes[index].servingsOverride = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Кнопки открыть/сохранить
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openExistingPlan,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(12)),
                    child: const SizedBox(
                      height: 60,
                      child: Row(
                        children: [
                          Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.folder)),
                          Text('Открыть \nсуществующий \nплан мероприятий')
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _saveEvent,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(12)),
                    child: const SizedBox(
                      height: 60,
                      child: Row(
                        children: [
                          Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.file_copy)),
                          Text('Сохранить текущий \nплан мероприятий')
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1, height: 1),

          // Название мероприятия
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: TextField(
                  controller: _eventNameController,
                  decoration: InputDecoration(
                    hintText: 'Введите название мероприятия',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    suffixIcon: const Icon(Icons.edit),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          // Количество гостей
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Укажите количество гостей:'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(12)),
                  child: SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _guestsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                ),
                const Icon(Icons.edit),
              ],
            ),
          ),

          // Заголовок "Меню" и "Количество порций"
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text('Меню'),
                Spacer(),
                Text('Количество порций /развесовка')
              ],
            ),
          ),

          // Список блюд
          Expanded(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: _eventRecipes.length + 1,
                            itemBuilder: (context, index) {
                              if (index < _eventRecipes.length) {
                                final item = _eventRecipes[index];
                                int currentValue = item.servingsOverride ?? _getDefaultServings(item.recipe, _currentEvent?.guests ?? 0);
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.crop_square_sharp),
                                    title: Text(item.recipe.title),
                                    subtitle: Text(item.recipe.description ?? ''),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.exposure_minus_1),
                                          onPressed: () => _updateServings(index, currentValue - 1),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(12)),
                                          child: Text('$currentValue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.plus_one),
                                          onPressed: () => _updateServings(index, currentValue + 1),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _removeRecipe(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.6,
                                      child: ElevatedButton(
                                        onPressed: _addRecipeToEvent,
                                        child: const Text('Добавить блюдо'),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.93,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_currentEvent == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Сначала сохраните мероприятие')),
                            );
                            return;
                          }
                          await _saveEvent(); // сохраняем текущее состояние перед расчётом
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventIngredientsPage(eventId: _currentEvent!.id!),
                            ),
                          );
                        },
                        child: const Text('Рассчитать'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getDefaultServings(Recipe recipe, int guests) {
    final defaultServings = recipe.servings ?? 1; // поле default_servings должно быть в модели Recipe
    return (guests / defaultServings).ceil();
  }
}

class _EventRecipeItem {
  int? eventRecipeId;
  final Recipe recipe;
  int? servingsOverride;

  _EventRecipeItem({this.eventRecipeId, required this.recipe, this.servingsOverride});
}