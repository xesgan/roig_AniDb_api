import 'package:flutter/material.dart';
import 'package:roig_spaceflight_api/models/models.dart';
import 'package:roig_spaceflight_api/widgets/casting_cards.dart';

class DetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Canviar després per una instància de Peli
    // final Articles article =
    //     ModalRoute.of(context)?.settings.arguments as Articles;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // _CustomAppBar(article: article),
          SliverList(
            delegate: SliverChildListDelegate([
              // _PosterAndTitile(article: article),
              // _Overview(article: article),
              // _Overview(article: article),
              CastingCards(),
            ]),
          ),
        ],
      ),
    );
  }
}

// class _CustomAppBar extends StatelessWidget {
//   final Articles article;
//   const _CustomAppBar({Key? key, required this.article});
//   @override
//   Widget build(BuildContext context) {
//     // Exactament igual que la AppBaer però amb bon comportament davant scroll
//     return SliverAppBar(
//       backgroundColor: Colors.indigo,
//       expandedHeight: 200,
//       floating: false,
//       pinned: true,
//       flexibleSpace: FlexibleSpaceBar(
//         centerTitle: true,
//         titlePadding: EdgeInsets.all(0),
//         title: Container(
//           width: double.infinity,
//           alignment: Alignment.bottomCenter,
//           color: Colors.black12,
//           padding: const EdgeInsets.only(bottom: 10),
//           // child: Text(article.getArticleTitle, style: TextStyle(fontSize: 16)),
//         ),
//         background: FadeInImage(
//           placeholder: AssetImage('assets/loading.gif'),
//           image: NetworkImage(article.getImageUrlSafe),
//           fit: BoxFit.cover,
//         ),
//       ),
//     );
//   }
// }

// class _PosterAndTitile extends StatelessWidget {
//   // final Articles article;
//   const _PosterAndTitile({Key? key, required this.article});
//   @override
//   Widget build(BuildContext context) {
//     final TextTheme textTheme = Theme.of(context).textTheme;
//     return Container(
//       margin: const EdgeInsets.only(top: 20),
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Row(
//         children: [
//           // ClipRRect(
//           //   borderRadius: BorderRadius.circular(20),
//           //   child: Container(
//           //     width: 110,
//           //     height: 160,
//           //     color: Colors.grey.shade300,
//           //     alignment: Alignment.center,
//           //   ),
//           // ),
//           const SizedBox(width: 20),
//           // 🟨 TEXTO (con ancho limitado)
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   article.getArticleTitle,
//                   style: textTheme.headlineSmall,
//                   maxLines: 5,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     const Icon(Icons.webhook, color: Colors.teal),
//                     const SizedBox(width: 7),
//                     Text(
//                       article.newsSite, // o título original
//                       style: textTheme.titleMedium,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//                 Padding(padding: EdgeInsetsGeometry.all(10)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Overview extends StatelessWidget {
//   final Articles article;
//   const _Overview({Key? key, required this.article});
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           child: Text(
//             article.summary,
//             textAlign: TextAlign.justify,
//             style: Theme.of(context).textTheme.titleMedium,
//           ),
//         ),
//         Container(child: Text('Published at ${article.getPublishedAt}')),
//         const SizedBox(height: 30),
//       ],
//     );
//   }
// }
