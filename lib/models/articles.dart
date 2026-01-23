import 'package:roig_spaceflight_api/models/models.dart';

class Articles {
  int id;
  String title;
  List<Author> authors;
  String url;
  String imageUrl;
  String newsSite;
  String summary;
  DateTime publishedAt;
  DateTime updatedAt;
  bool featured;

  Articles({
    required this.id,
    required this.title,
    required this.authors,
    required this.url,
    required this.imageUrl,
    required this.newsSite,
    required this.summary,
    required this.publishedAt,
    required this.updatedAt,
    required this.featured,
  });

  // ========= GETTERS =========
  String get getImageUrlSafe {
    final url = imageUrl.trim();
    if (url.isEmpty) return 'https://i.stack.imgur.com/GNhxO.png';
    return url;
  }

  String get getArticleTitle {
    if (title.isEmpty || title == null) {
      return 'Sin titulo';
    }
    return title;
  }

  factory Articles.fromJson(String str) => Articles.fromMap(json.decode(str));

  factory Articles.fromMap(Map<String, dynamic> json) => Articles(
    id: json["id"],
    title: json["title"],
    authors: List<Author>.from(json["authors"].map((x) => Author.fromMap(x))),
    url: json["url"],
    imageUrl: json["image_url"],
    newsSite: json["news_site"],
    summary: json["summary"],
    publishedAt: DateTime.parse(json["published_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    featured: json["featured"],
  );
}
