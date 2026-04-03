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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          title: const Text("Thống kê báo phí"),
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
                        
                        if (selectedHouseId == null) {
                          selectedHouseId = docs.first.id;
                          selectedHouseAddr = docs.first['address'];
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
                  // Chọn Tháng/Năm
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        // Logic chọn tháng đơn giản (Có thể dùng thư viện month_picker nếu muốn chuyên nghiệp hơn)
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

            // TABS TRẠNG THÁI
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

  Widget _buildRoomList(List<DocumentSnapshot> rooms, String status) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        var data = rooms[index].data() as Map<String, dynamic>;
        
        // Giả sử logic lọc: Chỉ hiện phòng "isRented == true" (đang thuê)
        if (data['isRented'] != true) return const SizedBox();

        double roomPrice = double.tryParse(data['price'].toString()) ?? 0;

        return _buildRoomCard(
          rooms[index].id,
          roomPrice,
          data['name'] ?? '?',
          data['tenantName'] ?? "Khách thuê",
          data['tenantPhone'] ?? "Chưa có SDT",
          status
        );
      },
    );
  }

  Widget _buildRoomCard(String roomId, double roomPrice, String roomName, String tenant, String phone, String status) {
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
                    onPressed: () {},
                    child: const Text("Xem chi tiết", style: TextStyle(color: Colors.red, decoration: TextDecoration.underline, fontSize: 12)),
                  ),
                ),
                Text(roomName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("Người thuê: $tenant - ĐT: $phone", style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAB47BC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateInvoicePage(
                            houseId: selectedHouseId!,
                            roomId: roomId,
                            roomName: roomName,
                            tenantName: tenant,
                            roomPrice: roomPrice,
                            electricPrice: 3500,
                            waterPrice: 20000,
                          ),
                        ),
                      );
                    },
                    child: Text("Báo phí tháng ${selectedDate.month} cho khách", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          if (status == "Chưa báo")
            Positioned(
              top: 15,
              left: -25,
              child: Transform.rotate(
                angle: -0.7,
                child: Container(
                  color: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 4),
                  child: const Text(
                    "Chưa báo phí",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}