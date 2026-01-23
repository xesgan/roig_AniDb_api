import 'dart:convert';

import 'package:roig_spaceflight_api/models/models.dart';

class FeaturedArticlesResponse {
  int count;
  String? next;
  dynamic previous;
  List<Articles> results;

  FeaturedArticlesResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory FeaturedArticlesResponse.fromJson(String str) =>
      FeaturedArticlesResponse.fromMap(json.decode(str));

  factory FeaturedArticlesResponse.fromMap(Map<String, dynamic> json) =>
      FeaturedArticlesResponse(
        count: json["count"],
        next: json["next"],
        previous: json["previous"],
        results: List<Articles>.from(
          json["results"].map((x) => Articles.fromMap(x)),
        ),
      );
}
