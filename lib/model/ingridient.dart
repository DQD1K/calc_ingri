final String tableIngridients = 'ingridients';

class IngridientFields{
  static final List<String> values = [id, name, description, picturePath];

  static final String id = '_id';
  static final String name = 'name';
  static final String description = 'description';
  static final String picturePath = 'picturePath';
}

class Ingridient {
  final int? id;
  final String name;
  final String? description;
  final String? picturePath;

  const Ingridient({
    this.id,
    required this.name,
    this.description,
    this.picturePath
  });

  static Ingridient fromJson(Map<String, Object?> json) => Ingridient(
    id: json[IngridientFields.id] as int?,
    name: json[IngridientFields.name] as String,
    description: json[IngridientFields.description] as String?,
    picturePath: json[IngridientFields.picturePath] as String?,
  );

  Map<String, Object?> toJson() => {
    IngridientFields.id: id,
    IngridientFields.name: name,
    IngridientFields.description: description,
    IngridientFields.picturePath: picturePath,
  };

  Ingridient copy({
    int? id,
    String? name,
    String? description,
    String? picturePath,

  }) => Ingridient(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    picturePath: picturePath ?? this.picturePath,
    );
}