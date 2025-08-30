// Screens/dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import '../widgets.dart';
import '../Services/pdf_generator.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final _formKey = GlobalKey<FormState>();
  List<OrderItem> _orderItems = [];

  final TextEditingController _slNoController = TextEditingController();
  final TextEditingController _supplierPartyController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _thicknessController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _pcsController = TextEditingController();
  final TextEditingController _tnController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _paymentDateController = TextEditingController();
  final TextEditingController _paymentAmountController = TextEditingController();
  final TextEditingController _outstandingController = TextEditingController();
  final TextEditingController _totalBillController = TextEditingController();

  String? _selectedColor;
  String? _selectedType;

  final List<String> _colors = ['CNG','BLUE','RED','PARROT','M-GREEN','WHITE','GREEN','SILVER'];
  final List<String> _types = ['CHERRY','CHERRY 10/11','CHERRY 11/12','BORO','BORO 10/11','BORO 11/12','PROFILE','INDSL. PROFILE','GP SHEET','B. TALLY','TUA','BABY COIL','COIL'];

  bool _isUpdating = false;
  bool _lastEditedTn = false; // track last edit source

  @override
  void initState() {
    super.initState();

    // any change in pcs
    _pcsController.addListener(() {
      if (!_isUpdating) {
        _lastEditedTn = false;
        _recalculate();
      }
    });

    // any change in tn
    _tnController.addListener(() {
      if (!_isUpdating) {
        _lastEditedTn = true;
        _recalculate();
      }
    });

    // any change in thickness or length triggers recalculation
    _thicknessController.addListener(() {
      if (!_isUpdating) _recalculate();
    });
    _lengthController.addListener(() {
      if (!_isUpdating) _recalculate();
    });
  }

  void _recalculate() {
    _isUpdating = true;

    final thickness = double.tryParse(_thicknessController.text) ?? 0;
    final length = double.tryParse(_lengthController.text) ?? 0;
    if (thickness == 0 || length == 0) {
      _isUpdating = false;
      return;
    }

    int pcsPerTon = _getPcsPerTon(thickness, length);
    if (pcsPerTon == 0) {
      _isUpdating = false;
      return;
    }

    if (_lastEditedTn) {
      final tn = double.tryParse(_tnController.text) ?? 0.0;
      final pcs = (tn * pcsPerTon).round();
      if (_pcsController.text != pcs.toString()) {
        _pcsController.text = pcs.toString();
      }
    } else {
      final pcs = int.tryParse(_pcsController.text) ?? 0;
      final tn = pcs / pcsPerTon;
      final tnStr = tn.toStringAsFixed(3);
      if (_tnController.text != tnStr) {
        _tnController.text = tnStr;
      }
    }

    _isUpdating = false;
  }

  int _getPcsPerTon(double thickness, double length) {
    if (thickness >= 130 && thickness <= 260) {
      if (length == 6) return 282;
      if (length == 7) return 241;
      if (length == 8) return 211;
      if (length == 9) return 188;
      if (length == 10) return 169;
    } else if (thickness >= 320 && thickness <= 360) {
      if (length == 6) return 224;
      if (length == 7) return 192;
      if (length == 8) return 168;
      if (length == 9) return 149;
      if (length == 10) return 134;
    } else if (thickness >= 420 && thickness <= 510) {
      if (length == 6) return 175;
      if (length == 7) return 150;
      if (length == 8) return 131;
      if (length == 9) return 117;
      if (length == 10) return 105;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFCDF5FD),
        automaticallyImplyLeading: false,
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 40, margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(8)),
                child: Image.asset('assets/images/logo.png',fit: BoxFit.contain),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('আলিফ স্টিল মিলস লিঃ', style: TextStyle(color: Color(0xFF3A0050), fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('ALIF STEEL MILLS LTD.', style: TextStyle(color: Color(0xFF156132), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'logout') {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout), Text(' Logout')]))
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                buildTextField(controller: _slNoController,label: 'SL. NO',keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                buildTextField(controller: _supplierPartyController,label: 'Enter Party Name'),
                const SizedBox(height: 16),
                buildTextField(controller: _addressController,label: 'Enter Address',maxLines: 2),
                const SizedBox(height: 16),
                buildTextField(controller: _phoneController,label: 'Phone Number (optional)',keyboardType: TextInputType.phone),
                const SizedBox(height: 50),
                buildTextField(controller: _thicknessController,label: 'Thickness (mm)',keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 16),
                buildDropdown(label: 'Color', value: _selectedColor, items: _colors,onChanged: (value){ setState((){_selectedColor = value;});}),
                const SizedBox(height: 16),
                buildTextField(controller: _widthController,label: 'Width (inch)',keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 16),
                buildDropdown(label: 'P. Type', value: _selectedType, items: _types,onChanged: (value){ setState((){_selectedType = value;});}),
                const SizedBox(height: 16),
                buildTextField(controller: _lengthController,label: 'Length (ft)',keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 16),
                buildTextField(controller: _pcsController,label: 'PCS',keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 16),
                buildTextField(controller: _tnController,label: 'PCS TN',keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 16),
                buildTextField(controller: _rateController,label: 'Rate (TK)',keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 16),
                buildTextField(controller: _discountController,label: 'Discount',keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _generatePDF,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Submit',style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _generatePDF,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Print',style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addAnotherOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Add Another Order',style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addAnotherOrder() {
    if (_formKey.currentState!.validate()) {
      final item = OrderItem(
        particular: _selectedType ?? 'N/A',
        width: _widthController.text,
        col6: '-',
        col7: '-',
        col8: '-',
        col9: '-',
        col10: '-',
        totalPTon: _tnController.text,
        totalWTon: '-',
        pricePerTon: _rateController.text,
      );

      setState(() {
        _orderItems.add(item);
        _thicknessController.clear();
        _widthController.clear();
        _lengthController.clear();
        _pcsController.clear();
        _tnController.clear();
        _rateController.clear();
        _discountController.clear();
        _selectedColor = null;
        _selectedType = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Item added. Fill next order.'), backgroundColor: Colors.orange[700]),
      );
    }
  }

  void _generatePDF() async {
    if (_formKey.currentState!.validate()) {
      try {
        final item = OrderItem(
          particular: _selectedType ?? 'N/A',
          width: _widthController.text,
          col6: '-',
          col7: '-',
          col8: '-',
          col9: '-',
          col10: '-',
          totalPTon: _tnController.text,
          totalWTon: '-',
          pricePerTon: _rateController.text,
        );

        final itemsForPDF = List<OrderItem>.from(_orderItems)..add(item);

        double totalBill = 0.0;
        for (var orderItem in itemsForPDF) {
          final tons = double.tryParse(orderItem.totalPTon) ?? 0.0;
          final rate = double.tryParse(orderItem.pricePerTon) ?? 0.0;
          totalBill += tons * rate;
        }

        await PDFGeneratorService.generateDeliveryOrderPDF(
          date: DateTime.now().toString().split(' ')[0],
          customerName: _supplierPartyController.text,
          address: _addressController.text,
          items: itemsForPDF,
          paymentDate: DateTime.now().toString().split(' ')[0],
          paymentAmount: '0',
          outstanding: totalBill.toStringAsFixed(2),
          totalBill: totalBill.toStringAsFixed(2),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to Downloads folder! (${itemsForPDF.length} items)'),
            backgroundColor: Colors.green[700],
          ),
        );

        setState(() {
          _orderItems.clear();
          _thicknessController.clear();
          _widthController.clear();
          _lengthController.clear();
          _pcsController.clear();
          _tnController.clear();
          _rateController.clear();
          _discountController.clear();
          _selectedColor = null;
          _selectedType = null;
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red[700]),
        );
      }
    }
  }

  @override
  void dispose() {
    _thicknessController.dispose();
    _widthController.dispose();
    _lengthController.dispose();
    _pcsController.dispose();
    _tnController.dispose();
    _rateController.dispose();
    _discountController.dispose();
    _supplierPartyController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
