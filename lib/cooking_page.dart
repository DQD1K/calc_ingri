import 'package:calc_ingri/recipePage.dart';
import 'package:flutter/material.dart';
import 'create_cooking_page.dart';
import '/db/ingridients_database.dart';
import '/model/recipe.dart';

class CookingPage extends StatefulWidget {
  const CookingPage({super.key});

  @override
  State<CookingPage> createState() => CookingPageState();
}

class CookingPageState extends State<CookingPage> {
  List<Recipe> recipes = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    refreshRecipes();
  }

  Future<void> refreshRecipes() async {
    setState(() => isLoading = true);
    recipes = await IngridientsDataBase.instance.readAllRecipes();
    setState(() => isLoading = false);
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить рецепт?'),
        content: Text('Вы уверены, что хотите удалить "${recipe.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => isLoading = true);
      await IngridientsDataBase.instance.deleteRecipe(recipe.id!);
      await refreshRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchAnchor(
                    builder: (BuildContext context, SearchController controller) {
                      return SearchBar(
                        controller: controller,
                        padding: const WidgetStatePropertyAll<EdgeInsets>(
                          EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                        onTap: () {
                          controller.openView();
                        },
                        onChanged: (_) {
                          controller.openView();
                        },
                        leading: const Icon(Icons.search),
                      );
                    },
                    suggestionsBuilder: (BuildContext context, SearchController controller) {
                      return List<ListTile>.generate(5, (int index) {
                        final String item = 'item $index';
                        return ListTile(
                          title: Text(item),
                          onTap: () {
                            setState(() {
                              controller.closeView(item);
                            });
                          },
                        );
                      });
                    },
                  ),
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.filter)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.sort)),
            ],
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: recipes.length,
                    itemBuilder: (BuildContext context, index) {
                      final recipe = recipes[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipePage(recipeId: recipe.id!)
                              )
                          );
                        },
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.dangerous),
                            title: Text(recipe.title),
                            subtitle: Text(recipe.description ?? 'Без описания'),
                            trailing: IconButton(onPressed: () => _deleteRecipe(recipe), icon: Icon(Icons.delete)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(1.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.93,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateCookingPage()),
                  );
                  if (result == true) {
                    refreshRecipes();
                  }
                },
                child: const Text('Добавить рецепт'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}