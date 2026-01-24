import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roig_spaceflight_api/provider/anidb_provider.dart';
import 'package:roig_spaceflight_api/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final p = context.read<AniDbProvider>();
      await p.fetchRandomRecommendationList();
      await p.fetchHotAnime();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AniDB'),
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_outlined)),
        ],
      ),
      body: Consumer<AniDbProvider>(
        builder: (_, p, _) {
          if (p.isLoadingList) {
            return const Center(child: CircularProgressIndicator());
          }
          if (p.errorMessage != null) {
            return Center(
              child: Text(
                p.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.60,
                  child: CardSwiper(items: p.randomList),
                ),

                const SizedBox(height: 10),

                SizedBox(height: 270, child: MovieSlider(items: p.hotList)),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
