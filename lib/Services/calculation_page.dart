import 'package:flutter/material.dart';

class CalculationPage extends StatefulWidget {
  @override
  _CalculationPageState createState() => _CalculationPageState();
}

class _CalculationPageState extends State<CalculationPage> {
  final TextEditingController _thicknessController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _pcsController = TextEditingController();
  final TextEditingController _tonController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  String _conversionInfo = '';
  double _convertedLength = 0.0;
  int _pcsPerTon = 0;
  double _totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _pcsController.addListener(_onPcsChanged);
    _tonController.addListener(_onTonChanged);
    _thicknessController.addListener(_updateInfo);
    _lengthController.addListener(_updateInfo);
    _rateController.addListener(_calculateCost);
  }

  // Get converted length (C.L)
  double _getConvertedLength(double thickness, double length) {
    if (thickness >= 130 && thickness <= 260) {
      switch (length.toInt()) {
        case 7: return 7.021;
        case 8: return 8.019;
        case 10: return 10.012;
        default: return length;
      }
    } else if (thickness >= 320 && thickness <= 360) {
      switch (length.toInt()) {
        case 9: return 9.020;
        case 10: return 10.030;
        default: return length;
      }
    } else if (thickness >= 420 && thickness <= 510) {
      switch (length.toInt()) {
        case 8: return 8.020;
        case 9: return 8.970;
        default: return length;
      }
    }
    return length;
  }

  // Get pieces per ton
  int _getPcsPerTon(double thickness, int length) {
    if (thickness >= 130 && thickness <= 260) {
      switch (length) {
        case 6: return 282;
        case 7: return 241;
        case 8: return 211;
        case 9: return 188;
        case 10: return 169;
        default: return 0;
      }
    } else if (thickness >= 320 && thickness <= 360) {
      switch (length) {
        case 6: return 224;
        case 7: return 192;
        case 8: return 168;
        case 9: return 149;
        case 10: return 134;
        default: return 0;
      }
    } else if (thickness >= 420 && thickness <= 510) {
      switch (length) {
        case 6: return 175;
        case 7: return 150;
        case 8: return 131;
        case 9: return 117;
        case 10: return 105;
        default: return 0;
      }
    }
    return 0;
  }

  void _updateInfo() {
    final thickness = double.tryParse(_thicknessController.text);
    final length = double.tryParse(_lengthController.text);

    if (thickness != null && length != null) {
      _convertedLength = _getConvertedLength(thickness, length);
      _pcsPerTon = _getPcsPerTon(thickness, length.toInt());

      setState(() {
        if (_pcsPerTon > 0) {
          _conversionInfo = 'Valid combination\nC.L: ${_convertedLength.toStringAsFixed(3)} ft\n1 Ton = $_pcsPerTon pieces';
        } else {
          _conversionInfo = 'Invalid thickness-length combination';
        }
      });

      // Recalculate if values exist
      if (_pcsController.text.isNotEmpty) {
        _onPcsChanged();
      } else if (_tonController.text.isNotEmpty) {
        _onTonChanged();
      }
    } else {
      setState(() {
        _conversionInfo = '';
      });
    }
  }

  void _onPcsChanged() {
    if (_pcsController.text.isEmpty || _pcsPerTon == 0) return;

    final pcs = int.tryParse(_pcsController.text);
    if (pcs != null) {
      final tons = pcs / _pcsPerTon;
      _tonController.removeListener(_onTonChanged);
      _tonController.text = tons.toStringAsFixed(3);
      _tonController.addListener(_onTonChanged);
      _calculateCost();
    }
  }

  void _onTonChanged() {
    if (_tonController.text.isEmpty || _pcsPerTon == 0) return;

    final tons = double.tryParse(_tonController.text);
    if (tons != null) {
      final pcs = (tons * _pcsPerTon).round();
      _pcsController.removeListener(_onPcsChanged);
      _pcsController.text = pcs.toString();
      _pcsController.addListener(_onPcsChanged);
      _calculateCost();
    }
  }

  void _calculateCost() {
    final tons = double.tryParse(_tonController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    setState(() {
      _totalCost = tons * rate;
    });
  }

  void _clearAll() {
    _thicknessController.clear();
    _lengthController.clear();
    _pcsController.clear();
    _tonController.clear();
    _rateController.clear();
    setState(() {
      _conversionInfo = '';
      _convertedLength = 0.0;
      _pcsPerTon = 0;
      _totalCost = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Steel Calculator'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _clearAll,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Section
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Input Parameters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Thickness
                    TextFormField(
                      controller: _thicknessController,
                      decoration: InputDecoration(
                        labelText: 'Thickness (mm)',
                        border: OutlineInputBorder(),
                        hintText: 'Valid: 130-260, 320-360, 420-510',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 12),

                    // Length
                    TextFormField(
                      controller: _lengthController,
                      decoration: InputDecoration(
                        labelText: 'Length (ft)',
                        border: OutlineInputBorder(),
                        hintText: 'Valid: 6, 7, 8, 9, 10',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Conversion Info
            if (_conversionInfo.isNotEmpty)
              Card(
                elevation: 2,
                color: _pcsPerTon > 0 ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _pcsPerTon > 0 ? Icons.check_circle : Icons.error,
                            color: _pcsPerTon > 0 ? Colors.green[700] : Colors.red[700],
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Conversion Info',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _pcsPerTon > 0 ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _conversionInfo,
                        style: TextStyle(
                          fontSize: 14,
                          color: _pcsPerTon > 0 ? Colors.green[600] : Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 16),

            // Calculation Section
            if (_pcsPerTon > 0)
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PCS ⇄ Tons Calculation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 16),

                      // PCS and Tons
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pcsController,
                              decoration: InputDecoration(
                                labelText: 'Pieces (PCS)',
                                border: OutlineInputBorder(),
                                suffixText: 'pcs',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 16),
                          Icon(Icons.swap_horiz, color: Colors.blue[600]),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _tonController,
                              decoration: InputDecoration(
                                labelText: 'Tons (TN)',
                                border: OutlineInputBorder(),
                                suffixText: 'tons',
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Rate
                      TextFormField(
                        controller: _rateController,
                        decoration: InputDecoration(
                          labelText: 'Rate per Ton (TK)',
                          border: OutlineInputBorder(),
                          prefixText: '৳ ',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 16),

            // Cost Display
            if (_totalCost > 0)
              Card(
                elevation: 2,
                color: Colors.orange[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calculate, color: Colors.orange[700]),
                          SizedBox(width: 8),
                          Text(
                            'Cost Calculation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      Text(
                        '${_tonController.text} tons × ৳${_rateController.text}',
                        style: TextStyle(fontSize: 14, color: Colors.orange[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Total Cost: ৳${_totalCost.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 32),

            // Reference Tables
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Reference',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Thickness ranges
                    _buildReferenceSection(
                      'Thickness 130-260mm',
                      [
                        '6\' → 282 pcs/ton',
                        '7\' → 241 pcs/ton (C.L: 7.021)',
                        '8\' → 211 pcs/ton (C.L: 8.019)',
                        '9\' → 188 pcs/ton',
                        '10\' → 169 pcs/ton (C.L: 10.012)',
                      ],
                    ),

                    _buildReferenceSection(
                      'Thickness 320-360mm',
                      [
                        '6\' → 224 pcs/ton',
                        '7\' → 192 pcs/ton',
                        '8\' → 168 pcs/ton',
                        '9\' → 149 pcs/ton (C.L: 9.020)',
                        '10\' → 134 pcs/ton (C.L: 10.030)',
                      ],
                    ),

                    _buildReferenceSection(
                      'Thickness 420-510mm',
                      [
                        '6\' → 175 pcs/ton',
                        '7\' → 150 pcs/ton',
                        '8\' → 131 pcs/ton (C.L: 8.020)',
                        '9\' → 117 pcs/ton (C.L: 8.970)',
                        '10\' → 105 pcs/ton',
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(left: 12, bottom: 4),
          child: Row(
            children: [
              Icon(Icons.fiber_manual_record, size: 6, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(
                item,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        )).toList(),
        SizedBox(height: 12),
      ],
    );
  }

  @override
  void dispose() {
    _pcsController.removeListener(_onPcsChanged);
    _tonController.removeListener(_onTonChanged);
    _thicknessController.removeListener(_updateInfo);
    _lengthController.removeListener(_updateInfo);
    _rateController.removeListener(_calculateCost);

    _thicknessController.dispose();
    _lengthController.dispose();
    _pcsController.dispose();
    _tonController.dispose();
    _rateController.dispose();
    super.dispose();
  }
}