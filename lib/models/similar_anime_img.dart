class SimilarImageItem {
  final int aid;
  final String picture;

  SimilarImageItem({required this.aid, required this.picture});

  String get posterUrl => 'https://cdn.anidb.net/images/main/$picture';
}

class SimilarPair {
  final SimilarImageItem source;
  final SimilarImageItem target;

  SimilarPair({required this.source, required this.target});
}
