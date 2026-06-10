import '../models/parsed_student.dart';

/// Result of parsing a CSV string — callers must handle both cases.
sealed class CsvResult {
  const CsvResult();
}

final class CsvSuccess extends CsvResult {
  final List<ParsedStudent> students;
  final int malformedCount;
  final bool wasTruncated;

  const CsvSuccess({
    required this.students,
    this.malformedCount = 0,
    this.wasTruncated = false,
  });
}

final class CsvFailure extends CsvResult {
  final String message;
  final int? row;

  const CsvFailure(this.message, {this.row});
}
