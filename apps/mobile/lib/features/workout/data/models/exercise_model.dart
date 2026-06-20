class Exercise {
  final String id;
  final String name;
  final String category;
  final String muscleGroup;
  final String equipment;
  final String difficulty;
  final String description;
  final String? videoUrl;
  final String? imageUrl;
  final List<String> instructions;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.equipment,
    required this.difficulty,
    required this.description,
    this.videoUrl,
    this.imageUrl,
    required this.instructions,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      muscleGroup: map['muscle_group'] ?? '',
      equipment: map['equipment'] ?? '',
      difficulty: map['difficulty'] ?? '',
      description: map['description'] ?? '',
      videoUrl: map['video_url'],
      imageUrl: map['image_url'],
      instructions: List<String>.from(map['instructions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'muscle_group': muscleGroup,
      'equipment': equipment,
      'difficulty': difficulty,
      'description': description,
      'video_url': videoUrl,
      'image_url': imageUrl,
      'instructions': instructions,
    };
  }
}
