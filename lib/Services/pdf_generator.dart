import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/order.dart';

class PDFGeneratorService {
  static Future<String?> generateDeliveryOrderPDF({
    required String clientName,
    required String address,
    required String date,
    required List<OrderItem> items,
    required String paymentDate,
    required String paymentAmount,
    required String outstanding,
    required String totalBill,
  }) async {
    // Request storage permission
    if (!await Permission.manageExternalStorage.request().isGranted &&
        !await Permission.storage.request().isGranted) {
      return null; // Permission denied
    }

    final pdf = pw.Document();

    // Collect all unique length columns dynamically
    final allLengths = <String>{};
    for (var item in items) {
      allLengths.addAll(item.lengths.keys);
    }
    final sortedLengths = allLengths.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          // Collect all unique length columns dynamically
          final allLengths = <String>{};
          for (var item in items) {
            allLengths.addAll(item.lengths.keys);
          }
          final sortedLengths = allLengths.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

          // Prepare table header rows
          final headerRow1 = [
            pw.Text('Color', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('P.Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Width', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Thickness', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ];
          final headerRow2 = [];

          for (var len in sortedLengths) {
            headerRow1.add(pw.Text(len, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
            headerRow1.add(pw.Text('')); // Placeholder for sub-column
            headerRow2.add(pw.Text('Ton', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
            headerRow2.add(pw.Text('PCS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          }

          headerRow1.add(pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          headerRow2.add(pw.Text(''));

          // Table rows for items
          final dataRows = items.map((item) {
            final row = [
              pw.Text(item.color),
              pw.Text(item.pType),
              pw.Text(item.width),
              pw.Text(item.thickness),
            ];
            for (var len in sortedLengths) {
              row.add(pw.Text(item.lengths[len]?['ton'] ?? '0'));
              row.add(pw.Text(item.lengths[len]?['pcs'] ?? '0'));
            }
            row.add(pw.Text(item.amount));
            return pw.TableRow(
              children: row.map((w) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: w)).toList(),
            );
          }).toList();

          // Totals per length
          final totalTons = <String, double>{};
          final totalPcs = <String, int>{};
          for (var len in sortedLengths) {
            totalTons[len] = 0;
            totalPcs[len] = 0;
            for (var item in items) {
              totalTons[len] = totalTons[len]! + (double.tryParse(item.lengths[len]?['ton'] ?? '0') ?? 0);
              totalPcs[len] = totalPcs[len]! + (int.tryParse(item.lengths[len]?['pcs'] ?? '0') ?? 0);
            }
          }
          final grandTotal = items.fold<double>(0, (prev, e) => prev + (double.tryParse(e.amount) ?? 0));

          // Total row
          final totalRow = [
            pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(''),
            pw.Text(''),
            pw.Text(''),
          ];
          for (var len in sortedLengths) {
            totalRow.add(pw.Text(totalTons[len]!.toStringAsFixed(2)));
            totalRow.add(pw.Text(totalPcs[len].toString()));
          }
          totalRow.add(pw.Text(grandTotal.toStringAsFixed(2)));

          return [
            pw.Text('Delivery Order', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Client: $clientName'),
            pw.Text('Address: $address'),
            pw.Text('Date: $date'),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey),
              children: [
                pw.TableRow(children: headerRow1.map((w) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: w)).toList()),
                pw.TableRow(children: headerRow2.map((w) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: w)).toList()),
                ...dataRows,
                pw.TableRow(children: totalRow.map((w) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: w)).toList()),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text('Payment Date: $paymentDate'),
            pw.Text('Payment Amount: $paymentAmount'),
            pw.Text('Outstanding: $outstanding'),
            pw.SizedBox(height: 8),
            pw.Text('Grand Total: ${grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ];
        },
      ),
    );


    // Save to public Downloads folder
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download'); // Android Downloads path
    } else {
      downloadsDir = await getApplicationDocumentsDirectory(); // iOS fallback
    }

    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final filePath = '${downloadsDir.path}/delivery_order_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }
}
