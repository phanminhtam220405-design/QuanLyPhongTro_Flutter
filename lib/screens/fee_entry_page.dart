import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_invoice_page.dart';

class FeeEntryScreen extends StatefulWidget {
  const FeeEntryScreen({super.key});

  @override
  State<FeeEntryScreen> createState() => _FeeEntryScreenState();
}

class _FeeEntryScreenState extends State<FeeEntryScreen> {
  String? selectedHouseId;
  String? selectedHouseAddr;
  DateTime selectedDate = DateTime.now();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  String formatVND(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }

  String _formatTime(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString);
      return "${dt.day}/${dt.month} lúc ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          title: const Text("Quản lý Hóa đơn & Báo phí"),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('houses').where('userId', isEqualTo: uid).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Text("Đang tải...");
                        var docs = snapshot.data!.docs;
                        if (docs.isEmpty) return const Text("Chưa có nhà");
                        
                        if (selectedHouseId == null && docs.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                selectedHouseId = docs.first.id;
                                selectedHouseAddr = docs.first['address'];
                              });
                            }
                          });
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                          child: DropdownButton<String>(
                            value: selectedHouseId,
                            isExpanded: true,
                            underline: const SizedBox(),
                            onChanged: (val) {
                              setState(() {
                                selectedHouseId = val;
                                selectedHouseAddr = docs.firstWhere((d) => d.id == val)['address'];
                              });
                            },
                            items: docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['address'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_month, size: 18, color: Colors.blue),
                            const SizedBox(width: 5),
                            Text("${selectedDate.month}/${selectedDate.year}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              child: const TabBar(
                isScrollable: true,
                labelColor: Color(0xFF1976D2),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF1976D2),
                labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: "Chưa báo"),
                  Tab(text: "Đã báo"),
                  Tab(text: "Đóng một phần"),
                  Tab(text: "Đã đóng"),
                ],
              ),
            ),
            Expanded(
              child: selectedHouseId == null 
                ? const Center(child: Text("Vui lòng chọn căn nhà"))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('houses').doc(selectedHouseId).collection('rooms').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      var rooms = snapshot.data!.docs;
                      if (rooms.isEmpty) return const Center(child: Text("Nhà này chưa có phòng"));

                      return TabBarView(
                        children: [
                          _buildRoomList(rooms, "Chưa báo"),
                          _buildRoomList(rooms, "Đã báo"),
                          _buildRoomList(rooms, "Đóng một phần"),
                          _buildRoomList(rooms, "Đã đóng"),
                        ],
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomList(List<DocumentSnapshot> rooms, String tabStatus) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        var data = rooms[index].data() as Map<String, dynamic>;
        if (data['isRented'] != true) return const SizedBox();

        double roomPrice = double.tryParse(data['price'].toString()) ?? 0;
        String roomId = rooms[index].id;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bills') 
              .where('roomId', isEqualTo: roomId)
              .where('month', isEqualTo: selectedDate.month)
              .where('year', isEqualTo: selectedDate.year)
              .snapshots(),
          builder: (context, invoiceSnapshot) {
            if (!invoiceSnapshot.hasData) return const SizedBox();

            bool hasInvoice = invoiceSnapshot.data!.docs.isNotEmpty;
            String currentInvoiceStatus = "Chưa báo";
            Map<String, dynamic>? invoiceData;

            if (hasInvoice) {
              var docInvoice = invoiceSnapshot.data!.docs.first;
              invoiceData = Map<String, dynamic>.from(docInvoice.data() as Map<String, dynamic>);
              invoiceData['invoice_id'] = docInvoice.id; 
              currentInvoiceStatus = invoiceData['status'] ?? "Đã báo"; 
            }

            if (tabStatus == "Chưa báo" && currentInvoiceStatus != "Chưa báo") return const SizedBox();
            if (tabStatus == "Đã báo" && currentInvoiceStatus != "Đã báo") return const SizedBox();
            if (tabStatus == "Đóng một phần" && currentInvoiceStatus != "Đóng một phần") return const SizedBox();
            if (tabStatus == "Đã đóng" && currentInvoiceStatus != "Đã đóng") return const SizedBox();

            return _buildRoomCard(
              roomId, roomPrice, data['name'] ?? '?', data['tenantName'] ?? "Khách thuê", data['tenantPhone'] ?? "Chưa có SDT", tabStatus, invoiceData
            );
          },
        );
      },
    );
  }

  Widget _buildRoomCard(String roomId, double roomPrice, String roomName, String tenant, String phone, String status, Map<String, dynamic>? invoiceData) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () {
                      if (invoiceData != null) _showInvoiceDetails(context, invoiceData, roomName, roomId, roomPrice);
                    },
                    child: const Text("Xem chi tiết", style: TextStyle(color: Colors.red, decoration: TextDecoration.underline, fontSize: 12)),
                  ),
                ),
                Text("Phòng $roomName", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("Người thuê: $tenant - ĐT: $phone", style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 20),
                
                if (status == "Chưa báo")
                  SizedBox(
                    width: double.infinity, height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAB47BC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => CreateInvoicePage(
                          houseId: selectedHouseId!, roomId: roomId, roomName: roomName, tenantName: tenant, 
                          roomPrice: roomPrice, electricPrice: 4000, waterPrice: 20000,
                          selectedMonth: selectedDate.month, selectedYear: selectedDate.year 
                        )));
                      },
                      child: Text("Báo phí tháng ${selectedDate.month} cho khách", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity, height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status == 'Đã đóng' ? Colors.green : Colors.orange, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      onPressed: () {
                        if (invoiceData != null) _showInvoiceDetails(context, invoiceData, roomName, roomId, roomPrice);
                      },
                      child: Text("Hóa đơn: $status (Chi tiết)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          if (status == "Chưa báo")
            Positioned(
              top: 15, left: -25,
              child: Transform.rotate(angle: -0.7, child: Container(color: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 4), child: const Text("Chưa báo phí", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
            ),
        ],
      ),
    );
  }

  void _showInvoiceDetails(BuildContext context, Map<String, dynamic> data, String roomName, String roomId, double roomPrice) {
    double total = double.tryParse(data['totalAmount'].toString()) ?? 0;
    double paid = double.tryParse(data['paidAmount']?.toString() ?? '0') ?? 0;
    double remaining = total - paid;
    String invoiceId = data['invoice_id'] ?? '';
    String currentStatus = data['status'] ?? 'Chưa rõ';
    List history = data['history'] ?? [];
    
    final payCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 15),
              Text("Chi tiết hóa đơn - P.$roomName", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
              const SizedBox(height: 15),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            _invoiceRow("Tiền phòng cơ bản", formatVND(double.tryParse(data['roomPrice']?.toString() ?? '0') ?? 0)),
                            if ((data['elecTotal'] ?? 0) > 0) _invoiceRow("Điện (${data['elecOld']} ➜ ${data['elecNew']})", formatVND(double.tryParse(data['elecTotal'].toString()) ?? 0)),
                            if ((data['waterTotal'] ?? 0) > 0) _invoiceRow("Nước (${data['waterOld']} ➜ ${data['waterNew']})", formatVND(double.tryParse(data['waterTotal'].toString()) ?? 0)),
                            if ((data['xeTotal'] ?? 0) > 0) _invoiceRow("Gửi xe (${data['xeCount']} chiếc)", formatVND(double.tryParse(data['xeTotal'].toString()) ?? 0)),
                            if ((data['internet'] ?? 0) > 0) _invoiceRow("Internet", formatVND(double.tryParse(data['internet'].toString()) ?? 0)),
                            if ((data['giatsay'] ?? 0) > 0) _invoiceRow("Giặt sấy", formatVND(double.tryParse(data['giatsay'].toString()) ?? 0)),
                            if ((data['rac'] ?? 0) > 0) _invoiceRow("Tiền rác", formatVND(double.tryParse(data['rac'].toString()) ?? 0)),
                            if ((data['thangmay'] ?? 0) > 0) _invoiceRow("Thang máy", formatVND(double.tryParse(data['thangmay'].toString()) ?? 0)),
                            if ((data['dichvu'] ?? 0) > 0) _invoiceRow("Phí dịch vụ khác", formatVND(double.tryParse(data['dichvu'].toString()) ?? 0)),
                          ],
                        ),
                      ),

                      const Divider(height: 30),
                      _invoiceRow("TỔNG HÓA ĐƠN", formatVND(total), isBold: true),
                      _invoiceRow("ĐÃ ĐÓNG", formatVND(paid), valueColor: Colors.green),
                      _invoiceRow("CÒN NỢ", formatVND(remaining), valueColor: Colors.red, isBold: true),
                      const Divider(height: 30),

                      const Text("LỊCH SỬ GIAO DỊCH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 10),
                      if (history.isEmpty) 
                        const Text("Chưa có lịch sử giao dịch", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                      else
                        ...history.map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.history, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(_formatTime(h['time']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(h['msg'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                            ],
                          ),
                        )),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              
              if (currentStatus != 'Đã đóng') ...[
                const Text("Nhập số tiền khách đóng:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                TextField(
                  controller: payCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: "VD: 500000", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), suffixText: "đ"),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () async {
                            double input = double.tryParse(payCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                            if (input <= 0) return;
                            double newPaid = paid + input;
                            String newStatus = newPaid >= total ? 'Đã đóng' : 'Đóng một phần';
                            
                            List newHistory = List.from(history);
                            newHistory.add({'time': DateTime.now().toIso8601String(), 'msg': 'Khách đóng: ${formatVND(input)}'});

                            await FirebaseFirestore.instance.collection('bills').doc(invoiceId).update({'paidAmount': newPaid, 'status': newStatus, 'history': newHistory});
                            if(context.mounted) Navigator.pop(context);
                          },
                          child: const Text("ĐÓNG 1 PHẦN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () async {
                            List newHistory = List.from(history);
                            newHistory.add({'time': DateTime.now().toIso8601String(), 'msg': 'Khách tất toán: ${formatVND(remaining)}'});

                            await FirebaseFirestore.instance.collection('bills').doc(invoiceId).update({'paidAmount': total, 'status': 'Đã đóng', 'history': newHistory});
                            if(context.mounted) Navigator.pop(context);
                          },
                          child: const Text("ĐÓNG ĐỦ 100%", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                )
              ] else
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("ĐÓNG MÀN HÌNH", style: TextStyle(color: Colors.white)),
                  ),
                ),

              if (currentStatus == 'Đã báo') ...[
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity, height: 45,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue)),
                    icon: const Icon(Icons.edit),
                    label: const Text("SỬA HÓA ĐƠN NÀY"),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CreateInvoicePage(
                        houseId: selectedHouseId!, roomId: roomId, roomName: roomName, tenantName: data['tenantName'], 
                        roomPrice: roomPrice, electricPrice: 4000, waterPrice: 20000,
                        selectedMonth: data['month'], selectedYear: data['year'],
                        invoiceId: invoiceId, existingData: data,
                      )));
                    },
                  ),
                )
              ] else if (currentStatus == 'Đã đóng' || currentStatus == 'Đóng một phần') ...[
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity, height: 45,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    icon: const Icon(Icons.undo),
                    label: const Text("HOÀN TÁC (QUAY VỀ CHƯA ĐÓNG)"),
                    onPressed: () async {
                      List newHistory = List.from(history);
                      newHistory.add({'time': DateTime.now().toIso8601String(), 'msg': 'Admin hoàn tác hóa đơn về 0đ'});

                      await FirebaseFirestore.instance.collection('bills').doc(invoiceId).update({'paidAmount': 0, 'status': 'Đã báo', 'history': newHistory});
                      if(context.mounted) Navigator.pop(context);
                    },
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _invoiceRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: valueColor ?? Colors.black, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}