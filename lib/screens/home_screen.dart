import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roig_anidb_api/provider/anidb_provider.dart';
import 'package:roig_anidb_api/widgets/widgets.dart';

// Pantalla principal (Home) con estado porque lanzo cargas en initState
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

    // Microtask: ejecuta después de que el widget se haya montado
    // (evita usar context “demasiado pronto” en initState)
    Future.microtask(() async {
      final p = context
          .read<AniDbProvider>(); // lee el provider sin escuchar cambios
      await p.fetchRandomRecommendationList(); // carga carrusel principal
      await p.fetchHotAnime(); // carga slider de “hot”
      await p.fetchRandomSimilar(); // carga pares “similar” (si los usas en UI)
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
      // Consumer: reconstruye solo este body cuando AniDbProvider notifica cambios
      body: Consumer<AniDbProvider>(
        builder: (_, p, _) {
          // Loading principal para la lista random (tu condición actual)
          if (p.isLoadingList) {
            return const Center(child: CircularProgressIndicator());
          }
          // Error genérico mostrado en rojo
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
