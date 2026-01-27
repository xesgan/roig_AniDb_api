import 'package:flutter/material.dart';
import 'package:roig_anidb_api/models/models.dart';

class CastingCards extends StatelessWidget {
  final List<SimilarPair> pairs; // <-- lo que viene del provider

  const CastingCards({Key? key, required this.pairs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pairs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      width: double.infinity,
      height: 180,
      child: ListView.builder(
        itemCount: pairs.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (BuildContext context, int index) {
          final pair = pairs[index];

          // Pintamos 2 “cards”: source + target (solo imagen)
          return Row(
            children: [
              _CastCard(item: pair.source),
              _CastCard(item: pair.target),
            ],
          );
        },
      ),
    );
  }
}

class _CastCard extends StatelessWidget {
  final SimilarImageItem item;
  const _CastCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 110,
      height: 180,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FadeInImage(
              placeholder: const AssetImage('assets/no-image.jpg'),
              image: NetworkImage(item.posterUrl),
              height: 140,
              width: 100,
              fit: BoxFit.cover,
              imageErrorBuilder: (_, __, ___) {
                return Image.asset(
                  'assets/no-image.jpg',
                  height: 140,
                  width: 100,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          const SizedBox(height: 5),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
