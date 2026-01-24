import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roig_spaceflight_api/models/models.dart';
import 'package:roig_spaceflight_api/provider/anidb_provider.dart';

class CardSwiper extends StatelessWidget {
  final List<AnimePreview> items;

  const CardSwiper({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: double.infinity,
      height: size.height * 0.52,
      child: Swiper(
        itemCount: items.length,
        loop: true,
        layout: SwiperLayout.STACK,
        itemWidth: size.width * 0.72,
        itemHeight: size.height * 0.50,
        onIndexChanged: (i) => context.read<AniDbProvider>().preloadForIndex(i),
        itemBuilder: (_, i) => _AnimePosterCard(preview: items[i]),
      ),
    );
  }
}

class _AnimePosterCard extends StatelessWidget {
  final AnimePreview preview;

  const _AnimePosterCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AniDbProvider>();

    final anime = provider.getFromCache(preview.id);
    final title = anime != null
        ? _pickBestTitle(anime)
        : (preview.title ?? 'Anime ${preview.id}');

    final subtitle = anime != null
        ? '${anime.type ?? 'Unknown'} • ${anime.episodeCount ?? '?'} eps'
        : '${preview.type ?? 'Unknown'} • ${preview.episodeCount ?? '?'} eps';

    return GestureDetector(
      onTap: () {
        context.read<AniDbProvider>().fetchAnime(preview.id);
        Navigator.pushNamed(context, 'details', arguments: preview);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen
            Image.network(
              preview.posterUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Image.asset('assets/no-image.jpg', fit: BoxFit.cover);
              },
              errorBuilder: (context, error, stack) {
                debugPrint('❌ Poster failed: $error');
                debugPrint('URL: ${preview.posterUrl}');
                return Image.asset('assets/no-image.jpg', fit: BoxFit.cover);
              },
            ),

            // Degradado abajo para que el texto se lea
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54, Colors.black87],
                ),
              ),
            ),

            // Texto abajo
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _Chip(text: preview.restricted ? 'Restricted' : 'OK'),
                      const SizedBox(width: 8),
                      if (preview.recommendationsCount != null)
                        _Chip(text: 'Recs: ${preview.recommendationsCount}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pickBestTitle(Anime anime) {
    final titles = anime.titles;

    String? find({String? lang, String? type}) {
      for (final t in titles) {
        final okLang = (lang == null) || (t.lang == lang);
        final okType = (type == null) || (t.type == type);
        if (okLang && okType && t.text.trim().isNotEmpty) return t.text.trim();
      }
      return null;
    }

    return find(lang: 'en', type: 'official') ??
        find(type: 'main') ??
        (titles.isNotEmpty ? titles.first.text.trim() : 'Anime ${anime.id}');
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}
