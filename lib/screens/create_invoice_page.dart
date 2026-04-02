import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateInvoicePage extends StatefulWidget {
  final String houseId;
  final String roomId;
  final String roomName;
  final String tenantName;
  final double roomPrice;
  final double electricPrice;
  final double waterPrice;

  const CreateInvoicePage({
    super.key, required this.houseId, required this.roomId, required this.roomName,
    required this.tenantName, required this.roomPrice, required this.electricPrice, required this.waterPrice,
  });

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final oldElecCtrl = TextEditingController();
  final newElecCtrl = TextEditingController();
  final oldWaterCtrl = TextEditingController();
  final newWaterCtrl = TextEditingController();
  final otherFeeCtrl = TextEditingController(text: '0');

  double totalAmount = 0;

  void _calculateTotal() {
    double oldE = double.tryParse(oldElecCtrl.text) ?? 0;
    double newE = double.tryParse(newElecCtrl.text) ?? 0;
    double oldW = double.tryParse(oldWaterCtrl.text) ?? 0;
    double newW = double.tryParse(newWaterCtrl.text) ?? 0;
    double other = double.tryParse(otherFeeCtrl.text) ?? 0;

    double elecDiff = (newE - oldE) > 0 ? (newE - oldE) : 0;
    double waterDiff = (newW - oldW) > 0 ? (newW - oldW) : 0;

    setState(() {
      totalAmount = widget.roomPrice + (elecDiff * widget.electricPrice) + (waterDiff * widget.waterPrice) + other;
    });
  }

  Future<void> _saveInvoice() async {
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập chỉ số điện nước!")));
      return;
    }
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('bills').add({
        'userId': uid,
        'houseId': widget.houseId,
        'roomId': widget.roomId,
        'roomName': widget.roomName,
        'tenantName': widget.tenantName,
        'totalAmount': totalAmount,
        'status': 'Chưa đóng',
        'month': DateTime.now().month,
        'year': DateTime.now().year,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Lập hóa đơn thành công!")));
        Navigator.pop(context); // Trở về trang trước
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(title: Text("Lập hóa đơn - Phòng ${widget.roomName}"), backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nhập chỉ số tháng này", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  _buildInputRow("Số điện cũ", oldElecCtrl, "Số điện mới", newElecCtrl),
                  const SizedBox(height: 15),
                  _buildInputRow("Khối nước cũ", oldWaterCtrl, "Khối nước mới", newWaterCtrl),
                  const SizedBox(height: 15),
                  TextField(
                    controller: otherFeeCtrl, keyboardType: TextInputType.number, onChanged: (v) => _calculateTotal(),
                    decoration: const InputDecoration(labelText: "Phí khác (Rác, Wifi...)", border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade200)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Tiền phòng cố định:"), Text("${widget.roomPrice} đ", style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const Divider(height: 30),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("TỔNG CỘNG:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text("${totalAmount.toStringAsFixed(0)} đ", style: const TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold))]),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _saveInvoice,
                child: const Text("LƯU & XUẤT HÓA ĐƠN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(String l1, TextEditingController c1, String l2, TextEditingController c2) {
    return Row(
      children: [
        Expanded(child: TextField(controller: c1, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l1, border: const OutlineInputBorder()), onChanged: (v) => _calculateTotal())),
        const SizedBox(width: 15),
        Expanded(child: TextField(controller: c2, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l2, border: const OutlineInputBorder()), onChanged: (v) => _calculateTotal())),
      ],
    );
  }
}