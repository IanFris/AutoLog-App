import 'package:intl/intl.dart';

import '../models/service_log.dart';

class ServiceLogCsvExporter {
  static const List<String> headers = [
    'Tanggal Servis',
    'Jenis Servis',
    'Odometer (KM)',
    'Bengkel',
    'Biaya (Rp)',
    'Catatan',
  ];

  static String createCsv(List<ServiceLog> logs) {
    final rows = <List<String>>[
      headers,
      for (final log in logs)
        [
          DateFormat('yyyy-MM-dd').format(log.serviceDate),
          log.serviceTypeName ?? 'Pemeliharaan',
          log.odometerKm.toString(),
          log.workshopName,
          log.cost.toStringAsFixed(2),
          log.notes ?? '',
        ],
    ];

    return '\uFEFF${rows.map((row) => row.map(_escape).join(',')).join('\r\n')}';
  }

  static String _escape(String value) {
    final formulaPrefix = RegExp(r'^[\s\x00-\x1F]*[=+\-@]');
    final safeValue = formulaPrefix.hasMatch(value) ? "'$value" : value;
    return '"${safeValue.replaceAll('"', '""')}"';
  }
}
