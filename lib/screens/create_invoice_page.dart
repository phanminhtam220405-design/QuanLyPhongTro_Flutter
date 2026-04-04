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
  final int selectedMonth;
  final int selectedYear;
  final String? invoiceId;
  final Map<String, dynamic>? existingData;

  const CreateInvoicePage({
    super.key, required this.houseId, required this.roomId, required this.roomName,
    required this.tenantName, required this.roomPrice, required this.electricPrice, required this.waterPrice,
    required this.selectedMonth, required this.selectedYear, this.invoiceId, this.existingData,
  });

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final oldElecCtrl = TextEditingController();
  final newElecCtrl = TextEditingController();
  final oldWaterCtrl = TextEditingController();
  final newWaterCtrl = TextEditingController();
  final xeCountCtrl = TextEditingController(text: '0');
  final internetCtrl = TextEditingController(text: '100000');
  final giatSayCtrl = TextEditingController(text: '50000');
  final racCtrl = TextEditingController(text: '17000');
  final thangMayCtrl = TextEditingController(text: '0');
  final dichVuCtrl = TextEditingController(text: '0');

  double totalAmount = 0;
  double elecTotal = 0;
  double waterTotal = 0;
  double xeTotal = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      oldElecCtrl.text = widget.existingData!['elecOld']?.toString() ?? '';
      newElecCtrl.text = widget.existingData!['elecNew']?.toString() ?? '';
      oldWaterCtrl.text = widget.existingData!['waterOld']?.toString() ?? '';
      newWaterCtrl.text = widget.existingData!['waterNew']?.toString() ?? '';
      xeCountCtrl.text = widget.existingData!['xeCount']?.toString() ?? '0';
      internetCtrl.text = widget.existingData!['internet']?.toString() ?? '100000';
      giatSayCtrl.text = widget.existingData!['giatsay']?.toString() ?? '50000';
      racCtrl.text = widget.existingData!['rac']?.toString() ?? '17000';
      thangMayCtrl.text = widget.existingData!['thangmay']?.toString() ?? '0';
      dichVuCtrl.text = widget.existingData!['dichvu']?.toString() ?? '0';
    }
    _calculateTotal();
  }

  String formatVND(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }

  void _calculateTotal() {
    double oldE = double.tryParse(oldElecCtrl.text) ?? 0;
    double newE = double.tryParse(newElecCtrl.text) ?? 0;
    double elecDiff = (newE - oldE) > 0 ? (newE - oldE) : 0;
    elecTotal = elecDiff * widget.electricPrice;

    double oldW = double.tryParse(oldWaterCtrl.text) ?? 0;
    double newW = double.tryParse(newWaterCtrl.text) ?? 0;
    double waterDiff = (newW - oldW) > 0 ? (newW - oldW) : 0;
    waterTotal = waterDiff * widget.waterPrice;

    double xeCount = double.tryParse(xeCountCtrl.text) ?? 0;
    xeTotal = xeCount * 10000;

    double internet = double.tryParse(internetCtrl.text) ?? 0;
    double giatsay = double.tryParse(giatSayCtrl.text) ?? 0;
    double rac = double.tryParse(racCtrl.text) ?? 0;
    double thangmay = double.tryParse(thangMayCtrl.text) ?? 0;
    double dichvu = double.tryParse(dichVuCtrl.text) ?? 0;

    setState(() {
      totalAmount = widget.roomPrice + elecTotal + waterTotal + xeTotal + internet + giatsay + rac + thangmay + dichvu;
    });
  }

  Future<void> _saveInvoice() async {
    if (totalAmount < widget.roomPrice) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi tính toán số tiền!")));
      return;
    }
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      
      Map<String, dynamic> payload = {
        'userId': uid,
        'houseId': widget.houseId,
        'roomId': widget.roomId,
        'roomName': widget.roomName,
        'tenantName': widget.tenantName,
        'totalAmount': totalAmount,
        'month': widget.selectedMonth,
        'year': widget.selectedYear,
        'roomPrice': widget.roomPrice,
        'elecOld': oldElecCtrl.text,
        'elecNew': newElecCtrl.text,
        'elecTotal': elecTotal,
        'waterOld': oldWaterCtrl.text,
        'waterNew': newWaterCtrl.text,
        'waterTotal': waterTotal,
        'xeCount': xeCountCtrl.text,
        'xeTotal': xeTotal,
        'internet': double.tryParse(internetCtrl.text) ?? 0,
        'giatsay': double.tryParse(giatSayCtrl.text) ?? 0,
        'rac': double.tryParse(racCtrl.text) ?? 0,
        'thangmay': double.tryParse(thangMayCtrl.text) ?? 0,
        'dichvu': double.tryParse(dichVuCtrl.text) ?? 0,
      };

      if (widget.invoiceId != null) {
        List newHistory = List.from(widget.existingData?['history'] ?? []);
        newHistory.add({
          'time': DateTime.now().toIso8601String(),
          'msg': 'Cập nhật lại hóa đơn: ${formatVND(totalAmount)}'
        });
        payload['history'] = newHistory;
        await FirebaseFirestore.instance.collection('bills').doc(widget.invoiceId).update(payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật hóa đơn thành công!")));
          Navigator.pop(context);
        }
      } else {
        payload['paidAmount'] = 0;
        payload['status'] = 'Đã báo';
        payload['createdAt'] = FieldValue.serverTimestamp();
        payload['history'] = [
          {
            'time': DateTime.now().toIso8601String(),
            'msg': 'Lập hóa đơn: ${formatVND(totalAmount)}'
          }
        ];
        await FirebaseFirestore.instance.collection('bills').add(payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xuất hóa đơn thành công!")));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.invoiceId != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? "Sửa hóa đơn T${widget.selectedMonth}/${widget.selectedYear}" : "Báo phí T${widget.selectedMonth}/${widget.selectedYear}"), 
        backgroundColor: const Color(0xFF1976D2), 
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFakeDropdown("Nhà ID: ${widget.houseId.substring(0, 5)}..."),
            const SizedBox(height: 10),
            _buildFakeDropdown("Phòng: ${widget.roomName} - ${widget.tenantName}"),
            const SizedBox(height: 25),

            Text("Chỉ số Điện - ${formatVND(widget.electricPrice)}/Kwh", style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTextField("Chỉ số cũ", oldElecCtrl)),
                const SizedBox(width: 15),
                Expanded(child: _buildTextField("Chỉ số mới", newElecCtrl)),
              ],
            ),
            const SizedBox(height: 25),

            Text("Chỉ số Nước - ${formatVND(widget.waterPrice)}/Khối", style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTextField("Khối cũ", oldWaterCtrl)),
                const SizedBox(width: 15),
                Expanded(child: _buildTextField("Khối mới", newWaterCtrl)),
              ],
            ),
            const SizedBox(height: 25),

            const Text("Các loại phí dịch vụ (đ/Phòng)", style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTextField("Internet", internetCtrl)),
                const SizedBox(width: 15),
                Expanded(child: _buildTextField("Giặt sấy", giatSayCtrl)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildTextField("Tiền Rác", racCtrl)),
                const SizedBox(width: 15),
                Expanded(child: _buildTextField("Thang máy", thangMayCtrl)),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField("Phí dịch vụ khác", dichVuCtrl),
            const SizedBox(height: 25),

            const Text("Gửi Xe (10.000đ/Chiếc)", style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: _buildTextField("Số lượng xe", xeCountCtrl),
            ),
            
            const SizedBox(height: 30),
            const Divider(thickness: 2),
            const SizedBox(height: 10),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tiền phòng cơ bản:", style: TextStyle(fontSize: 16)),
                Text(formatVND(widget.roomPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TỔNG THANH TOÁN:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(formatVND(totalAmount), style: const TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEditing ? Colors.blue : const Color(0xFFFF9800),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                onPressed: _saveInvoice,
                child: Text(isEditing ? "CẬP NHẬT HÓA ĐƠN" : "TÍNH TIỀN & XUẤT HÓA ĐƠN", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy bỏ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFakeDropdown(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(text, style: const TextStyle(fontWeight: FontWeight.w500)), const Icon(Icons.keyboard_arrow_down, color: Colors.grey)],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl, 
      keyboardType: TextInputType.number, 
      onChanged: (v) => _calculateTotal(),
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10)
      ), 
    );
  }
}