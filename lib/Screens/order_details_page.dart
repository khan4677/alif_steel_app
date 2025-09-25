import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderData, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final rows = orderData['rows'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Client: ${orderData['client_name'] ?? 'N/A'}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text("Date: ${orderData['date'] ?? '-'}"),
            const SizedBox(height: 16),

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
                  padding: const EdgeInsets.symmetric(vertical: 6),
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
          ],
        ),
      ),
    );
  }
}
