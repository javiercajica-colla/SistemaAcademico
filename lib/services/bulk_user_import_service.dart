import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import '../models/models.dart';

// Resultado de parsear una fila del archivo de importación masiva.
// `error` es null cuando la fila es válida y está lista para procesarse.
class ParsedUserRow {
  final int rowNumber;
  final String firstName;
  final String lastName;
  final UserRole? role;
  final String documentId;
  final String? specialization;
  final String? courseName;
  final String? phone;
  final String? relationship;
  final String? error;

  ParsedUserRow({
    required this.rowNumber,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.documentId,
    this.specialization,
    this.courseName,
    this.phone,
    this.relationship,
    this.error,
  });

  bool get isValid => error == null;
  String get fullName => '$firstName $lastName';
}

class BulkUserImportService {
  // Genera un .xlsx con los encabezados esperados y filas de ejemplo, para
  // que el coordinador sepa exactamente cómo estructurar el archivo a importar.
  static List<int> generateTemplateXlsxBytes() {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Usuarios');
    final sheet = excel['Usuarios'];

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
    );

    const headers = [
      'nombres',
      'apellidos',
      'rol',
      'documento',
      'especializacion',
      'curso',
      'telefono',
      'parentesco',
    ];
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
      sheet.setColumnWidth(c, 16);
    }

    const exampleRows = [
      ['Juan', 'Pérez', 'docente', '100234', 'Matemáticas', '', '', ''],
      ['María', 'Gómez', 'estudiante', '100235', '', '6°A', '', ''],
      ['Carlos', 'Ruiz', 'padre', '100236', '', '', '3001234567', 'Padre'],
    ];
    for (var r = 0; r < exampleRows.length; r++) {
      for (var c = 0; c < exampleRows[r].length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1),
        );
        cell.value = TextCellValue(exampleRows[r][c]);
      }
    }

    return excel.encode()!;
  }

  static List<ParsedUserRow> parseExcelBytes(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) return [];
    final rows = sheet.rows
        .map(
          (row) =>
              row.map((cell) => cell?.value?.toString().trim() ?? '').toList(),
        )
        .toList();
    return _parseRows(rows);
  }

  static List<ParsedUserRow> parseCsvBytes(List<int> bytes) {
    final content = utf8.decode(bytes);
    final rawRows = const CsvToListConverter(
      eol: '\n',
    ).convert(content, shouldParseNumbers: false);
    final rows = rawRows
        .map((row) => row.map((c) => c.toString().trim()).toList())
        .toList();
    return _parseRows(rows);
  }

  static List<ParsedUserRow> _parseRows(List<List<String>> rows) {
    if (rows.isEmpty) return [];
    final header = rows.first.map(_normalize).toList();

    int colIndex(List<String> candidates) {
      for (final name in candidates) {
        final i = header.indexOf(name);
        if (i != -1) return i;
      }
      return -1;
    }

    final iNombres = colIndex(['nombres', 'nombre']);
    final iApellidos = colIndex(['apellidos', 'apellido']);
    final iRol = colIndex(['rol', 'role']);
    final iDocumento = colIndex([
      'documento',
      'documentodeidentidad',
      'cedula',
      'identificacion',
    ]);
    final iEspecializacion = colIndex(['especializacion', 'especialidad']);
    final iCurso = colIndex(['curso', 'grado']);
    final iTelefono = colIndex(['telefono', 'celular']);
    final iParentesco = colIndex(['parentesco']);

    String cell(List<String> row, int i) =>
        (i >= 0 && i < row.length) ? row[i].trim() : '';
    String? cellOrNull(List<String> row, int i) {
      final v = cell(row, i);
      return v.isEmpty ? null : v;
    }

    final result = <ParsedUserRow>[];
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.every((c) => c.trim().isEmpty)) continue;

      final firstName = cell(row, iNombres);
      final lastName = cell(row, iApellidos);
      final roleRaw = cell(row, iRol);
      final documentId = cell(row, iDocumento);
      final role = _parseRole(roleRaw);

      String? error;
      if (firstName.isEmpty || lastName.isEmpty) {
        error = 'Nombres o apellidos vacíos';
      } else if (role == null) {
        error = 'Rol no válido: "$roleRaw"';
      } else if (documentId.isEmpty) {
        error = 'Documento de identidad vacío';
      }

      result.add(
        ParsedUserRow(
          rowNumber: r + 1,
          firstName: firstName,
          lastName: lastName,
          role: role,
          documentId: documentId,
          specialization: cellOrNull(row, iEspecializacion),
          courseName: cellOrNull(row, iCurso),
          phone: cellOrNull(row, iTelefono),
          relationship: cellOrNull(row, iParentesco),
          error: error,
        ),
      );
    }
    return result;
  }

  static String _normalize(String input) {
    const accented = 'áéíóúñÁÉÍÓÚÑ';
    const plain = 'aeiounAEIOUN';
    var out = input.trim().toLowerCase();
    for (var i = 0; i < accented.length; i++) {
      out = out.replaceAll(accented[i], plain[i].toLowerCase());
    }
    return out.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static UserRole? _parseRole(String raw) {
    switch (_normalize(raw)) {
      case 'docente':
      case 'profesor':
      case 'teacher':
        return UserRole.teacher;
      case 'estudiante':
      case 'alumno':
      case 'student':
        return UserRole.student;
      case 'padre':
      case 'madre':
      case 'acudiente':
      case 'padredefamilia':
      case 'tutor':
      case 'parent':
        return UserRole.parent;
      case 'coordinador':
      case 'coordinator':
        return UserRole.coordinator;
      case 'administrador':
      case 'admin':
        return UserRole.admin;
      default:
        return null;
    }
  }
}
