import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class RoomListScreen extends StatelessWidget {
  final String houseId, houseName;
  const RoomListScreen({super.key, required this.houseId, required this.houseName});

  Future<String?> _createTenantAccount(String email, String name, String phone) async {
    try {
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempAccountCreator',
        options: Firebase.app().options,
      );
      UserCredential res = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: '123456');
      
      String uid = res.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid, 'email': email, 'name': name, 'phone': phone, 'role': 'user',
        'house_id': houseId, 'house_name': houseName, 'room_name': '', 
      });
      await tempApp.delete();
      return uid;
    } catch (e) { return null; }
  }

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
          return ListView(
            padding: const EdgeInsets.all(10),
            children: snapshot.data!.docs.map((doc) => _buildRoomCard(context, doc)).toList(),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isRented ? Colors.green : const Color(0xFF1976D2), 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12))
            ),
            child: Row(children: [
              const Icon(Icons.door_sliding, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text("Phòng $rName", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                onPressed: () => _showRoomForm(context, doc: doc),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white70, size: 20),
                onPressed: () => _confirmDelete(context, () => doc.reference.delete(), "Xoá phòng $rName?"),
              )
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Giá thuê: $rPrice đ /tháng", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Tối đa: ${data['maxOccupants'] ?? 0} người", style: const TextStyle(color: Colors.grey)),
                const Divider(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRented ? Colors.green : Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => isRented ? _showViewContract(context, doc) : _showCreateContract(context, doc),
                    child: Text(isRented ? "XEM HỢP ĐỒNG" : "TẠO HĐ & TÀI KHOẢN", style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showCreateContract(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final tEmail = TextEditingController();
    final tNo = TextEditingController(text: "HD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}");
    final tName = TextEditingController(), tPhone = TextEditingController(), tCCCD = TextEditingController(), tAddress = TextEditingController();
    final tDate = TextEditingController(text: DateTime.now().toString().split(' ')[0]), tMonths = TextEditingController(text: "12"), tOccupants = TextEditingController(text: "1"), tDeposit = TextEditingController(text: data['defaultDeposit'] ?? data['price'] ?? "0");
    int maxAllowed = data['maxOccupants'] ?? 1;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(color: Color(0xFFF5F5F5), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(children: [
            const Text("Tạo hợp đồng & Tài khoản", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
            const SizedBox(height: 20),
            _whiteInput("Email khách hàng (Tài khoản) *", "Email dùng để đăng nhập", tEmail, type: TextInputType.emailAddress),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: _whiteInput("Phòng", data['name'] ?? '', null, enabled: false)),
              const SizedBox(width: 10),
              Expanded(child: _whiteInput("Số hợp đồng *", "", tNo)),
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
            const SizedBox(height: 25),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
              onPressed: () async {
                int inputOcc = int.tryParse(tOccupants.text) ?? 0;
                if (inputOcc > maxAllowed) {
                  _showErrorAlert(context, "Quá số lượng", "Phòng tối đa $maxAllowed người.");
                  return;
                }
                showDialog(context: context, builder: (ctx) => const Center(child: CircularProgressIndicator()));
                String? tenantUid = await _createTenantAccount(tEmail.text, tName.text, tPhone.text);
                Navigator.pop(context);
                if (tenantUid == null) {
                  _showErrorAlert(context, "Lỗi", "Email đã tồn tại hoặc không hợp lệ.");
                  return;
                }
                await doc.reference.update({
                  'isRented': true,
                  'tenantUid': tenantUid,
                  'contractNo': tNo.text, 'tenantName': tName.text, 'tenantPhone': tPhone.text,
                  'tenantCCCD': tCCCD.text, 'tenantAddress': tAddress.text, 'contractDate': tDate.text,
                  'contractMonths': tMonths.text, 'occupantsCount': tOccupants.text, 'deposit': tDeposit.text,
                });
                await FirebaseFirestore.instance.collection('users').doc(tenantUid).update({
                  'room_name': data['name'],
                  'house_id': houseId,
                  'house_name': houseName,
                });
                Navigator.pop(context);
              },
              child: const Text("XÁC NHẬN KÝ HĐ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )),
          ]),
        ),
      ),
    );
  }

  // --- HÀM THANH LÝ HỢP ĐỒNG (ĐÃ CẬP NHẬT LOGIC) ---
  void _showViewContract(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String? tUid = data['tenantUid']; // Lấy ID khách thuê để xử lý

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
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    // 1. CẬP NHẬT PHÒNG VỀ TRẠNG THÁI TRỐNG & XOÁ THÔNG TIN HĐ
                    await doc.reference.update({
                      'isRented': false,
                      'tenantUid': FieldValue.delete(),
                      'tenantName': FieldValue.delete(),
                      'tenantPhone': FieldValue.delete(),
                      'tenantCCCD': FieldValue.delete(),
                      'tenantAddress': FieldValue.delete(),
                      'contractNo': FieldValue.delete(),
                      'contractDate': FieldValue.delete(),
                      'contractMonths': FieldValue.delete(),
                      'occupantsCount': FieldValue.delete(),
                      'deposit': FieldValue.delete(),
                    });

                    // 2. XOÁ THÔNG TIN PHÒNG TRONG TÀI KHOẢN KHÁCH ĐỂ HỌ MẤT PHÒNG NGAY LẬP TỨC
                    if (tUid != null && tUid.isNotEmpty) {
                      await FirebaseFirestore.instance.collection('users').doc(tUid).update({
                        'house_id': '',
                        'house_name': '',
                        'room_name': '',
                      });
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("THANH LÝ HĐ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("ĐÓNG"))),
            ])
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Function onDelete, String title) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Xác nhận"), content: Text(title), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")), TextButton(onPressed: () { onDelete(); Navigator.pop(context); }, child: const Text("Xoá", style: TextStyle(color: Colors.red)))]));
  }

  void _showErrorAlert(BuildContext context, String title, String message) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Row(children: [const Icon(Icons.error_outline, color: Colors.red), const SizedBox(width: 10), Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ĐÃ HIỂU"))]));
  }

  Widget _whiteInput(String l, String h, TextEditingController? c, {bool enabled = true, TextInputType type = TextInputType.text}) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)), child: TextField(controller: c ?? TextEditingController(text: h), enabled: enabled, keyboardType: type, decoration: InputDecoration(labelText: l, border: InputBorder.none, labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))));
  }

  void _showRoomForm(BuildContext context, {DocumentSnapshot? doc}) {
    Map<String, dynamic>? data = doc?.data() as Map<String, dynamic>?;
    final n = TextEditingController(text: data?['name']), p = TextEditingController(text: data?['price']), d = TextEditingController(text: data?['defaultDeposit']), m = TextEditingController(text: data?['maxOccupants']?.toString() ?? "2");
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Container(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20), decoration: const BoxDecoration(color: Color(0xFFF5F5F5), borderRadius: BorderRadius.vertical(top: Radius.circular(20))), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(doc == null ? "THÊM PHÒNG MỚI" : "CẬP NHẬT PHÒNG", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))), const SizedBox(height: 20), _whiteInput("Phòng *", "", n), const SizedBox(height: 15), Row(children: [Expanded(child: _whiteInput("Tiền phòng", "", p, type: TextInputType.number)), const SizedBox(width: 10), Expanded(child: _whiteInput("Tiền cọc", "", d, type: TextInputType.number))]), const SizedBox(height: 15), _whiteInput("Tối đa người ở", "", m, type: TextInputType.number), const SizedBox(height: 25), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)), onPressed: () async { if (n.text.isEmpty) return; final payload = {'name': n.text, 'price': p.text, 'defaultDeposit': d.text, 'maxOccupants': int.tryParse(m.text) ?? 1}; if (doc == null) { FirebaseFirestore.instance.collection('houses').doc(houseId).collection('rooms').add({...payload, 'isRented': false}); } else { doc.reference.update(payload); } Navigator.pop(context); }, child: const Text("LƯU", style: TextStyle(color: Colors.white)))), const SizedBox(height: 20)]))));
  }
}