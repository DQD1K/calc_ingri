final String tableEvents = 'events';

class EventFields {
  static final List<String> values = [id, name, guests, description, date];
  static const String id = '_id';
  static const String name = 'name';
  static const String guests = 'guests';
  static const String description = 'description';
  static const String date = 'date';
}

class Event {
  final int? id;
  final String name;
  final int guests;
  final String? description;
  final int? date;

  const Event({this.id, required this.name, required this.guests, this.description, this.date});

  static Event fromJson(Map<String, Object?> json) => Event(
    id: json[EventFields.id] as int?,
    name: json[EventFields.name] as String,
    guests: json[EventFields.guests] as int,
    description: json[EventFields.description] as String?,
    date: json[EventFields.date] as int?,
  );

  Map<String, Object?> toJson() => {
    EventFields.id: id,
    EventFields.name: name,
    EventFields.guests: guests,
    EventFields.description: description,
    EventFields.date: date,
  };

  Event copy({int? id, String? name, int? guests, String? description, int? date}) => Event(
    id: id ?? this.id,
    name: name ?? this.name,
    guests: guests ?? this.guests,
    description: description ?? this.description,
    date: date ?? this.date,
  );
}