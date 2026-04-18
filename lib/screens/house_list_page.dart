import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'room_list_page.dart';

class HouseListScreen extends StatelessWidget {
  const HouseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white,
        title: const Text("Các căn nhà của bạn"),
        actions: [IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _showHouseForm(context, uid: uid))],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('houses').where('userId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(10),
            children: snapshot.data!.docs.map((doc) => _buildHouseCard(context, doc)).toList(),
          );
        },
      ),
    );
  }

  // Hàm hiển thị bảng báo lỗi cho Nhà
  void _showErrorAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        ]),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ĐÃ HIỂU")),
        ],
      ),
    );
  }

  Future<bool> _isAddressDuplicate(String address, String uid, String? currentDocId) async {
    var result = await FirebaseFirestore.instance.collection('houses').where('userId', isEqualTo: uid).where('address', isEqualTo: address).get();
    if (currentDocId == null) return result.docs.isNotEmpty;
    return result.docs.any((doc) => doc.id != currentDocId);
  }

  Widget _buildHouseCard(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFF1976D2), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(children: [
              const Icon(Icons.home, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(data['address'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.delete_forever, color: Colors.white), onPressed: () => _confirmDelete(context, () => doc.reference.delete(), "Xoá nhà tại ${data['address']}?"))
            ]),
          ),
          Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("👤 ${data['name']} - ${data['phone']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            _feeRow("Điện", "KWH", "${data['electricPrice'] ?? 0} đ"),
            _feeRow("Nước", "phòng", "${data['waterPrice'] ?? 0} đ"),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => _showHouseForm(context, uid: FirebaseAuth.instance.currentUser!.uid, doc: doc), icon: const Icon(Icons.edit), label: const Text("Sửa nhà"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RoomListScreen(houseId: doc.id, houseName: data['address']))), icon: const Icon(Icons.door_sliding), label: const Text("DS Phòng"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6D00), foregroundColor: Colors.white))),
            ]),
          ]))
        ],
      ),
    );
  }

  void _showHouseForm(BuildContext context, {required String uid, DocumentSnapshot? doc}) {
    Map<String, dynamic>? data = doc?.data() as Map<String, dynamic>?;
    final n = TextEditingController(text: data?['name']), p = TextEditingController(text: data?['phone']), a = TextEditingController(text: data?['address']), ep = TextEditingController(text: data?['electricPrice']), wp = TextEditingController(text: data?['waterPrice']);

    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(doc == null ? "Tạo thông tin căn nhà" : "Sửa thông tin căn nhà", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextField(controller: n, decoration: const InputDecoration(labelText: "Tên quản lý *")),
        TextField(controller: p, decoration: const InputDecoration(labelText: "Điện thoại *")),
        TextField(controller: a, decoration: const InputDecoration(labelText: "Địa chỉ nhà *")),
        Row(children: [Expanded(child: TextField(controller: ep, decoration: const InputDecoration(labelText: "Giá điện"))), const SizedBox(width: 10), Expanded(child: TextField(controller: wp, decoration: const InputDecoration(labelText: "Giá nước")))]),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () async {
          if (a.text.isEmpty) return;
          if (await _isAddressDuplicate(a.text, uid, doc?.id)) {
            if (context.mounted) _showErrorAlert(context, "Trùng địa chỉ", "Địa chỉ '${a.text}' đã có trong danh sách của bạn. Vui lòng kiểm tra lại.");
            return;
          }
          final payload = {'name': n.text, 'phone': p.text, 'address': a.text, 'electricPrice': ep.text, 'waterPrice': wp.text};
          if (doc == null) { FirebaseFirestore.instance.collection('houses').add({...payload, 'userId': uid}); }
          else { doc.reference.update(payload); }
          if (context.mounted) Navigator.pop(context);
        }, child: Text(doc == null ? "LƯU THÔNG TIN" : "CẬP NHẬT")),
        const SizedBox(height: 20),
      ]),
    ));
  }

  void _confirmDelete(BuildContext context, Function onDelete, String title) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Xác nhận"), content: Text(title), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")), TextButton(onPressed: () { onDelete(); Navigator.pop(context); }, child: const Text("Xoá", style: TextStyle(color: Colors.red)))]));
  }

  Widget _feeRow(String l, String u, String p) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [Expanded(child: Text(l)), Expanded(child: Text(u, textAlign: TextAlign.center)), Expanded(child: Text(p, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)))]));
  }
}