class AnimeRelation {
  final String id;
  final String? relationType; // Sequel, Prequel, Similar, etc.
  final String? title;

  AnimeRelation({required this.id, this.relationType, this.title});
}
