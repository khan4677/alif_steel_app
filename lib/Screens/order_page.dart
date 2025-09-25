import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import '../Services/pdf_generator.dart';
import 'order_details_page.dart';

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
          if (snapshot.hasError) return const Center(child: Text("Error loading orders"));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final orders = snapshot.data!.docs;
          if (orders.isEmpty) return const Center(child: Text("No orders yet"));

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;

              final clientName = data['client_name']?.toString() ?? 'N/A';
              final dateStr = data['date']?.toString() ?? '-';
              final totalBill = data['total_amount']?.toString() ?? '0';
              final address = data['address']?.toString() ?? '-';
              final paymentDate = data['payment_date']?.toString() ?? '';
              final paymentAmount = data['payment_amount']?.toString() ?? '';
              final outstanding = data['outstanding']?.toString() ?? '';

              final rows = data['rows'] as List<dynamic>? ?? [];

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Client: $clientName", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text("Date: $dateStr | Total: $totalBill"),
                      const SizedBox(height: 12),

                      // ===== PCS / Length Display =====
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: rows.map((row) {
                          final rowMap = Map<String, dynamic>.from(row);
                          final lengths = (rowMap['lengths'] as Map? ?? {}).map((k, v) => MapEntry(
                            k.toString(),
                            Map<String, String>.from(v as Map),
                          ));

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${rowMap['pType'] ?? '-'} (${rowMap['color'] ?? '-'})",
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    Text("Thickness: ${rowMap['thickness'] ?? '-'} mm"),
                                    const SizedBox(width: 12),
                                    Text("Width: ${rowMap['width'] ?? '-'} inch"),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: lengths.entries.map((entry) {
                                    final length = entry.key;
                                    final pcs = entry.value['pcs'] ?? '0';
                                    final ton = entry.value['ton'] ?? '0';
                                    return Text("Length: $length ft → PCS: $pcs, Ton: $ton");
                                  }).toList(),
                                ),
                                Text("Total PCS: ${rowMap['totalPcs'] ?? '0'}"),
                                Text("Total Ton: ${rowMap['totalPTon'] ?? '0'}"),
                                Text("Amount: ${rowMap['amount'] ?? '0'} tk"),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

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
                                  builder: (_) =>
                                      OrderDetailsPage(orderData: data, orderId: orderId),
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

                                final orderItems = rows.map((row) {
                                  final rowMap = Map<String, dynamic>.from(row);

                                  Map<String, Map<String, String>> lengthsMap = {};
                                  if (rowMap['lengths'] != null) {
                                    (rowMap['lengths'] as Map).forEach((k, v) {
                                      lengthsMap[k.toString()] = Map<String, String>.from(v as Map);
                                    });
                                  }

                                  return OrderItem(
                                    color: rowMap['color']?.toString() ?? '-',
                                    pType: rowMap['pType']?.toString() ?? 'N/A',
                                    thickness: rowMap['thickness']?.toString() ?? '0',
                                    width: rowMap['width']?.toString() ?? '-',
                                    lengths: lengthsMap,
                                    totalPTon: rowMap['totalPTon']?.toString() ?? '0',
                                    totalPcs: rowMap['totalPcs']?.toString() ?? '0',
                                    amount: rowMap['amount']?.toString() ?? '0',
                                  );
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
                                  const SnackBar(content: Text('PDF generated successfully')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error generating PDF: $e')),
                                );
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
