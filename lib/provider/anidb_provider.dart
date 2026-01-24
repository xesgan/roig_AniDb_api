import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roig_spaceflight_api/models/models.dart';
import 'package:xml/xml.dart';

import '../models/anime.dart';

class AniDbProvider extends ChangeNotifier {
  final String client;
  final int clientVer;

  AniDbProvider({required this.client, required this.clientVer});

  List<AnimePreview> randomList = [];
  List<AnimePreview> hotList = [];

  // ===== State =====
  bool isLoading = false;
  bool isLoadingList = false;
  String? errorMessage;

  // Cache por id (aid)
  final Map<int, Anime> _cache = {};

  // Para no spamear AniDB (mínimo 2s entre requests)
  DateTime _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Carga una lista de animes recomendados aleatoriamente(id)
  Future<void> fetchRandomRecommendationList() async {
    isLoadingList = true;
    errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri(
        scheme: 'http',
        host: 'api.anidb.net',
        port: 9001,
        path: '/httpapi',
        queryParameters: {
          'request': 'randomrecommendation',
          'client': client,
          'clientver': clientVer.toString(),
          'protover': '1',
        },
      );

      final res = await http.get(uri);

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final xmlStr = utf8.decode(res.bodyBytes);
      final doc = XmlDocument.parse(xmlStr);

      randomList = parseRandomRecommendation(doc); // la función de arriba
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoadingList = false;
      notifyListeners();
    }
  }

  // Carga una lista de los animes mas vistos temporalmente
  Future<void> fetchHotAnime() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri(
        scheme: 'http',
        host: 'api.anidb.net',
        port: 9001,
        path: '/httpapi',
        queryParameters: {
          'request': 'hotanime',
          'client': client,
          'clientver': clientVer.toString(),
          'protover': '1',
        },
      );

      final res = await http.get(uri);

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final xmlStr = utf8.decode(res.bodyBytes);
      final doc = XmlDocument.parse(xmlStr);

      hotList = parseHotAnime(doc);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<AnimePreview> parseHotAnime(XmlDocument doc) {
    final list = <AnimePreview>[];

    for (final a in doc.rootElement.findElements('anime')) {
      final id = int.tryParse(a.getAttribute('id') ?? '');
      if (id == null) continue;

      final restricted =
          (a.getAttribute('restricted') ?? 'false').toLowerCase() == 'true';

      String? textOf(String tag) {
        final el = a.findElements(tag);
        if (el.isEmpty) return null;
        final t = el.first.innerText.trim();
        return t.isEmpty ? null : t;
      }

      final title = textOf('title');
      final picture = textOf('picture');
      final episodeCount = int.tryParse(textOf('episodecount') ?? '');
      final startDate = DateTime.tryParse(textOf('startdate') ?? '');

      // ratings/permanent y ratings/temporary
      double? ratingOf(String tag) {
        final ratings = a.findElements('ratings');
        if (ratings.isEmpty) return null;
        final el = ratings.first.findElements(tag);
        if (el.isEmpty) return null;
        return double.tryParse(el.first.innerText.trim());
      }

      list.add(
        AnimePreview(
          id: id,
          restricted: restricted,
          title: title,
          picture: picture,
          episodeCount: episodeCount,
          startDate: startDate,
          permanentRating: ratingOf('permanent'),
          temporaryRating: ratingOf('temporary'),
        ),
      );
    }

    return list;
  }

  /// Carga un anime por id (aid).
  Future<Anime?> fetchAnime(int aid, {bool force = false}) async {
    errorMessage = null;

    if (!force && _cache.containsKey(aid)) {
      return _cache[aid];
    }

    await _throttle();

    isLoading = true;
    notifyListeners();

    try {
      final uri = Uri(
        scheme: 'http',
        host: 'api.anidb.net',
        port: 9001,
        path: '/httpapi',
        queryParameters: {
          'request': 'anime',
          'client': client.toLowerCase(),
          'clientver': clientVer.toString(),
          'protover': '1',
          'aid': aid.toString(),
        },
      );

      final res = await http.get(
        uri,
        headers: const {'Accept-Encoding': 'gzip'},
      );

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final xmlStr = utf8.decode(res.bodyBytes);
      final doc = XmlDocument.parse(xmlStr);

      final anime = _parseAnime(doc);

      _cache[aid] = anime;
      return anime;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =======================
  // Helpers internos
  // =======================

  Anime? getFromCache(int aid) => _cache[aid];

  Future<void> _throttle() async {
    final now = DateTime.now();
    final diff = now.difference(_lastRequestAt);

    // AniDB: 1 request cada 2s (safe)
    const minGap = Duration(seconds: 2);

    if (diff < minGap) {
      await Future.delayed(minGap - diff);
    }

    _lastRequestAt = DateTime.now();
  }

  Anime? getAnime(int aid) => getFromCache(aid);

  void preloadForIndex(int index) {
    if (index < 0 || index >= randomList.length) return;

    final aid = randomList[index].id;

    // Si no está en cache, lo pido
    if (getFromCache(aid) == null) {
      fetchAnime(aid);
    }

    // Preload del siguiente (suave)
    if (index + 1 < randomList.length) {
      final nextAid = randomList[index + 1].id;
      if (getFromCache(nextAid) == null) {
        fetchAnime(nextAid);
      }
    }
  }

  List<AnimePreview> parseRandomRecommendation(XmlDocument doc) {
    final list = <AnimePreview>[];

    for (final anime in doc.findAllElements('anime')) {
      final id = int.tryParse(anime.getAttribute('id') ?? '');
      if (id == null) continue;

      bool parseBool(String? v) => (v ?? '').toLowerCase() == 'true';

      String? textOf(String tag) {
        final els = anime.findElements(tag);
        if (els.isEmpty) return null;
        final t = els.first.innerText.trim();
        return t.isEmpty ? null : t;
      }

      int? intOf(String tag) => int.tryParse(textOf(tag) ?? '');
      DateTime? dateOf(String tag) => DateTime.tryParse(textOf(tag) ?? '');

      final titleEl = anime.findElements('title').isNotEmpty
          ? anime.findElements('title').first
          : null;
      final title = titleEl?.innerText.trim();

      // ratings/permanent y ratings/recommendations
      double? permanent;
      int? recCount;
      final ratingsEl = anime.findElements('ratings');
      if (ratingsEl.isNotEmpty) {
        final r = ratingsEl.first;

        final permEl = r.findElements('permanent');
        if (permEl.isNotEmpty) {
          permanent = double.tryParse(permEl.first.innerText.trim());
        }

        final recEl = r.findElements('recommendations');
        if (recEl.isNotEmpty) {
          recCount = int.tryParse(recEl.first.innerText.trim());
        }
      }

      list.add(
        AnimePreview(
          id: id,
          restricted: parseBool(anime.getAttribute('restricted')),
          type: textOf('type'),
          episodeCount: intOf('episodecount'),
          startDate: dateOf('startdate'),
          endDate: dateOf('enddate'),
          title: title,
          picture: textOf('picture'),
          permanentRating: permanent,
          recommendationsCount: recCount,
        ),
      );
    }

    return list;
  }

  Anime _parseAnime(XmlDocument doc) {
    final root = doc.findAllElements('anime').first;

    final id = root.getAttribute('id') ?? '';
    final restricted =
        (root.getAttribute('restricted') ?? 'false').toLowerCase() == 'true';

    String? textOf(String tag) {
      final el = root.findElements(tag);
      if (el.isEmpty) return null;
      final txt = el.first.innerText.trim();
      return txt.isEmpty ? null : txt;
    }

    int? intOf(String tag) {
      final v = textOf(tag);
      return v == null ? null : int.tryParse(v);
    }

    DateTime? dateOf(String tag) {
      final v = textOf(tag);
      return v == null ? null : DateTime.tryParse(v);
    }

    // Titles
    final titles = <AnimeTitle>[];
    final titlesEl = root.findElements('titles');
    if (titlesEl.isNotEmpty) {
      for (final t in titlesEl.first.findElements('title')) {
        titles.add(
          AnimeTitle(
            text: t.innerText.trim(),
            lang: t.getAttribute('xml:lang'),
            type: t.getAttribute('type'),
          ),
        );
      }
    }

    // Related
    final related = <AnimeRelation>[];
    final relatedEl = root.findElements('relatedanime');
    if (relatedEl.isNotEmpty) {
      for (final a in relatedEl.first.findElements('anime')) {
        related.add(
          AnimeRelation(
            id: a.getAttribute('id') ?? '',
            relationType: a.getAttribute('type'),
            title: a.innerText.trim().isEmpty ? null : a.innerText.trim(),
          ),
        );
      }
    }

    // Similar
    final similar = <AnimeRelation>[];
    final similarEl = root.findElements('similaranime');
    if (similarEl.isNotEmpty) {
      for (final a in similarEl.first.findElements('anime')) {
        similar.add(
          AnimeRelation(
            id: a.getAttribute('id') ?? '',
            relationType: 'Similar',
            title: a.innerText.trim().isEmpty ? null : a.innerText.trim(),
          ),
        );
      }
    }

    // Creators
    final creators = <Creator>[];
    final creatorsEl = root.findElements('creators');
    if (creatorsEl.isNotEmpty) {
      for (final n in creatorsEl.first.findElements('name')) {
        creators.add(
          Creator(name: n.innerText.trim(), type: n.getAttribute('type')),
        );
      }
    }

    // Recommendations
    final recs = <AnimeRecommendation>[];
    final recsEl = root.findElements('recommendations');

    if (recsEl.isNotEmpty) {
      for (final r in recsEl.first.findElements('recommendation')) {
        final aidStr = r.getAttribute('aid');
        final aid = int.tryParse(aidStr ?? '');
        if (aid == null) continue;

        final content = r.innerText.trim();
        if (content.isEmpty) continue;

        recs.add(
          AnimeRecommendation(
            aid: aid,
            text: content,
            type: r.getAttribute('type'),
          ),
        );
      }
    }

    // URL a veces viene con espacios tipo "http: //"
    final rawUrl = textOf('url');
    final cleanedUrl = rawUrl?.replaceAll(' ', '');

    return Anime(
      id: id,
      restricted: restricted,
      type: textOf('type'),
      episodeCount: intOf('episodecount'),
      startDate: dateOf('startdate'),
      endDate: dateOf('enddate'),
      titles: titles,
      relatedAnime: related,
      similarAnime: similar,
      url: cleanedUrl,
      creators: creators,
      description: textOf('description'),
      recommendations: recs,
    );
  }
}
