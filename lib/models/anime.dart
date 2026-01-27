import 'package:roig_anidb_api/models/models.dart';

class Anime {
  final String id;
  final bool restricted;

  final String? type;
  final int? episodeCount;
  final DateTime? startDate;
  final DateTime? endDate;

  final List<AnimeTitle> titles;
  final List<AnimeRelation> relatedAnime;
  final List<AnimeRelation> similarAnime;

  final String? url;
  final List<Creator> creators;
  final String? description;
  final List<AnimeRecommendation> recommendations;

  Anime({
    required this.id,
    required this.restricted,
    this.type,
    this.episodeCount,
    this.startDate,
    this.endDate,
    List<AnimeTitle>? titles,
    List<AnimeRelation>? relatedAnime,
    List<AnimeRelation>? similarAnime,
    this.url,
    List<Creator>? creators,
    this.description,
    List<AnimeRecommendation>? recommendations,
  }) : titles = titles ?? [],
       relatedAnime = relatedAnime ?? [],
       similarAnime = similarAnime ?? [],
       creators = creators ?? [],
       recommendations = recommendations ?? [];
}
