// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Hive_History.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveHistoryAdapter extends TypeAdapter<HiveHistory> {
  @override
  final int typeId = 1;

  @override
  HiveHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveHistory(
      songName: fields[0] as String?,
      artistName: fields[1] as String?,
      imageUrl: fields[3] as String?,
      songUrl: fields[4] as String?,
      duration: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveHistory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.songName)
      ..writeByte(1)
      ..write(obj.artistName)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.songUrl)
      ..writeByte(5)
      ..write(obj.duration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SearchHistoryAdapter extends TypeAdapter<SearchHistory> {
  @override
  final int typeId = 2;

  @override
  SearchHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SearchHistory(
      searchquery: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SearchHistory obj) {
    writer
      ..writeByte(1)
      ..writeByte(6)
      ..write(obj.searchquery);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
