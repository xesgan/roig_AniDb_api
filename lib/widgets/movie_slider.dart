import 'package:flutter/material.dart';
import 'package:roig_spaceflight_api/models/models.dart';

class MovieSlider extends StatelessWidget {
  final List<AnimePreview> items;
  const MovieSlider({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 270,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'HOT ANIMES',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _MoviePoster(item: items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MoviePoster extends StatelessWidget {
  final AnimePreview item;
  const _MoviePoster({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, 'details', arguments: item),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                item.posterUrl,
                width: 130,
                height: 190,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Image.asset(
                    'assets/no-image.jpg',
                    fit: BoxFit.cover,
                    width: 130,
                    height: 190,
                  );
                },
                errorBuilder: (context, error, stack) {
                  debugPrint('❌ Poster failed: $error');
                  debugPrint('URL: ${item.posterUrl}');
                  return Image.asset(
                    'assets/no-image.jpg',
                    fit: BoxFit.cover,
                    width: 130,
                    height: 190,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.title ?? 'Anime ${item.id}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
