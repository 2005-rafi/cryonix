class ParsedStudent {
  final String rollNumber;
  final String name;

  const ParsedStudent({required this.rollNumber, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedStudent &&
          rollNumber == other.rollNumber &&
          name == other.name;

  @override
  int get hashCode => Object.hash(rollNumber, name);

  ParsedStudent copyWith({String? rollNumber, String? name}) => ParsedStudent(
        rollNumber: rollNumber ?? this.rollNumber,
        name: name ?? this.name,
      );
}
