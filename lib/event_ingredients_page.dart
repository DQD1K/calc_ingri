import 'package:flutter/material.dart';
import 'package:calc_ingri/db/ingridients_database.dart';

class EventIngredientsPage extends StatefulWidget {
  final int eventId;
  const EventIngredientsPage({super.key, required this.eventId});

  @override
  State<EventIngredientsPage> createState() => _EventIngredientsPageState();
}

class _EventIngredientsPageState extends State<EventIngredientsPage> {
  List<CalculatedIngredient> _ingredients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCalculation();
  }

  Future<void> _loadCalculation() async {
    setState(() => _isLoading = true);
    try {
      final result = await IngridientsDataBase.instance.calculateEventIngredients(widget.eventId);
      setState(() {
        _ingredients = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькуляция ингредиентов'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Ошибка: $_error'))
              : _ingredients.isEmpty
                  ? const Center(child: Text('Нет ингредиентов для расчёта'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        final item = _ingredients[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.kitchen),
                            title: Text(item.ingredient.name),
                            subtitle: item.unitConflict
                                ? Text(
                                    'ВНИМАНИЕ: разные единицы измерения!\n${_formatQuantity(item.totalQuantity)} ${item.unit} (несоответствие)',
                                    style: const TextStyle(color: Colors.orange),
                                  )
                                : Text('${_formatQuantity(item.totalQuantity)} ${item.unit}'),
                            trailing: item.unitConflict
                                ? const Icon(Icons.warning, color: Colors.orange)
                                : null,
                          ),
                        );
                      },
                    ),
    );
  }

  String _formatQuantity(double value) {
    // Убираем .0 для целых чисел
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toString();
  }
}