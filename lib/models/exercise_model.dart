class ExerciseModel {
  final int id;
  final String slug;
  final String category; // 'bodyweight' | 'weighted'
  final String difficulty; // 'beginner' | 'intermediate'
  final String name;
  final String description;
  final String nameEn;
  final String nameUk;
  final String descriptionEn;
  final String descriptionUk;
  final bool isFavorite;

  const ExerciseModel({
    required this.id,
    required this.slug,
    required this.category,
    required this.difficulty,
    required this.name,
    required this.description,
    required this.nameEn,
    required this.nameUk,
    required this.descriptionEn,
    required this.descriptionUk,
    required this.isFavorite,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as int,
      slug: json['slug'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      nameEn: json['name_en'] as String,
      nameUk: json['name_uk'] as String,
      descriptionEn: json['description_en'] as String,
      descriptionUk: json['description_uk'] as String,
      isFavorite: (json['is_favorite'] as bool?) ?? false,
    );
  }

  ExerciseModel copyWith({bool? isFavorite}) {
    return ExerciseModel(
      id: id,
      slug: slug,
      category: category,
      difficulty: difficulty,
      name: name,
      description: description,
      nameEn: nameEn,
      nameUk: nameUk,
      descriptionEn: descriptionEn,
      descriptionUk: descriptionUk,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}