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
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date: $date', style: pw.TextStyle(fontSize: 12)),
                        pw.SizedBox(height: 10),
                        pw.Text('Customer Name:', style: pw.TextStyle(fontSize: 12)),
                        pw.Text(customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 10),
                        pw.Text('Address: $address', style: pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Table with proper structure
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                  columnWidths: {
                    0: pw.FlexColumnWidth(2.5),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(1),
                    3: pw.FlexColumnWidth(1),
                    4: pw.FlexColumnWidth(1),
                    5: pw.FlexColumnWidth(1),
                    6: pw.FlexColumnWidth(1.2),
                    7: pw.FlexColumnWidth(1.2),
                    8: pw.FlexColumnWidth(1.2),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
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
                    // Data rows
                    ...items.map((item) => pw.TableRow(
                      children: [
                        _buildTableCell('${item.particular} ${item.width}\"'),
                        _buildTableCell(item.col6),
                        _buildTableCell(item.col7),
                        _buildTableCell(item.col8),
                        _buildTableCell(item.col9),
                        _buildTableCell(item.col10),
                        _buildTableCell(item.totalPTon),
                        _buildTableCell(item.totalWTon),
                        _buildTableCell(item.pricePerTon),
                      ],
                    )).toList(),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Payment Section
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Payment $paymentDate - PBL - $paymentAmount',
                        style: pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 5),
                    pw.Text('Outstanding', style: pw.TextStyle(fontSize: 12)),
                    pw.Text('জমা আছে - $outstanding',
                        style: pw.TextStyle(fontSize: 12, font: font)),
                    pw.SizedBox(height: 5),
                    pw.Text('Total Bill - $totalBill',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text('বি:দ্র - মাল তোলার সময় ডেলিভারি পেপার নিয়ে আসবেন (গ্যারান্টি মাল নয়)',
                        style: pw.TextStyle(fontSize: 10, font: font)),
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

    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
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
  String particular;    // Removed 'final'
  String width;         // Removed 'final'
  String col6;          // Removed 'final'
  String col7;          // Removed 'final'
  String col8;          // Removed 'final'
  String col9;          // Removed 'final'
  String col10;         // Removed 'final'
  String totalPTon;     // Removed 'final'
  String totalWTon;     // Removed 'final'
  String pricePerTon;   // Removed 'final'

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