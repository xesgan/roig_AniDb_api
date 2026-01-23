import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:roig_spaceflight_api/models/models.dart';

class CardSwiper extends StatelessWidget {
  final List<Articles> articles;

  const CardSwiper({Key? key, required this.articles}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      height: size.height * 0.5,
      // color: Colors.red,
      child: Swiper(
        itemCount: articles.length,
        layout: SwiperLayout.STACK,
        itemWidth: size.width * 0.6,
        itemHeight: size.height * 0.4,
        itemBuilder: (BuildContext context, int index) {
          final article = articles[index];
          // debugPrint(article.getImageUrl);
          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              'details',
              arguments: 'detalls peli',
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                article.getImageUrlSafe,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Image.asset('assets/no-image.jpg', fit: BoxFit.cover);
                },
                errorBuilder: (context, error, stack) {
                  debugPrint('❌ Image failed: $error');
                  debugPrint('URL: ${article.getImageUrlSafe}');
                  return Image.asset('assets/no-image.jpg', fit: BoxFit.cover);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
