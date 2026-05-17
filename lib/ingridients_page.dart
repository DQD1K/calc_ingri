import 'package:calc_ingri/model/ingridient.dart';
import 'package:flutter/material.dart';
import '/db/ingridients_database.dart';


class IngriPage extends StatefulWidget {
  const IngriPage({super.key});

  @override
  State<IngriPage> createState() => IngriPageState();
}

class IngriPageState extends State<IngriPage> {
  //List<String> ingrilist = ['1', '2', '3'];
  List<Ingridient> ingridients = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    refreshIngridients();
  }

  Future refreshIngridients() async{
    setState(() => isLoading = true);
    this.ingridients = await IngridientsDataBase.instance.readAllIngridients();
    setState(() => isLoading = false);
  }

  Future<void> _addIngridient() async {
    // Контроллеры для полей ввода
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController picController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Добавить ингредиент'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Название',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  hintText: 'Описание',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: picController,
                decoration: const InputDecoration(
                  hintText: 'Путь к картинке (необязательно)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                // Показываем ошибку
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите название')),
                );
                return;
              }
              final ingridient = Ingridient(
                name: name,
                description: descController.text.trim(),
                picturePath: picController.text.trim(),
              );
              await IngridientsDataBase.instance.create(ingridient);
              Navigator.pop(context); // закрываем диалог
              await refreshIngridients(); // обновляем список
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIngridient(Ingridient ingridient) async {
    await IngridientsDataBase.instance.delete(ingridient.id!);
    await refreshIngridients(); // перезагружаем список
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('Ингредиенты'),
        actions: [
          IconButton(onPressed: _addIngridient, icon: Icon(Icons.add))
        ],
      ),
      body: ListView.builder(
        itemCount: ingridients.length,
        itemBuilder: (BuildContext context, index){
          final ingridient = ingridients[index];
          return GestureDetector(
            onTap: (){},
            child: Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.cabin),
                    title: Text(ingridient.name),
                    trailing: IconButton(onPressed: () => _deleteIngridient(ingridient), icon: Icon(Icons.delete)),
                  )
                ],
              ),
            ),
          );
        }
        ),
      
    );
  }
}