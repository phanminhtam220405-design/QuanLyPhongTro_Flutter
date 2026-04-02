import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomListScreen extends StatelessWidget {
  final String houseId, houseName;
  const RoomListScreen({super.key, required this.houseId, required this.houseName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2), 
        foregroundColor: Colors.white, 
        title: Text("Phòng tại: $houseName"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('houses').doc(houseId).collection('rooms').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) => _buildRoomCard(context, docs[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2), 
        child: const Icon(Icons.add, color: Colors.white), 
        onPressed: () => _showRoomForm(context),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isRented = data['isRented'] ?? false;
    String rName = data['name'] ?? '';
    String rPrice = data['price'] ?? '0';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Row(
          children: [
            Text("Phòng $rName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () => _showRoomForm(context, doc: doc)),
          ],
        ),
        subtitle: Text("$rPrice đ /tháng", style: const TextStyle(color: Colors.grey)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isRented ? Colors.green : Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          // NẾU ĐÃ THUÊ THÌ XEM, CHƯA THÌ TẠO
          onPressed: () => isRented ? _showViewContract(context, doc) : _showCreateContract(context, doc),
          child: Text(isRented ? "Xem HĐ" : "Tạo HĐ", style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
    );
  }

  // --- HÀM TẠO HỢP ĐỒNG ---
  void _showCreateContract(BuildContext context, DocumentSnapshot doc) {
    final tName = TextEditingController();
    final tPhone = TextEditingController();
    final tCCCD = TextEditingController();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Color(0xFFF5F5F5), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text("Tạo hợp đồng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
              const SizedBox(height: 20),
              _whiteInput("Số hợp đồng *", "12202604021024", null),
              const SizedBox(height: 15),
              Row(children: [
                Expanded(child: _whiteInput("Tên khách hàng *", "", tName)),
                const SizedBox(width: 10),
                Expanded(child: _whiteInput("Điện thoại *", "", tPhone)),
              ]),
              const SizedBox(height: 15),
              _whiteInput("Số CCCD *", "", tCCCD),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_idPhotoBox("Mặt trước CCCD"), _idPhotoBox("Mặt sau CCCD")]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _whiteInput("Phòng", data['name'], null, enabled: false)),
                const SizedBox(width: 10),
                Expanded(child: _whiteInput("Giá thuê", data['price'], null, enabled: false)),
              ]),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
                  onPressed: () {
                    doc.reference.update({
                      'isRented': true,
                      'tenantName': tName.text,
                      'tenantPhone': tPhone.text,
                      'tenantCCCD': tCCCD.text,
                      'contractDate': DateTime.now().toString().split(' ')[0],
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("LƯU HỢP ĐỒNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HÀM XEM HỢP ĐỒNG (GIAO DIỆN CHỈ ĐỌC) ---
  void _showViewContract(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Color(0xFFF5F5F5), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text("Thông tin hợp đồng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 20),
              _whiteInput("Tên khách thuê", data['tenantName'] ?? '', null, enabled: false),
              const SizedBox(height: 15),
              _whiteInput("Điện thoại", data['tenantPhone'] ?? '', null, enabled: false),
              const SizedBox(height: 15),
              _whiteInput("Số CCCD", data['tenantCCCD'] ?? '', null, enabled: false),
              const SizedBox(height: 15),
              _whiteInput("Ngày ký", data['contractDate'] ?? '', null, enabled: false),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        // THANH LÝ HỢP ĐỒNG -> Đưa phòng về trống
                        doc.reference.update({
                          'isRented': false,
                          'tenantName': FieldValue.delete(),
                          'tenantPhone': FieldValue.delete(),
                          'tenantCCCD': FieldValue.delete(),
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("THANH LÝ HĐ", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ĐÓNG", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HÀM THÊM/SỬA PHÒNG ---
  void _showRoomForm(BuildContext context, {DocumentSnapshot? doc}) {
    Map<String, dynamic>? data = doc?.data() as Map<String, dynamic>?;
    final n = TextEditingController(text: data?['name']), p = TextEditingController(text: data?['price']);
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(doc == null ? "Thêm phòng" : "Sửa phòng"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: n, decoration: const InputDecoration(labelText: "Tên phòng")),
        TextField(controller: p, decoration: const InputDecoration(labelText: "Giá thuê"), keyboardType: TextInputType.number),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
        ElevatedButton(onPressed: () {
          final payload = {'name': n.text, 'price': p.text};
          if (doc == null) {
            FirebaseFirestore.instance.collection('houses').doc(houseId).collection('rooms').add({...payload, 'isRented': false});
          } else { doc.reference.update(payload); }
          Navigator.pop(context);
        }, child: const Text("Lưu"))
      ],
    ));
  }

  // --- WIDGET GIAO DIỆN ---
  Widget _whiteInput(String l, String h, TextEditingController? c, {bool enabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        controller: c ?? TextEditingController(text: h),
        enabled: enabled,
        decoration: InputDecoration(labelText: l, border: InputBorder.none, labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _idPhotoBox(String label) {
    return Column(children: [
      Container(width: 120, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)), child: const Icon(Icons.badge_outlined, size: 40, color: Colors.grey)),
      const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
  }
}