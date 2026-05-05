// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodEntryAdapter extends TypeAdapter<FoodEntry> {
  @override
  final int typeId = 0;

  @override
  FoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodEntry(
      name: fields[0] as String,
      calories: fields[1] as double,
      protein: fields[2] as double,
      carbs: fields[3] as double,
      fat: fields[4] as double,
      timestamp: fields[5] as DateTime,
      imagePath: fields[6] as String?,
      emoji: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FoodEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.calories)
      ..writeByte(2)
      ..write(obj.protein)
      ..writeByte(3)
      ..write(obj.carbs)
      ..writeByte(4)
      ..write(obj.fat)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.imagePath)
      ..writeByte(7)
      ..write(obj.emoji);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
