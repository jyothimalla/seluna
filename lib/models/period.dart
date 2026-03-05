import 'package:hive/hive.dart';

/// Manual TypeAdapter for Period — avoids build_runner code generation.
class PeriodAdapter extends TypeAdapter<Period> {
  @override
  final int typeId = 0;

  @override
  Period read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return Period(
      id: fields[0] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(fields[1] as int),
      endDate: fields[2] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[2] as int)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Period obj) {
    writer.writeByte(3);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.startDate.millisecondsSinceEpoch);
    writer.writeByte(2);
    writer.write(obj.endDate?.millisecondsSinceEpoch);
  }
}

class Period {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;

  const Period({
    required this.id,
    required this.startDate,
    this.endDate,
  });

  Period copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return Period(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  /// Number of days from startDate to endDate (inclusive).
  int get lengthInDays {
    if (endDate == null) return 1;
    return endDate!.difference(startDate).inDays + 1;
  }

  bool get isOngoing => endDate == null;

  /// Returns true if [date] falls within this period (inclusive).
  bool containsDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    if (endDate == null) return d == s;
    final e = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  /// Firestore serialisation
  Map<String, dynamic> toMap() => {
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate?.millisecondsSinceEpoch,
      };

  factory Period.fromMap(String id, Map<String, dynamic> map) => Period(
        id: id,
        startDate:
            DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
        endDate: map['endDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int)
            : null,
      );

  @override
  String toString() =>
      'Period(id: $id, start: $startDate, end: $endDate)';
}
