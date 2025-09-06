import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PDFGeneratorService {
  static Future<void> generateDeliveryOrderPDF({
    required String date,
    required String customerName,
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

      // Find all unique lengths used in all items for table header
      final Set<int> allLengths = {};
      for (var item in items) {
        allLengths.addAll(item.lengthPcs.keys);
      }
      final sortedLengths = allLengths.toList()..sort();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'Delivery Orders',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Customer Info
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date: $date', style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 5),
                    pw.Text('Customer Name: $customerName', style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 5),
                    pw.Text('Address: $address', style: pw.TextStyle(fontSize: 14)),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3), // Particular + width
                    // Add dynamic columns for lengths
                    for (int i = 0; i < sortedLengths.length; i++) i + 1: pw.FlexColumnWidth(1),
                    sortedLengths.length + 1: pw.FlexColumnWidth(1.2), // total P.Ton
                    sortedLengths.length + 2: pw.FlexColumnWidth(1.2), // total W.Ton
                    sortedLengths.length + 3: pw.FlexColumnWidth(1.5), // Price
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildTableCell('Particulars\n(Colour) Width mm', isHeader: true),
                        ...sortedLengths.map((len) => _buildTableCell("${len}'", isHeader: true)),
                        _buildTableCell('Total\nP.Ton', isHeader: true),
                        _buildTableCell('Total\nW.Ton', isHeader: true),
                        _buildTableCell('Price/\nPcs Ton', isHeader: true),
                      ],
                    ),

                    // Second header row for P.Ton
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildTableCell('', isHeader: true),
                        ...sortedLengths.map((len) => _buildTableCell('Pcs', isHeader: true, fontSize: 8)),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell('', isHeader: true),
                      ],
                    ),

                    // Data rows
                    ...items.map((item) {
                      List<pw.Widget> cells = [
                        _buildTableCell('${item.particular} ${item.width}'),
                      ];

                      // Fill dynamic lengths
                      for (var len in sortedLengths) {
                        if (item.lengthPcs.containsKey(len)) {
                          cells.add(_buildTableCell(item.lengthPcs[len].toString()));
                        } else {
                          cells.add(_buildTableCell('-'));
                        }
                      }

                      // Add totals
                      cells.add(_buildTableCell(item.totalPTon));
                      cells.add(_buildTableCell(item.totalWTon));
                      cells.add(_buildTableCell('${item.pricePerTon}/-'));

                      return pw.TableRow(children: cells);
                    }).toList(),

                    // Total P.Ton row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildTableCell('Total', isHeader: true),
                        ...sortedLengths.map((len) {
                          // Sum PCS for this length across all items
                          int totalPcs = 0;
                          for (var item in items) {
                            totalPcs += item.lengthPcs[len] ?? 0;
                          }
                          return _buildTableCell(totalPcs > 0 ? totalPcs.toString() : '-', isHeader: true);
                        }),
                        _buildTableCell(_calculateTotalPTon(items), isHeader: true),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell('', isHeader: true),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Payment Section
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Payment $paymentDate - PBL - $paymentAmount/-', style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 5),
                    pw.Text('Outstanding: $outstanding/-', style: pw.TextStyle(fontSize: 14, font: font)),
                    pw.SizedBox(height: 5),
                    pw.Text('Total Bill: $totalBill/-', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text('বি:দ্র - মাল তোলার সময় ডেলিভারি পেপার নিয়ে আসবেন (গ্যারান্টি মাল নয়)', style: pw.TextStyle(fontSize: 12, font: font)),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Save PDF to Downloads
      final filePath = await _savePDFToDownloads(pdf, fileName);
      print('PDF saved to Downloads: $filePath');

    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, double fontSize = 10}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? fontSize : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static String _calculateTotalPTon(List<OrderItem> items) {
    double total = 0.0;
    for (var item in items) {
      total += double.tryParse(item.totalPTon) ?? 0.0;
    }
    return total.toStringAsFixed(3);
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

    // Now downloadsDirectory is guaranteed to be non-null
    final file = File('${downloadsDirectory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}


class OrderItem {
  String particular;
  String width;
  Map<int, int> lengthPcs; // length in ft -> PCS
  String totalPTon;
  String totalWTon;
  String pricePerTon;

  OrderItem({
    required this.particular,
    required this.width,
    required this.lengthPcs,
    required this.totalPTon,
    required this.totalWTon,
    required this.pricePerTon,
  });

  double get itemTotal {
    final tons = double.tryParse(totalPTon) ?? 0.0;
    final rate = double.tryParse(pricePerTon) ?? 0.0;
    return tons * rate;
  }
}
