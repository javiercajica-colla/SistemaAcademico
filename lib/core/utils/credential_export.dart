import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'download_helper.dart';
import '../../services/credential_log_service.dart';

// Genera y descarga un PDF/Excel con la lista de credenciales dada.
// No consulta CredentialLogService directamente: el llamador decide si usa
// el registro completo de la sesión o solo un subconjunto (p. ej. un lote
// de importación masiva).
Future<void> exportCredentialsPdf(List<CredentialLogEntry> entries) async {
  final doc = pw.Document();
  final bold = pw.Font.helveticaBold();
  final regular = pw.Font.helvetica();
  const navy = PdfColor(0.118, 0.227, 0.541);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        pw.Text(
          'Credenciales de Usuarios Generadas',
          style: pw.TextStyle(font: bold, fontSize: 16, color: navy),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generado el ${DateTime.now().toString().split('.').first} — Solo incluye usuarios creados en esta sesión',
          style: pw.TextStyle(
            font: regular,
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.8),
            1: pw.FlexColumnWidth(1.8),
            2: pw.FlexColumnWidth(1.4),
            3: pw.FlexColumnWidth(1.4),
            4: pw.FlexColumnWidth(1.6),
            5: pw.FlexColumnWidth(1.6),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: navy),
              children:
                  [
                        'Nombre',
                        'Apellido',
                        'Documento',
                        'Rol',
                        'Usuario',
                        'Contraseña',
                      ]
                      .map(
                        (h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            h,
                            style: pw.TextStyle(
                              font: bold,
                              fontSize: 9,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            ...entries.map(
              (e) => pw.TableRow(
                children:
                    [
                          e.firstName,
                          e.lastName,
                          e.documentId,
                          e.roleLabel,
                          e.username,
                          e.password,
                        ]
                        .map(
                          (v) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              v,
                              style: pw.TextStyle(font: regular, fontSize: 9),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  final bytes = await doc.save();
  downloadBytes(
    bytes,
    'credenciales_usuarios_${DateTime.now().millisecondsSinceEpoch}.pdf',
  );
}

Future<void> exportCredentialsExcel(List<CredentialLogEntry> entries) async {
  final excel = Excel.createExcel();
  excel.rename('Sheet1', 'Credenciales');
  final sheet = excel['Credenciales'];

  final headerStyle = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
    horizontalAlign: HorizontalAlign.Center,
  );

  const headers = [
    'Nombre',
    'Apellido',
    'Documento',
    'Rol',
    'Usuario',
    'Contraseña',
  ];
  for (int c = 0; c < headers.length; c++) {
    _excelCredCell(sheet, 0, c, headers[c], style: headerStyle);
  }
  const widths = [20.0, 20.0, 16.0, 16.0, 18.0, 16.0];
  for (int c = 0; c < widths.length; c++) {
    sheet.setColumnWidth(c, widths[c]);
  }

  for (int r = 0; r < entries.length; r++) {
    final e = entries[r];
    final values = [
      e.firstName,
      e.lastName,
      e.documentId,
      e.roleLabel,
      e.username,
      e.password,
    ];
    for (int c = 0; c < values.length; c++) {
      _excelCredCell(sheet, r + 1, c, values[c]);
    }
  }

  final bytes = excel.encode();
  if (bytes != null) {
    downloadBytes(
      bytes,
      'credenciales_usuarios_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
  }
}

void _excelCredCell(
  Sheet sheet,
  int row,
  int col,
  String value, {
  CellStyle? style,
}) {
  final cell = sheet.cell(
    CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
  );
  cell.value = TextCellValue(value);
  if (style != null) cell.cellStyle = style;
}
