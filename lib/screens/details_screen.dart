import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roig_anidb_api/models/models.dart';
import 'package:roig_anidb_api/provider/anidb_provider.dart';
import 'package:roig_anidb_api/widgets/widgets.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is! AnimePreview) {
      return const Scaffold(
        body: Center(
          child: Text('❌ No se recibió un AnimePreview en arguments'),
        ),
      );
    }

    final AnimePreview item = args;
    final p = context.watch<AniDbProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _CustomAppBar(item: item),
          SliverList(
            delegate: SliverChildListDelegate([
              _PosterAndTitle(item: item),
              _Overview(aid: item.id),
              const SizedBox(height: 20),

              CastingCards(pairs: p.similarPairs), //
            ]),
          ),
        ],
      ),
    );
  }
}

class _CustomAppBar extends StatelessWidget {
  final AnimePreview item;
  const _CustomAppBar({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.indigo,
      expandedHeight: 220,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: EdgeInsets.zero,
        title: Container(
          width: double.infinity,
          alignment: Alignment.bottomCenter,
          color: Colors.black45,
          padding: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
        ),
        background: FadeInImage(
          placeholder: const AssetImage('assets/loading.gif'),
          image: NetworkImage(item.posterUrl),
          fit: BoxFit.cover,
          imageErrorBuilder: (context, error, stack) {
            return Image.asset('assets/no-image.jpg', fit: BoxFit.cover);
          },
        ),
      ),
    );
  }
}

class _PosterAndTitle extends StatelessWidget {
  final AnimePreview item;
  const _PosterAndTitle({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              item.posterUrl,
              width: 110,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/no-image.jpg',
                width: 110,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title ?? 'Anime ${item.id}',
                  style: textTheme.headlineSmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.type ?? 'Unknown'} • ${item.episodeCount ?? '?'} eps',
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(_buildMetaLine(item), style: textTheme.bodyMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.star_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.permanentRating == null
                          ? 'Sin rating'
                          : item.permanentRating!.toStringAsFixed(2),
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildMetaLine(AnimePreview item) {
    final date = item.startDate;
    final dateTxt = (date == null)
        ? 'Sin fecha'
        : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'Estreno: $dateTxt';
  }
}

class _Overview extends StatelessWidget {
  final int aid;
  const _Overview({Key? key, required this.aid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AniDbProvider>();
    final anime = provider.getFromCache(aid);

    final desc = anime?.description;

    // Si ya tenemos descripción → la mostramos
    if (desc != null && desc.trim().isNotEmpty) {
      return _OverviewBody(text: desc);
    }

    // Si no, pedimos el detalle
    return FutureBuilder(
      future: context.read<AniDbProvider>().fetchAnime(aid),
      builder: (context, snapshot) {
        final animeNow = context.watch<AniDbProvider>().getFromCache(aid);
        final d = animeNow?.description;

        if (snapshot.connectionState == ConnectionState.waiting &&
            (d == null || d.isEmpty)) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.errorMessage != null && (d == null || d.isEmpty)) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return _OverviewBody(text: d ?? 'No hay descripción disponible.');
      },
    );
  }
}

class _OverviewBody extends StatelessWidget {
  final String text;
  const _OverviewBody({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cleaned = cleanDescription(text);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            cleaned,
            textAlign: TextAlign.justify,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

String cleanDescription(String raw) {
  return raw
      .replaceAll(RegExp(r'\*+'), '') // quita asteriscos
      .replaceAll(RegExp(r'\s+\n'), '\n') // limpia saltos
      .replaceAll(RegExp(r'\n{3,}'), '\n\n') // máx 2 saltos
      .trim();
}
