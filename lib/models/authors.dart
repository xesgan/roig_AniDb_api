import 'package:roig_spaceflight_api/models/models.dart';

class Author {
  String name;
  dynamic socials;

  Author({required this.name, required this.socials});

  factory Author.fromJson(String str) => Author.fromMap(json.decode(str));

  factory Author.fromMap(Map<String, dynamic> json) =>
      Author(name: json["name"], socials: json["socials"]);
}
