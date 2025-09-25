// lib/models/order.dart

class OrderItem {
  final String color;       // split from "particular"
  final String pType;       // split from "particular"
  final String width;
  final String thickness;

  // Dynamic lengths: { "6": {"ton": "1", "pcs": "282"}, "7": {"ton": "1", "pcs": "241"} }
  Map<String, Map<String, String>> lengths;

  String totalPTon;
  String totalPcs;
  String amount;  // replaces totalWTon

  OrderItem({
    required this.color,
    required this.pType,
    required this.width,
    required this.thickness,
    required this.lengths,
    required this.totalPTon,
    required this.totalPcs,
    required this.amount,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    // Prepare lengths map
    final Map<String, Map<String, String>> lengthsMap = {};

    // 1️⃣ New format: 'lengths' exists
    if (map['lengths'] != null && map['lengths'] is Map) {
      (map['lengths'] as Map).forEach((key, value) {
        if (value is Map) {
          lengthsMap[key.toString()] = Map<String, String>.from(value);
        }
      });
    }
    // 2️⃣ Old format: 'lengthValue' + 'lengthPcs'
    else if (map['lengthValue'] != null && map['lengthPcs'] != null) {
      final lengthVal = map['lengthValue'].toString();
      final pcs = map['lengthPcs'];
      if (pcs is Map) {
        lengthsMap[lengthVal] = pcs.map((k, v) => MapEntry(k.toString(), v.toString()));
      } else if (pcs is String || pcs is int || pcs is double) {
        // Single PCS value
        lengthsMap[lengthVal] = {
          'pcs': pcs.toString(),
          'ton': map['totalPTon']?.toString() ?? '0',
        };
      }
    }

    return OrderItem(
      color: map['color'] ?? 'N/A',
      pType: map['pType'] ?? map['particular'] ?? 'N/A',
      width: map['width'] ?? '-',
      thickness: map['thickness'] ?? '0',
      lengths: lengthsMap,
      totalPTon: map['totalPTon'] ?? '0',
      totalPcs: map['totalPcs'] ??
          lengthsMap.values.map((v) => int.tryParse(v['pcs'] ?? '0') ?? 0).fold(0, (a, b) => a + b).toString(),
      amount: map['amount'] ?? map['totalWTon'] ?? '0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'pType': pType,
      'width': width,
      'thickness': thickness,
      'lengths': lengths,
      'totalPTon': totalPTon,
      'totalPcs': totalPcs,
      'amount': amount,
    };
  }
}

class Order {
  String id;
  String clientName;
  String address;
  String phone;
  String date;
  String paymentDate;
  String paymentAmount;
  String outstanding;
  String totalBill;
  List<OrderItem> items;

  Order({
    required this.id,
    required this.clientName,
    required this.address,
    required this.phone,
    required this.date,
    required this.paymentDate,
    required this.paymentAmount,
    required this.outstanding,
    required this.totalBill,
    required this.items,
  });

  Map<String, dynamic> toMap() => {
    'client_name': clientName,
    'address': address,
    'phone': phone,
    'date': date,
    'paymentDate': paymentDate,
    'paymentAmount': paymentAmount,
    'outstanding': outstanding,
    'totalBill': totalBill,
    'items': items.map((x) => x.toMap()).toList(),
  };

  factory Order.fromMap(String id, Map<String, dynamic> map) => Order(
    id: id,
    clientName: map['client_name'] ?? '',
    address: map['address'] ?? '',
    phone: map['phone'] ?? '',
    date: map['date'] ?? '',
    paymentDate: map['paymentDate'] ?? '',
    paymentAmount: map['paymentAmount'] ?? '',
    outstanding: map['outstanding'] ?? '',
    totalBill: map['totalBill'] ?? '',
    items: (map['items'] as List<dynamic>? ?? [])
        .map((x) => OrderItem.fromMap(Map<String, dynamic>.from(x)))
        .toList(),
  );
}
