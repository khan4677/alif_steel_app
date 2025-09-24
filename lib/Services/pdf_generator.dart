import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/order.dart';

class PDFGeneratorService {
  static Future<void> generateDeliveryOrderPDF({
    required String date,
    required String clientName,
    required String address,
    required List<OrderItem> items,
    required String paymentDate,
    required String paymentAmount,
    required String outstanding,
    required String totalBill,
  }) async {
    try {
      await _requestStoragePermission();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'delivery_order_$timestamp.pdf';
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.notoSansBengaliRegular();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Delivery Orders',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 20),
                // Customer info
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date: $date', style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 5),
                    pw.Text('Customer Name: $clientName', style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 5),
                    pw.Text('Address: $address', style: pw.TextStyle(fontSize: 14)),
                  ],
                ),
                pw.SizedBox(height: 20),
                // Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1.2), // Thickness
                    1: pw.FlexColumnWidth(1.2), // Length
                    2: pw.FlexColumnWidth(3),   // Particular
                    3: pw.FlexColumnWidth(1.2), // Width
                    4: pw.FlexColumnWidth(1),   // PCS
                    5: pw.FlexColumnWidth(1.2), // Tons
                    6: pw.FlexColumnWidth(1.2), // Rate
                    7: pw.FlexColumnWidth(1.5), // Total
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildTableCell('Thickness', isHeader: true),
                        _buildTableCell('Length', isHeader: true),
                        _buildTableCell('Particular', isHeader: true),
                        _buildTableCell('Width', isHeader: true),
                        _buildTableCell('PCS', isHeader: true),
                        _buildTableCell('Tons', isHeader: true),
                        _buildTableCell('Rate', isHeader: true),
                        _buildTableCell('Total', isHeader: true),
                      ],
                    ),
                    // Data rows
                    ...items.map((item) {
                      int pcs = item.lengthPcs.entries.first.value;
                      double tons = double.tryParse(item.totalPTon.toString()) ?? 0.0;
                      double rate = double.tryParse(item.pricePerTon.toString()) ?? 0.0;
                      double rowTotal = tons * rate;

                      return pw.TableRow(
                        children: [
                          _buildTableCell(item.thickness.toString()),
                          _buildTableCell(item.lengthValue.toString()),
                          _buildTableCell(item.particular.toString()),
                          _buildTableCell(item.width.toString()),
                          _buildTableCell(pcs.toString()),
                          _buildTableCell(tons.toStringAsFixed(2)),
                          _buildTableCell(rate.toStringAsFixed(2)),
                          _buildTableCell(rowTotal.toStringAsFixed(2)),
                        ],
                      );
                    }).toList(),
                    // Grand Total row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildTableCell('Grand Total', isHeader: true, fontSize: 12),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell(
                          items.fold<double>(
                              0.0,
                                  (sum, i) =>
                              sum + (double.tryParse(i.totalPTon.toString()) ?? 0)),
                          isHeader: true,
                        ),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell(
                          items
                              .fold<double>(
                            0.0,
                                (sum, i) =>
                            sum +
                                ((double.tryParse(i.totalPTon.toString()) ?? 0) *
                                    (double.tryParse(i.pricePerTon.toString()) ?? 0)),
                          )
                              .toStringAsFixed(2),
                          isHeader: true,
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                // Payment info
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Payment $paymentDate - PBL - ${paymentAmount.toString()}/-',
                        style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 5),
                    pw.Text('Outstanding: ${outstanding.toString()}/-', style: pw.TextStyle(fontSize: 14, font: font)),
                    pw.SizedBox(height: 5),
                    pw.Text('Total Bill: ${totalBill.toString()}/-',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'বি:দ্র - মাল তোলার সময় ডেলিভারি পেপার নিয়ে আসবেন (গ্যারান্টি মাল নয়)',
                      style: pw.TextStyle(fontSize: 12, font: font),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final filePath = await _savePDFToDownloads(pdf, fileName);
      print('PDF saved to Downloads: $filePath');
    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }

  static pw.Widget _buildTableCell(dynamic text, {bool isHeader = false, double fontSize = 10}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text.toString(),
        style: pw.TextStyle(
          fontSize: isHeader ? fontSize : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) return true;
      var status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
      status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  static Future<String> _savePDFToDownloads(pw.Document pdf, String fileName) async {
    final bytes = await pdf.save();
    Directory downloadsDirectory;

    if (Platform.isAndroid) {
      downloadsDirectory = Directory('/storage/emulated/0/Download');
      if (!downloadsDirectory.existsSync()) {
        final externalDir = await getExternalStorageDirectory();
        downloadsDirectory = externalDir != null
            ? Directory('${externalDir.path}/Download')
            : Directory('/storage/emulated/0/Download');
      }
      if (!downloadsDirectory.existsSync()) {
        await downloadsDirectory.create(recursive: true);
      }
    } else if (Platform.isIOS) {
      downloadsDirectory = await getApplicationDocumentsDirectory();
    } else {
      throw Exception('Unsupported platform');
    }

    final file = File('${downloadsDirectory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
