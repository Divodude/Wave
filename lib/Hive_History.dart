import 'package:hive/hive.dart';

part 'Hive_History.g.dart'; // This will be generated

@HiveType(typeId: 1)
class HiveHistory extends HiveObject {
  @HiveField(0)
  String? songName;

  @HiveField(1)
  String? artistName;

 

  @HiveField(3)
  String? imageUrl;

  @HiveField(4)
  String? songUrl;

  @HiveField(5)
  int? duration;

  HiveHistory({
    this.songName,
    this.artistName,
    this.imageUrl,
    this.songUrl,
    this.duration,
  });
}

@HiveType(typeId:2)
class SearchHistory
 extends HiveObject {

@HiveField(6)
String? searchquery;


SearchHistory({
  this.searchquery
});




 }




