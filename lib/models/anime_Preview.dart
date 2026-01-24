class AnimePreview {
  final int id;
  final bool restricted;
  final String? type;
  final int? episodeCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? title;
  final String? picture;
  final double? permanentRating;
  final double? temporaryRating;
  final int? recommendationsCount;

  AnimePreview({
    required this.id,
    required this.restricted,
    this.type,
    this.episodeCount,
    this.startDate,
    this.endDate,
    this.title,
    this.picture,
    this.permanentRating,
    this.temporaryRating,
    this.recommendationsCount,
  });

  // ====== GETTERS ======
  String get posterUrl {
    if (picture == null || picture!.trim().isEmpty) {
      return 'https://i.stack.imgur.com/GNhxO.png';
    }
    return 'https://cdn.anidb.net/images/main/$picture';
  }

  String get animeTitle {
    if (title == null) {
      return 'Titulo no available';
    }
    return title.toString();
  }
}
