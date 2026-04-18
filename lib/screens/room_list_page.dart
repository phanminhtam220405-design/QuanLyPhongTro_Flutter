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

  // --- FORM THÊM/SỬA PHÒNG ---
  void _showRoomForm(BuildContext context, {DocumentSnapshot? doc}) {
    Map<String, dynamic>? data = doc?.data() as Map<String, dynamic>?;
    final n = TextEditingController(text: data?['name']);
    final p = TextEditingController(text: data?['price']);
    final d = TextEditingController(text: data?['defaultDeposit']);
    final m = TextEditingController(text: data?['maxOccupants']?.toString() ?? "2");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        decoration: const BoxDecoration(color: Color(0xFFF5F5F5), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(doc == null ? "THÊM PHÒNG MỚI" : "CẬP NHẬT PHÒNG", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
              const SizedBox(height: 20),
              // ĐÃ ĐỔI THÀNH "Phòng *"
              _whiteInput("Phòng *", "", n),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _whiteInput("Tiền phòng/tháng", "", p, type: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _whiteInput("Tiền cọc mặc định", "", d, type: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 15),
              _whiteInput("Giới hạn người ở tối đa", "", m, type: TextInputType.number),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    if (n.text.isEmpty) return;
                    if (await _isRoomNameDuplicate(n.text, doc?.id)) {
                      if (context.mounted) _showErrorAlert(context, "Trùng tên phòng", "Phòng '${n.text}' đã tồn tại trong hệ thống.");
                      return;
                    }
                    final payload = {'name': n.text, 'price': p.text, 'defaultDeposit': d.text, 'maxOccupants': int.tryParse(m.text) ?? 1};
                    if (doc == null) {
                      FirebaseFirestore.instance.collection('houses').doc(houseId).collection('rooms').add({...payload, 'isRented': false});
                    } else { doc.reference.update(payload); }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("LƯU THÔNG TIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- FORM TẠO HỢP ĐỒNG ---
  void _showCreateContract(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final tNo = TextEditingController(text: "HD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}");
    final tName = TextEditingController(), tPhone = TextEditingController(), tCCCD = TextEditingController(), tAddress = TextEditingController();
    final tDate = TextEditingController(text: DateTime.now().toString().split(' ')[0]), tMonths = TextEditingController(text: "12");
    final tOccupants = TextEditingController(text: "1");
    final tDeposit = TextEditingController(text: data['defaultDeposit'] ?? data['price'] ?? "0");
    int maxAllowed = data['maxOccupants'] ?? 1;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(color: Color(0xFFF5F5F5), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(children: [
            const Text("Tạo hợp đồng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
            const SizedBox(height: 20),
            Row(children: [
              // Hiển thị tên phòng vào hợp đồng
              Expanded(child: _whiteInput("Phòng", data['name'] ?? '', null, enabled: false)),
              const SizedBox(width: 10),
              Expanded(child: _whiteInput("Số hợp đồng *", "", tNo)),
            ]),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: _whiteInput("Ngày ký *", "", tDate)),
              const SizedBox(width: 10),
              Expanded(child: _whiteInput("Thời hạn (tháng)", "", tMonths, type: TextInputType.number)),
            ]),
            const SizedBox(height: 15),
            _whiteInput("Tên khách hàng *", "", tName),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: _whiteInput("Điện thoại *", "", tPhone, type: TextInputType.phone)),
              const SizedBox(width: 10),
              Expanded(child: _whiteInput("Số CCCD *", "", tCCCD, type: TextInputType.number)),
            ]),
            const SizedBox(height: 15),
            _whiteInput("Địa chỉ thường trú khách", "", tAddress),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: _whiteInput("Số người ở (Tối đa $maxAllowed)", "", tOccupants, type: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _whiteInput("Tiền cọc thực tế (đ)", "", tDeposit, type: TextInputType.number)),
            ]),
            const SizedBox(height: 20),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
              onPressed: () {
                int inputOcc = int.tryParse(tOccupants.text) ?? 0;
                if (inputOcc > maxAllowed) {
                  _showErrorAlert(context, "Quá số lượng", "Số lượng người ở ($inputOcc) vượt quá giới hạn của phòng ($maxAllowed).");
                  return;
                }
                doc.reference.update({
                  'isRented': true,
                  'roomNameAtContract': data['name'], // Lưu tên phòng vào HĐ
                  'contractNo': tNo.text, 'tenantName': tName.text, 'tenantPhone': tPhone.text,
                  'tenantCCCD': tCCCD.text, 'tenantAddress': tAddress.text, 'contractDate': tDate.text,
                  'contractMonths': tMonths.text, 'occupantsCount': tOccupants.text, 'deposit': tDeposit.text,
                });
                Navigator.pop(context);
              },
              child: const Text("LƯU HỢP ĐỒNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )),
          ]),
        ),
      ),
    );
  }

  // --- XEM HỢP ĐỒNG ---
  void _showViewContract(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Color(0xFFF5F5F5), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(children: [
            const Text("Thông tin hợp đồng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: _whiteInput("Phòng", data['name'] ?? '', null, enabled: false)),
              const SizedBox(width: 10),
              Expanded(child: _whiteInput("Số HĐ", data['contractNo'] ?? '', null, enabled: false)),
            ]),
            const SizedBox(height: 10),
            _whiteInput("Khách thuê", data['tenantName'] ?? '', null, enabled: false),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _whiteInput("Ngày ký", data['contractDate'] ?? '', null, enabled: false)),
              const SizedBox(width: 10),
              Expanded(child: _whiteInput("Người ở", "${data['occupantsCount']} người", null, enabled: false)),
            ]),
            const SizedBox(height: 10),
            _whiteInput("Tiền cọc", "${data['deposit']} đ", null, enabled: false),
            const SizedBox(height: 30),
            Row(children: [
              Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () {
                doc.reference.update({
                  'isRented': false, 'contractNo': FieldValue.delete(), 'tenantName': FieldValue.delete(),
                  'roomNameAtContract': FieldValue.delete()
                });
                Navigator.pop(context);
              }, child: const Text("THANH LÝ", style: TextStyle(color: Colors.white)))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("ĐÓNG"))),
            ]),
          ]),
        ),
      ),
    );
  }

  // --- CÁC HÀM TIỆN ÍCH GIỮ NGUYÊN ---
  void _showErrorAlert(BuildContext context, String title, String message) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Row(children: [const Icon(Icons.error_outline, color: Colors.red), const SizedBox(width: 10), Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ĐÃ HIỂU"))]));
  }

  Future<bool> _isRoomNameDuplicate(String name, String? currentDocId) async {
    var result = await FirebaseFirestore.instance.collection('houses').doc(houseId).collection('rooms').where('name', isEqualTo: name).get();
    if (currentDocId == null) return result.docs.isNotEmpty;
    return result.docs.any((doc) => doc.id != currentDocId);
  }

  Widget _buildRoomCard(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isRented = data['isRented'] ?? false;
    String rName = data['name'] ?? '';
    String rPrice = data['price'] ?? '0';
    String rDep = data['defaultDeposit'] ?? '0';
    int maxOcc = data['maxOccupants'] ?? 0;
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: ListTile(title: Row(children: [Text("Phòng $rName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () => _showRoomForm(context, doc: doc)), IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _confirmDelete(context, () => doc.reference.delete(), "Xoá phòng $rName?"))]), subtitle: Text("Giá: $rPrice đ | Cọc: $rDep đ\nTối đa: $maxOcc người", style: const TextStyle(color: Colors.grey, fontSize: 13)), trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isRented ? Colors.green : Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () => isRented ? _showViewContract(context, doc) : _showCreateContract(context, doc), child: Text(isRented ? "Xem HĐ" : "Tạo HĐ", style: const TextStyle(color: Colors.white, fontSize: 12)))));
  }

  void _confirmDelete(BuildContext context, Function onDelete, String title) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Xác nhận"), content: Text(title), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")), TextButton(onPressed: () { onDelete(); Navigator.pop(context); }, child: const Text("Xoá", style: TextStyle(color: Colors.red)))]));
  }

  Widget _whiteInput(String l, String h, TextEditingController? c, {bool enabled = true, TextInputType type = TextInputType.text}) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)), child: TextField(controller: c ?? TextEditingController(text: h), enabled: enabled, keyboardType: type, decoration: InputDecoration(labelText: l, border: InputBorder.none, labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))));
  }

  Widget _idPhotoBox(String label) {
    return Column(children: [Container(width: 120, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)), child: const Icon(Icons.badge_outlined, size: 40, color: Colors.grey)), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]);
  }
}