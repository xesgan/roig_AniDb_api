import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roig_anidb_api/models/models.dart';
import 'package:xml/xml.dart';

import '../models/anime.dart';

// Provider (estado + peticiones) para consumir AniDB y notificar a la UI
class AniDbProvider extends ChangeNotifier {
  final String client;
  final int clientVer;

  AniDbProvider({required this.client, required this.clientVer});

  // Listas que se pintan en la UI
  List<AnimePreview> randomList = [];
  List<AnimePreview> hotList = [];
  List<SimilarPair> similarPairs = [];

  // ===== State =====
  bool isLoading = false;
  bool isLoadingList = false;
  String? errorMessage;

  // Cache por id (aid) para no pedir lo mismo repetidamente
  final Map<int, Anime> _cache = {};

  // Para no spamear AniDB (mínimo 2s entre requests) (Control rate)
  DateTime _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Carga una lista de animes recomendados aleatoriamente(id)
  Future<void> fetchRandomRecommendationList() async {
    isLoadingList = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Construccion de la query
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

      // Lanza request
      final res = await http.get(uri);

      // Valida el estado HTTP
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      // Decodifica bytes -> string (evita problemas de encoding)
      final xmlStr = utf8.decode(res.bodyBytes);
      final doc = XmlDocument.parse(xmlStr);

      // Convierte XML a lista de previews
      randomList = parseRandomRecommendation(doc);
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

      // Convierte XML a lista de previews
      hotList = parseHotAnime(doc);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Carga un anime por id (aid).
  Future<Anime?> fetchAnime(int aid, {bool force = false}) async {
    errorMessage = null;

    // Cache hit (si no forzamos)
    if (!force && _cache.containsKey(aid)) {
      return _cache[aid];
    }

    // Respetamos el minimo de tiempo entre respuestas
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

      // Pide gzip si el servidor lo soporta
      final res = await http.get(
        uri,
        headers: const {'Accept-Encoding': 'gzip'},
      );

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final xmlStr = utf8.decode(res.bodyBytes);
      final doc = XmlDocument.parse(xmlStr);

      // Parseo del XML a modelo Anime completo
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

  // Carga pares aleatorios "similar" (source/target con imagen)
  Future<void> fetchRandomSimilar() async {
    errorMessage = null;
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
          'client': client.toLowerCase(),
          'clientver': clientVer.toString(),
          'protover': '1',
          'request': 'randomsimilar',
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

      // Convierte XML a lista de SimilarPair
      similarPairs = _parseRandomSimilar(doc);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =======================
  // Helpers internos
  // =======================

  // Getter simple de cache
  Anime? getFromCache(int aid) => _cache[aid];

  // Throttle: asegura minimo 2s entre requests
  Future<void> _throttle() async {
    final now = DateTime.now();
    final diff = now.difference(_lastRequestAt);

    // AniDB: 1 request cada 2s (safe)
    const minGap = Duration(seconds: 2);

    // // Si no ha pasado el tiempo mínimo, espera la diferencia
    if (diff < minGap) {
      await Future.delayed(minGap - diff);
    }

    // Marca el momento de la request (post-wait)
    _lastRequestAt = DateTime.now();
  }

  // Alias (mismo que getFromCache)
  Anime? getAnime(int aid) => getFromCache(aid);

  // Pre-carga (prefetch) para suavizar navegacion en una lista
  void preloadForIndex(int index) {
    // Evita indices invalidos
    if (index < 0 || index >= randomList.length) return;

    final aid = randomList[index].id;

    // Si no está en cache, lo pido
    if (getFromCache(aid) == null) {
      fetchAnime(aid);
    }

    // Preload del siguiente para que al swipar vaya “instant”
    if (index + 1 < randomList.length) {
      final nextAid = randomList[index + 1].id;
      if (getFromCache(nextAid) == null) {
        fetchAnime(nextAid);
      }
    }
  }

  // Parseo de randomrecommendation -> lista de previews
  List<AnimePreview> parseRandomRecommendation(XmlDocument doc) {
    final list = <AnimePreview>[];

    // AniDB devueve <anime ...> repetidos
    for (final anime in doc.findAllElements('anime')) {
      final id = int.tryParse(anime.getAttribute('id') ?? '');
      if (id == null) continue;

      // Parser boolean tipo "true/false"
      bool parseBool(String? v) => (v ?? '').toLowerCase() == 'true';

      // Lee el innerText de un tag si existe y no está vacío
      String? textOf(String tag) {
        final els = anime.findElements(tag);
        if (els.isEmpty) return null;
        final t = els.first.innerText.trim();
        return t.isEmpty ? null : t;
      }

      // Helpers para int y DateTime desde tags
      int? intOf(String tag) => int.tryParse(textOf(tag) ?? '');
      DateTime? dateOf(String tag) => DateTime.tryParse(textOf(tag) ?? '');

      // Title: aquí pillo el primero que venga
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

      // Construye el preview ya mapeado a tu modelo
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

  // Parseo de hotanime -> lista de previews
  List<AnimePreview> parseHotAnime(XmlDocument doc) {
    final list = <AnimePreview>[];

    // En hotanime uso rootElement directamente
    for (final a in doc.rootElement.findElements('anime')) {
      final id = int.tryParse(a.getAttribute('id') ?? '');
      if (id == null) continue;

      // restricted viene como atributo
      final restricted =
          (a.getAttribute('restricted') ?? 'false').toLowerCase() == 'true';

      // Helper para leer tags hijos
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

      // Lee ratings/<tag> dentro de <ratings>
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

  // Parseo del detalle anime -> modelo Anime completo
  Anime _parseAnime(XmlDocument doc) {
    final root = doc.rootElement;

    // Lee tag directo del root (primer nivel)
    String? textOf(String tag) {
      final el = root.getElement(tag);
      if (el == null) return null;
      final t = el.innerText.trim();
      return t.isEmpty ? null : t;
    }

    // Booleans tipo "true/1"
    bool parseBool(String? v) =>
        v != null && (v.toLowerCase() == 'true' || v == '1');

    // Helpers para tipos
    DateTime? parseDate(String? v) {
      if (v == null) return null;
      return DateTime.tryParse(v);
    }

    int? parseInt(String? v) {
      if (v == null) return null;
      return int.tryParse(v);
    }

    // --- titles ---
    // AniDB a veces envuelve títulos en <titles>, a veces no
    final titles = <AnimeTitle>[];
    final titlesEl = root.getElement('titles');
    if (titlesEl != null) {
      for (final t in titlesEl.findElements('title')) {
        titles.add(
          AnimeTitle(
            lang: t.getAttribute('xml:lang'),
            type: t.getAttribute('type'),
            text: t.innerText.trim(),
          ),
        );
      }
    } else {
      for (final t in root.findElements('title')) {
        titles.add(
          AnimeTitle(
            lang: t.getAttribute('xml:lang'),
            type: t.getAttribute('type'),
            text: t.innerText.trim(),
          ),
        );
      }
    }

    // --- related / similar ---
    List<AnimeRelation> parseRelations(String tag) {
      final out = <AnimeRelation>[];
      final el = root.getElement(tag);
      if (el == null) return out;
      for (final a in el.findElements('anime')) {
        out.add(
          AnimeRelation(
            id: a.getAttribute('id') ?? '',
            title: a.innerText.trim(),
          ),
        );
      }
      return out;
    }

    // --- creators ---
    final creators = <Creator>[];
    final creatorsEl = root.getElement('creators');
    if (creatorsEl != null) {
      for (final n in creatorsEl.findElements('name')) {
        creators.add(
          Creator(type: n.getAttribute('type'), name: n.innerText.trim()),
        );
      }
    }

    // --- recommendations ---
    // Recomendaciones son texto + type, y las asocias al aid actual
    final recs = <AnimeRecommendation>[];
    final recsEl = root.getElement('recommendations');

    if (recsEl != null) {
      final aidStr = root.getAttribute('id');
      final aid = int.tryParse(aidStr ?? '');

      if (aid != null) {
        for (final r in recsEl.findElements('recommendation')) {
          final txt = r.innerText.trim();
          if (txt.isEmpty) continue;

          recs.add(
            AnimeRecommendation(
              aid: aid,
              text: txt,
              type: r.getAttribute('type'),
            ),
          );
        }
      }
    }

    // Devuelve el modelo final mapeando campos
    return Anime(
      id: root.getAttribute('id') ?? '',
      restricted: parseBool(root.getAttribute('restricted')),
      type: textOf('type'),
      episodeCount: parseInt(textOf('episodecount')),
      startDate: parseDate(textOf('startdate')),
      endDate: parseDate(textOf('enddate')),
      titles: titles,
      relatedAnime: parseRelations('relatedanime'),
      similarAnime: parseRelations('similaranime'),
      url: textOf('url'),
      creators: creators,
      description: textOf('description'),
      recommendations: recs,
    );
  }
}

// Parseo standalone (fuera del provider) de randomsimilar
List<SimilarPair> _parseRandomSimilar(XmlDocument doc) {
  final list = <SimilarPair>[];

  final root = doc.rootElement; // <randomsimilar>
  for (final sim in root.findElements('similar')) {
    final srcEl = sim.getElement('source');
    final tgtEl = sim.getElement('target');
    if (srcEl == null || tgtEl == null) continue;

    // Convierte <source aid=".."><picture>...</picture></source> a item
    SimilarImageItem? parseItem(XmlElement el) {
      final aidStr = el.getAttribute('aid');
      final pic = el.getElement('picture')?.innerText.trim();
      if (aidStr == null || pic == null || pic.isEmpty) return null;

      final aid = int.tryParse(aidStr);
      if (aid == null) return null;

      return SimilarImageItem(aid: aid, picture: pic);
    }

    final src = parseItem(srcEl);
    final tgt = parseItem(tgtEl);
    if (src == null || tgt == null) continue;

    list.add(SimilarPair(source: src, target: tgt));
  }

  return list;
}
