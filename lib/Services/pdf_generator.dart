import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
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

      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'delivery_order_$timestamp.pdf';

      final pdf = pw.Document();
      final font = await PdfGoogleFonts.notoSansBengaliRegular();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Delivery Orders',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Date and Customer Info
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date- $date', style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 8),
                    pw.Text('Customer Name- $customerName', style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 8),
                    pw.Text('Address-$address', style: pw.TextStyle(fontSize: 14)),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Table with proper structure matching the PDF format
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(1),
                    3: pw.FlexColumnWidth(1),
                    4: pw.FlexColumnWidth(1),
                    5: pw.FlexColumnWidth(1),
                    6: pw.FlexColumnWidth(1),
                    7: pw.FlexColumnWidth(1),
                    8: pw.FlexColumnWidth(1.2),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildTableCell('Particulars\n(Colour) Width mm', isHeader: true),
                        _buildTableCell('6\'', isHeader: true),
                        _buildTableCell('7\'', isHeader: true),
                        _buildTableCell('8\'', isHeader: true),
                        _buildTableCell('9\'', isHeader: true),
                        _buildTableCell('10\'', isHeader: true),
                        _buildTableCell('Total\nP.Ton', isHeader: true),
                        _buildTableCell('Total\nW.Ton', isHeader: true),
                        _buildTableCell('Price/\nPcs Ton', isHeader: true),
                      ],
                    ),

                    // Second header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildTableCell('', isHeader: true),
                        _buildTableCell('P.Ton', isHeader: true, fontSize: 8),
                        _buildTableCell('P.Ton', isHeader: true, fontSize: 8),
                        _buildTableCell('P.Ton', isHeader: true, fontSize: 8),
                        _buildTableCell('P.Ton', isHeader: true, fontSize: 8),
                        _buildTableCell('P.Tom', isHeader: true, fontSize: 8),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell('', isHeader: true),
                      ],
                    ),

                    // Data rows
                    ...items.map((item) => pw.TableRow(
                      children: [
                        _buildTableCell('${item.particular} ${item.width}'),
                        _buildTableCell(item.col6),
                        _buildTableCell(item.col7),
                        _buildTableCell(item.col8),
                        _buildTableCell(item.col9),
                        _buildTableCell(item.col10),
                        _buildTableCell(item.totalPTon),
                        _buildTableCell(item.totalWTon),
                        _buildTableCell('${item.pricePerTon}/-'),
                      ],
                    )).toList(),

                    // Total row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildTableCell('Total-', isHeader: true),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell('', isHeader: true),
                        _buildTableCell('', isHeader: true),
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
                    pw.Text('Payment $paymentDate-PBL-$paymentAmount/-',
                        style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 5),
                    pw.Text('OutStanding', style: pw.TextStyle(fontSize: 14)),
                    pw.Text('জমা আছে -$outstanding/-',
                        style: pw.TextStyle(fontSize: 14, font: font)),
                    pw.SizedBox(height: 5),
                    pw.Text('Total Bill-$totalBill/-',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text('বি:দ্র - মাল তোলার সময় ডেলিভারি পেপার নিয়ে আসবেন (গ্যারান্টি মাল নয়)',
                        style: pw.TextStyle(fontSize: 12, font: font)),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Save to Downloads folder
      final filePath = await _savePDFToDownloads(pdf, fileName);

      print('PDF saved to Downloads: $filePath');

      // Print PDF content after generation
      _printPDFContent(date, customerName, address, items, paymentDate, paymentAmount, outstanding, totalBill);

    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }

  static String _calculateTotalPTon(List<OrderItem> items) {
    double total = 0.0;
    for (var item in items) {
      total += double.tryParse(item.totalPTon) ?? 0.0;
    }
    return total.toStringAsFixed(3);
  }

  static void _printPDFContent(String date, String customerName, String address, List<OrderItem> items, String paymentDate, String paymentAmount, String outstanding, String totalBill) {
    print('\n=== PDF CONTENT ===');
    print('Date: $date');
    print('Customer Name: $customerName');
    print('Address: $address');
    print('\nItems:');
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      print('${i + 1}. ${item.particular} ${item.width} - P.Ton: ${item.totalPTon}, Price: ${item.pricePerTon}/-');
    }
    print('\nPayment Date: $paymentDate');
    print('Payment Amount: $paymentAmount/-');
    print('Outstanding: $outstanding/-');
    print('Total Bill: $totalBill/-');
    print('==================\n');
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, double fontSize = 10}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(4),
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

  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 11+ (API level 30+)
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      var status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      }

      // Fallback to storage permission for older Android versions
      status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // iOS doesn't need explicit permission for app documents
  }

  static Future<String> _savePDFToDownloads(pw.Document pdf, String fileName) async {
    try {
      final bytes = await pdf.save();

      // Get Downloads directory
      Directory? downloadsDirectory;

      if (Platform.isAndroid) {
        // For Android, use the public Downloads folder
        downloadsDirectory = Directory('/storage/emulated/0/Download');

        // If that doesn't exist, try alternative paths
        if (!downloadsDirectory.existsSync()) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            downloadsDirectory = Directory('${externalDir.path}/Download');
          }
        }

        // Last fallback - create Downloads folder in external storage
        if (!downloadsDirectory.existsSync()) {
          await downloadsDirectory.create(recursive: true);
        }
      } else if (Platform.isIOS) {
        // For iOS, use documents directory (Files app accessible)
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      if (downloadsDirectory == null) {
        throw Exception('Could not access Downloads directory');
      }

      // Create the file
      final file = File('${downloadsDirectory.path}/$fileName');
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      print('Error saving PDF to Downloads: $e');
      rethrow;
    }
  }
}

class OrderItem {
  String particular;
  String width;
  String col6;
  String col7;
  String col8;
  String col9;
  String col10;
  String totalPTon;
  String totalWTon;
  String pricePerTon;

  OrderItem({
    required this.particular,
    required this.width,
    required this.col6,
    required this.col7,
    required this.col8,
    required this.col9,
    required this.col10,
    required this.totalPTon,
    required this.totalWTon,
    required this.pricePerTon,
  });

  // Add a method to calculate item total
  double get itemTotal {
    try {
      final tons = double.tryParse(totalPTon) ?? 0.0;
      final rate = double.tryParse(pricePerTon) ?? 0.0;
      return tons * rate;
    } catch (e) {
      return 0.0;
    }
  }
}