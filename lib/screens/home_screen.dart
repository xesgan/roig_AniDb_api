import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roig_spaceflight_api/provider/articles_provider.dart';
import 'package:roig_spaceflight_api/widgets/card_swiper.dart';
import 'package:roig_spaceflight_api/widgets/movie_slider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final articleProvider = Provider.of<ArticlesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Space Flights News'),
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_outlined)),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              // Targetes principals
              CardSwiper(articles: articleProvider.featuredArticles),

              // Slider de pel·licules
              MovieSlider(articles: articleProvider.noFeaturedArticles),
              // Poodeu fer la prova d'afegir-ne uns quants, veureu com cada llista és independent
              // MovieSlider(),
              // MovieSlider(),
            ],
          ),
        ),
      ),
    );
  }
}
