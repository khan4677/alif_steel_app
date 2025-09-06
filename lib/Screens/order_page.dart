import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/pdf_generator.dart';

class DeliveryFormPage extends StatefulWidget {
  @override
  _DeliveryFormPageState createState() => _DeliveryFormPageState();
}

class _DeliveryFormPageState extends State<DeliveryFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController dateController = TextEditingController();
  final TextEditingController partyNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController paymentDateController = TextEditingController();
  final TextEditingController paymentAmountController = TextEditingController();
  final TextEditingController outstandingController = TextEditingController();
  final TextEditingController totalBillController = TextEditingController();

  List<OrderItem> items = [];
  List<int> lengths = [6, 7, 8, 9, 10]; // default lengths in feet

  @override
  void initState() {
    super.initState();
    dateController.text = DateTime.now().toString().split(' ')[0];
    paymentDateController.text = DateTime.now().toString().split(' ')[0];
    addNewItem();
  }

  @override
  void dispose() {
    dateController.dispose();
    partyNameController.dispose();
    addressController.dispose();
    paymentDateController.dispose();
    paymentAmountController.dispose();
    outstandingController.dispose();
    totalBillController.dispose();
    super.dispose();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void addNewItem() {
    setState(() {
      Map<int, int> lengthPcs = {for (var len in lengths) len: 0};
      items.add(OrderItem(
        particular: '',
        width: '',
        lengthPcs: lengthPcs,
        totalPTon: '',
        totalWTon: '-',
        pricePerTon: '',
      ));
    });
  }

  void removeItem(int index) {
    if (items.length > 1) {
      setState(() => items.removeAt(index));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('At least one item is required'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void calculateTotals() {
    double total = 0.0;
    for (var item in items) {
      final tons = double.tryParse(item.totalPTon) ?? 0.0;
      final rate = double.tryParse(item.pricePerTon) ?? 0.0;
      total += tons * rate;
    }

    setState(() {
      totalBillController.text = total.toStringAsFixed(2);
      if (outstandingController.text.isEmpty) {
        outstandingController.text = total.toStringAsFixed(2);
      }
    });
  }

  void generatePDF() async {
    if (!_formKey.currentState!.validate()) return;

    bool hasValidItem = items.any((item) =>
    item.particular.isNotEmpty &&
        item.totalPTon.isNotEmpty &&
        item.pricePerTon.isNotEmpty);

    if (!hasValidItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one complete item'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      calculateTotals();

      await PDFGeneratorService.generateDeliveryOrderPDF(
        date: dateController.text,
        customerName: partyNameController.text,
        address: addressController.text,
        items: items.where((item) => item.particular.isNotEmpty).toList(),
        paymentDate: paymentDateController.text,
        paymentAmount: paymentAmountController.text.isEmpty ? '0' : paymentAmountController.text,
        outstanding: outstandingController.text,
        totalBill: totalBillController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to Downloads folder!'), backgroundColor: Colors.green, duration: Duration(seconds: 3)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget buildTextField(String label, TextEditingController controller, {bool required = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: required ? (val) => val == null || val.isEmpty ? '$label is required' : null : null,
    );
  }

  Widget buildItemForm(int index) {
    final item = items[index];

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Item ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[700])),
                if (items.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => removeItem(index),
                  ),
              ],
            ),
            SizedBox(height: 12),
            // Particular & Width
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Particulars*', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                    initialValue: item.particular,
                    onChanged: (val) => setState(() => item.particular = val),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Width*', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                    initialValue: item.width,
                    onChanged: (val) => setState(() => item.width = val),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Length PCS inputs dynamically
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lengths.map((len) {
                return SizedBox(
                  width: 60,
                  child: TextFormField(
                    decoration: InputDecoration(labelText: "$len'", border: OutlineInputBorder(), contentPadding: EdgeInsets.all(6)),
                    initialValue: item.lengthPcs[len].toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() => item.lengthPcs[len] = int.tryParse(val) ?? 0);
                    },
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 8),
            // Totals & Price
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Total P.Ton*', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                    initialValue: item.totalPTon,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      setState(() => item.totalPTon = val);
                      calculateTotals();
                    },
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Total W.Ton', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                    initialValue: item.totalWTon,
                    onChanged: (val) => setState(() => item.totalWTon = val.isEmpty ? '-' : val),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Price/Ton*', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                    initialValue: item.pricePerTon,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      setState(() => item.pricePerTon = val);
                      calculateTotals();
                    },
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            if (item.totalPTon.isNotEmpty && item.pricePerTon.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Item Total: ${item.itemTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Order Form'),
        backgroundColor: Colors.blue[600],
        actions: [IconButton(icon: Icon(Icons.logout), onPressed: _logout)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                      SizedBox(height: 12),
                      buildTextField('Date', dateController),
                      SizedBox(height: 12),
                      buildTextField('Customer Name', partyNameController),
                      SizedBox(height: 12),
                      buildTextField('Address', addressController),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Items Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                  ElevatedButton.icon(onPressed: addNewItem, icon: Icon(Icons.add), label: Text('Add Item'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green)),
                ],
              ),
              SizedBox(height: 8),
              ...List.generate(items.length, buildItemForm),
              SizedBox(height: 16),
              // Payment Info
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                      SizedBox(height: 12),
                      buildTextField('Payment Date', paymentDateController),
                      SizedBox(height: 12),
                      buildTextField('Payment Amount', paymentAmountController, required: false),
                      SizedBox(height: 12),
                      buildTextField('Outstanding', outstandingController),
                      SizedBox(height: 12),
                      buildTextField('Total Bill', totalBillController),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: generatePDF,
                  icon: Icon(Icons.picture_as_pdf, size: 24),
                  label: Text('Generate PDF', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
