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

  double _getCL(double thickness, double length) {
    if (thickness >= 130 && thickness <= 260) {
      if (length == 7) return 7.021;
      if (length == 8) return 8.019;
      if (length == 10) return 10.012;
      return length;
    } else if (thickness >= 320 && thickness <= 360) {
      if (length == 9) return 9.020;
      if (length == 10) return 10.030;
      return length;
    } else if (thickness >= 420 && thickness <= 510) {
      if (length == 8) return 8.020;
      if (length == 9) return 8.970;
      return length;
    }
    return length;
  }

  int _getPCSPerTon(double thickness, int length) {
    if (thickness >= 130 && thickness <= 260) {
      switch (length) {
        case 6: return 282;
        case 7: return 241;
        case 8: return 211;
        case 9: return 188;
        case 10: return 169;
      }
    } else if (thickness >= 320 && thickness <= 360) {
      switch (length) {
        case 6: return 224;
        case 7: return 192;
        case 8: return 168;
        case 9: return 149;
        case 10: return 134;
      }
    } else if (thickness >= 420 && thickness <= 510) {
      switch (length) {
        case 6: return 175;
        case 7: return 150;
        case 8: return 131;
        case 9: return 117;
        case 10: return 105;
      }
    }
    return 0;
  }

  void _updateInfo() {
    final thickness = double.tryParse(_thicknessController.text);
    final length = double.tryParse(_lengthController.text);

    if (thickness != null && length != null) {
      _convertedLength = _getCL(thickness, length);
      _pcsPerTon = _getPCSPerTon(thickness, length.toInt());

      if (_pcsController.text.isNotEmpty) _onPcsChanged();
      else if (_tonController.text.isNotEmpty) _onTonChanged();
    }
  }

  void _onPcsChanged() {
    if (_pcsController.text.isEmpty || _pcsPerTon == 0) return;

    final pcs = int.tryParse(_pcsController.text) ?? 0;
    final tons = pcs / _pcsPerTon;

    _tonController.removeListener(_onTonChanged);
    _tonController.text = tons.toStringAsFixed(3);
    _tonController.addListener(_onTonChanged);

    _calculateCost();
  }

  void _onTonChanged() {
    if (_tonController.text.isEmpty || _pcsPerTon == 0) return;

    final tons = double.tryParse(_tonController.text) ?? 0.0;
    final pcs = (tons * _pcsPerTon).round();

    _pcsController.removeListener(_onPcsChanged);
    _pcsController.text = pcs.toString();
    _pcsController.addListener(_onPcsChanged);

    _calculateCost();
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
      _convertedLength = 0.0;
      _pcsPerTon = 0;
      _totalCost = 0.0;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // your existing UI unchanged
    );
  }
}
