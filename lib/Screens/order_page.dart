// Screens/order_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as models;
import '../Services/pdf_generator.dart'; // make sure this path is correct

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orders")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading orders"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text("No orders yet"));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;

              // Safe string conversion
              final slNo = data['sl_no']?.toString() ?? orderId;
              final clientName = data['client_name']?.toString() ?? 'N/A';
              final dateStr = data['date']?.toString() ?? '-';
              final address = data['address']?.toString() ?? '-';
              final paymentDate = data['payment_date']?.toString() ?? '';
              final paymentAmount = data['payment_amount']?.toString() ?? '';
              final outstanding = data['outstanding']?.toString() ?? '';
              final totalBill = data['total_amount']?.toString() ?? '0';

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SL.No: $slNo", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text("Client Name: $clientName"),
                      const SizedBox(height: 6),
                      Text("Date: $dateStr"),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Open Button
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailsPage(
                                    orderData: data,
                                    orderId: orderId,
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.blue),
                            child: const Text("Open"),
                          ),
                          // Download Button
                          TextButton(
                            onPressed: () async {
                              try {
                                final rows = data['rows'] as List<dynamic>? ?? [];

                                // Convert rows to OrderItem safely
                                final orderItems = rows.map((row) {
                                  final rowMap = Map<String, dynamic>.from(row);

                                  // Parse lengthPcs as Map<int,int>
                                  final Map<int, int> parseLengthPcs = {};
                                  if (rowMap['lengthPcs'] != null) {
                                    (rowMap['lengthPcs'] as Map).forEach((key, value) {
                                      final intKey = int.tryParse(key.toString()) ?? 0;
                                      final intValue = int.tryParse(value.toString()) ?? 0;
                                      parseLengthPcs[intKey] = intValue;
                                    });
                                  }

                                  return models.OrderItem.fromMap({
                                    ...rowMap,
                                    'lengthPcs': parseLengthPcs,
                                  });
                                }).toList();

                                await PDFGeneratorService.generateDeliveryOrderPDF(
                                  clientName: clientName,
                                  address: address,
                                  date: dateStr,
                                  items: orderItems,
                                  paymentDate: paymentDate,
                                  paymentAmount: paymentAmount,
                                  outstanding: outstanding,
                                  totalBill: totalBill,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('PDF generated successfully')));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error generating PDF: $e')));
                              }
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.black),
                            child: const Text("Download"),
                          ),


                          // Delete Button
                          TextButton(
                            onPressed: () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(orderId)
                                    .delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Order deleted successfully')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error deleting order: $e')),
                                );
                              }
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// New page to show full order details
class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String orderId;
  const OrderDetailsPage({super.key, required this.orderData, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final rows = orderData['rows'] as List<dynamic>? ?? [];
    return Scaffold(
      appBar: AppBar(title: Text("Order Details - $orderId")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Client Name: ${orderData['client_name']?.toString() ?? 'N/A'}"),
            Text("Phone: ${orderData['phone']?.toString() ?? '-'}"),
            Text("Address: ${orderData['address']?.toString() ?? '-'}"),
            Text("Date: ${orderData['date']?.toString() ?? '-'}"),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, index) {
                  final row = Map<String, dynamic>.from(rows[index]);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "${row['particular']?.toString() ?? ''} ${row['width']?.toString() ?? ''} | "
                            "${row['thickness']?.toString() ?? ''} | "
                            "${row['lengthValue']?.toString() ?? ''} | "
                            "PCS: ${row['lengthPcs'] != null ? row['lengthPcs'].values.first.toString() : '-'} | "
                            "Tons: ${row['totalPTon']?.toString() ?? '0'} | "
                            "Rate: ${row['pricePerTon']?.toString() ?? '0'}",
                      ),
                    ),
                  );
                },
              ),
            ),
            Text("Grand Total: ${orderData['total_amount']?.toString() ?? '0'} tk",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
