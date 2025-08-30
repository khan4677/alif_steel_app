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

  @override
  void initState() {
    super.initState();
    // Set default date to today
    dateController.text = DateTime.now().toString().split(' ')[0];
    paymentDateController.text = DateTime.now().toString().split(' ')[0];
    addNewItem(); // At least one item
  }

  @override
  void dispose() {
    // Clean up controllers
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
      items.add(OrderItem(
        particular: '',
        width: '',
        col6: '-',
        col7: '-',
        col8: '-',
        col9: '-',
        col10: '-',
        totalPTon: '',
        totalWTon: '-',
        pricePerTon: '',
      ));
    });
  }

  void removeItem(int index) {
    if (items.length > 1) {
      setState(() {
        items.removeAt(index);
      });
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
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that at least one item has data
    bool hasValidItem = items.any((item) =>
    item.particular.isNotEmpty &&
        item.totalPTon.isNotEmpty &&
        item.pricePerTon.isNotEmpty
    );

    if (!hasValidItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one complete item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      calculateTotals(); // Calculate totals before generating PDF

      await PDFGeneratorService.generateDeliveryOrderPDF(
        date: dateController.text,
        customerName: partyNameController.text,
        address: addressController.text,
        items: items.where((item) => item.particular.isNotEmpty).toList(), // Only include items with data
        paymentDate: paymentDateController.text,
        paymentAmount: paymentAmountController.text.isEmpty ? '0' : paymentAmountController.text,
        outstanding: outstandingController.text,
        totalBill: totalBillController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to Downloads folder successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildTextField(String label, TextEditingController controller, {bool required = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: required ? (val) => val == null || val.isEmpty ? '$label is required' : null : null,
    );
  }

  Widget buildItemForm(int index) {
    final item = items[index];

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue[700],
                  ),
                ),
                if (items.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => removeItem(index),
                    tooltip: 'Remove Item',
                  ),
              ],
            ),
            SizedBox(height: 12),

            // Particulars and Width
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Particulars*',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    initialValue: item.particular,
                    onChanged: (val) {
                      setState(() {
                        item.particular = val;
                      });
                    },
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Width*',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    initialValue: item.width,
                    onChanged: (val) {
                      setState(() {
                        item.width = val;
                      });
                    },
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Length columns (6', 7', 8', 9', 10')
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: '6\'',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    initialValue: item.col6,
                    onChanged: (val) {
                      setState(() {
                        item.col6 = val.isEmpty ? '-' : val;
                      });
                    },
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: '7\'',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    initialValue: item.col7,
                    onChanged: (val) {
                      setState(() {
                        item.col7 = val.isEmpty ? '-' : val;
                      });
                    },
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: '8\'',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    initialValue: item.col8,
                    onChanged: (val) {
                      setState(() {
                        item.col8 = val.isEmpty ? '-' : val;
                      });
                    },
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: '9\'',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    initialValue: item.col9,
                    onChanged: (val) {
                      setState(() {
                        item.col9 = val.isEmpty ? '-' : val;
                      });
                    },
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: '10\'',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    initialValue: item.col10,
                    onChanged: (val) {
                      setState(() {
                        item.col10 = val.isEmpty ? '-' : val;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Totals and Price
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Total P.Ton*',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    initialValue: item.totalPTon,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      setState(() {
                        item.totalPTon = val;
                      });
                      calculateTotals();
                    },
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Total W.Ton',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    initialValue: item.totalWTon,
                    onChanged: (val) {
                      setState(() {
                        item.totalWTon = val.isEmpty ? '-' : val;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Price/Ton*',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    initialValue: item.pricePerTon,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      setState(() {
                        item.pricePerTon = val;
                      });
                      calculateTotals();
                    },
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),

            // Show calculated amount for this item
            if (item.totalPTon.isNotEmpty && item.pricePerTon.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Item Total: ${item.itemTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
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
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Information
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
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

              // Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: addNewItem,
                    icon: Icon(Icons.add),
                    label: Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Dynamic Items List
              ...List.generate(items.length, buildItemForm),

              SizedBox(height: 16),

              // Payment Information
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
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

              // Generate PDF Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: generatePDF,
                  icon: Icon(Icons.picture_as_pdf, size: 24),
                  label: Text(
                    'Generate PDF',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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