import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_invoice_page.dart'; // Đảm bảo bạn đã có file này

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

  // Hàm định dạng tiền tệ VNĐ
  String formatVND(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }

  // Hàm định dạng thời gian từ chuỗi ISO
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
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          title: const Text(
            "Quản lý hóa đơn",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Column(
          children: [
            // PHẦN CHỌN NHÀ VÀ THÁNG/NĂM
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('houses')
                          .where('userId', isEqualTo: uid)
                          .snapshots(),
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
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButton<String>(
                            value: selectedHouseId,
                            isExpanded: true,
                            underline: const SizedBox(),
                            onChanged: (val) {
                              setState(() {
                                selectedHouseId = val;
                                selectedHouseAddr = docs.firstWhere(
                                  (d) => d.id == val,
                                )['address'];
                              });
                            },
                            items: docs.map((d) => DropdownMenuItem(
                                    value: d.id,
                                    child: Text(d['address'],
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  )).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_month, size: 18, color: Colors.blue),
                            const SizedBox(width: 5),
                            Text(
                              "${selectedDate.month}/${selectedDate.year}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // THANH TAB TRẠNG THÁI
            Container(
              color: Colors.white,
              child: TabBar(
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                indicator: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Chưa báo"),
                  Tab(text: "Đã báo"),
                  Tab(text: "Đóng một phần"),
                  Tab(text: "Đã đóng"),
                ],
              ),
            ),
            // DANH SÁCH PHÒNG THEO TAB
            Expanded(
              child: selectedHouseId == null
                  ? const Center(child: Text("Vui lòng chọn căn nhà"))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('houses')
                          .doc(selectedHouseId)
                          .collection('rooms')
                          .snapshots(),
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
        // QUAN TRỌNG: Lấy mã ID khách thuê để truyền sang hóa đơn
        String tenantId = data['tenantId'] ?? data['userId'] ?? ''; 

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

            if (tabStatus != currentInvoiceStatus) return const SizedBox();

            return _buildRoomCard(
              roomId,
              roomPrice,
              data['name'] ?? '?',
              data['tenantName'] ?? "Khách thuê",
              data['tenantPhone'] ?? "Chưa có SDT",
              tabStatus,
              invoiceData,
              tenantId,
            );
          },
        );
      },
    );
  }

  Widget _buildRoomCard(
    String roomId,
    double roomPrice,
    String roomName,
    String tenant,
    String phone,
    String status,
    Map<String, dynamic>? invoiceData,
    String tenantId,
  ) {
    Color statusColor = status == "Đã đóng" ? Colors.green : status == "Đóng một phần" ? Colors.orange : status == "Đã báo" ? Colors.blue : Colors.red;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(status == "Đã đóng" ? Icons.check_circle : Icons.receipt_long, color: statusColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Phòng $roomName", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(tenant, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(phone, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == "Chưa báo" ? Colors.purple : statusColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (status == "Chưa báo") {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateInvoicePage(
                      houseId: selectedHouseId!,
                      roomId: roomId,
                      roomName: roomName,
                      tenantName: tenant,
                      roomPrice: roomPrice,
                      electricPrice: 4000,
                      waterPrice: 20000,
                      selectedMonth: selectedDate.month,
                      selectedYear: selectedDate.year,
                    )));
                  } else if (invoiceData != null) {
                    _showInvoiceDetails(context, invoiceData, roomName, roomId, roomPrice);
                  }
                },
                child: Text(status == "Chưa báo" ? "TẠO HÓA ĐƠN" : "XEM & ĐÓNG TIỀN", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Chi tiết P.$roomName - Tháng ${data['month']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _invoiceRow("Tiền phòng", formatVND(double.tryParse(data['roomPrice'].toString()) ?? 0)),
                    _invoiceRow("Tiền điện", formatVND(double.tryParse(data['elecTotal'].toString()) ?? 0)),
                    _invoiceRow("Tiền nước", formatVND(double.tryParse(data['waterTotal'].toString()) ?? 0)),
                    const Divider(height: 30),
                    _invoiceRow("TỔNG CỘNG", formatVND(total), isBold: true),
                    _invoiceRow("ĐÃ ĐÓNG", formatVND(paid), valueColor: Colors.green),
                    _invoiceRow("CÒN NỢ", formatVND(remaining), valueColor: Colors.red, isBold: true),
                    const SizedBox(height: 20),
                    const Text("LỊCH SỬ GIAO DỊCH", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    ...history.map((h) => ListTile(
                      leading: const Icon(Icons.history, size: 16),
                      title: Text(h['msg'], style: const TextStyle(fontSize: 13)),
                      subtitle: Text(_formatTime(h['time']), style: const TextStyle(fontSize: 11)),
                    )).toList(),
                  ],
                ),
              ),
            ),
            if (currentStatus != 'Đã đóng') ...[
              const Text("Nhập số tiền thu thêm:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: payCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), suffixText: "đ"),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      onPressed: () async {
                        double input = double.tryParse(payCtrl.text) ?? 0;
                        if (input <= 0) return;
                        double newPaid = paid + input;
                        List newHistory = List.from(history)..add({'time': DateTime.now().toIso8601String(), 'msg': 'Thu thêm: ${formatVND(input)}'});
                        await FirebaseFirestore.instance.collection('bills').doc(invoiceId).update({
                          'paidAmount': newPaid,
                          'status': newPaid >= total ? 'Đã đóng' : 'Đóng một phần',
                          'history': newHistory,
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("XÁC NHẬN THU", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () async {
                        List newHistory = List.from(history)..add({'time': DateTime.now().toIso8601String(), 'msg': 'Tất toán hóa đơn: ${formatVND(remaining)}'});
                        await FirebaseFirestore.instance.collection('bills').doc(invoiceId).update({
                          'paidAmount': total,
                          'status': 'Đã đóng',
                          'history': newHistory,
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("TẤT TOÁN 100%", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ĐÓNG"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoiceRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor ?? Colors.black, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}