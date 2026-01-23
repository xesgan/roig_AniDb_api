import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roig_spaceflight_api/models/models.dart';

class ArticlesProvider extends ChangeNotifier {
  String _baseUrl = 'api.spaceflightnewsapi.net';
  String _isFeatured = 'true';

  List<Articles> featuredArticles = [];
  List<Articles> noFeaturedArticles = [];

  ArticlesProvider() {
    print('Articles Provider Iniciado');
    getAllFeaturedArticles();
    getAllNoFeaturedArticles();
  }

  getAllFeaturedArticles() async {
    var url = Uri.https(_baseUrl, 'v4/articles', {'is_featured': _isFeatured});

    final result = await http.get(url);

    final featuredArticlesResponse = FeaturedArticlesResponse.fromJson(
      result.body,
    );

    featuredArticles = featuredArticlesResponse.results;

    notifyListeners();
  }

  getAllNoFeaturedArticles() async {
    _isFeatured = 'false';

    var url = Uri.https(_baseUrl, 'v4/articles', {'is_featured': _isFeatured});

    final result = await http.get(url);

    final featuredArticlesResponse = FeaturedArticlesResponse.fromJson(
      result.body,
    );

    noFeaturedArticles = featuredArticlesResponse.results;

    // for (Articles a in noFeaturedArticles.take(5)) {
    //   debugPrint('Estamos en el no featured');
    //   debugPrint(a.title);
    // }

    notifyListeners();
  }
}
