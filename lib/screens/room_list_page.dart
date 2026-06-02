import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class RoomListScreen extends StatelessWidget {
  final String houseId, houseName;
  const RoomListScreen({
    super.key,
    required this.houseId,
    required this.houseName,
  });

  Future<String?> _createTenantAccount(
    String email,
    String name,
    String phone,
  ) async {
    try {
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempAccountCreator',
        options: Firebase.app().options,
      );
      UserCredential res = await FirebaseAuth.instanceFor(
        app: tempApp,
      ).createUserWithEmailAndPassword(email: email, password: '123456');

      String uid = res.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'phone': phone,
        'role': 'user',
        'house_id': houseId,
        'house_name': houseName,
        'room_name': '',
      });
      await tempApp.delete();
      return uid;
    } catch (e) {
      return null;
    }
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
        stream: FirebaseFirestore.instance
            .collection('houses')
            .doc(houseId)
            .collection('rooms')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(10),
            children: snapshot.data!.docs
                .map((doc) => _buildRoomCard(context, doc))
                .toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add_rounded, color: Colors.white),
        onPressed: () => _showRoomForm(context),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    bool isRented = data['isRented'] ?? false;

    String rName = data['name'] ?? '';
    String rPrice = data['price'] ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),

            decoration: BoxDecoration(
              color: isRented
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF1976D2),

              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),

            child: Row(
              children: [
                const Icon(
                  Icons.meeting_room_rounded,
                  color: Colors.white,
                  size: 22,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    "Phòng $rName",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () => _showRoomForm(context, doc: doc),
                ),

                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () => _confirmDelete(
                    context,
                    () => doc.reference.delete(),
                    "Xoá phòng $rName ?",
                  ),
                ),
              ],
            ),
          ),

          // BODY
          Padding(
            padding: const EdgeInsets.all(18),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      color: Colors.orange,
                      size: 20,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      "$rPrice đ / tháng",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      color: Colors.grey,
                      size: 18,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      "Tối đa ${data['maxOccupants'] ?? 0} người",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // TRẠNG THÁI
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),

                  decoration: BoxDecoration(
                    color: isRented
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),

                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: Text(
                    isRented ? "Đang có người thuê" : "Phòng còn trống",

                    style: TextStyle(
                      color: isRented ? Colors.green : Colors.orange,

                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton.icon(
                    icon: Icon(
                      isRented ? Icons.description : Icons.add_business,
                      color: Colors.white,
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRented
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFFF6D00),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    onPressed: () => isRented
                        ? _showViewContract(context, doc)
                        : _showCreateContract(context, doc),

                    label: Text(
                      isRented ? "XEM HỢP ĐỒNG" : "TẠO HĐ & TÀI KHOẢN",

                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateContract(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final tEmail = TextEditingController();
    final tNo = TextEditingController(
      text:
          "HD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
    );
    final tName = TextEditingController(),
        tPhone = TextEditingController(),
        tCCCD = TextEditingController(),
        tAddress = TextEditingController();
    final tDate = TextEditingController(
          text: DateTime.now().toString().split(' ')[0],
        ),
        tMonths = TextEditingController(text: "12"),
        tOccupants = TextEditingController(text: "1"),
        tDeposit = TextEditingController(
          text: data['defaultDeposit'] ?? data['price'] ?? "0",
        );
    int maxAllowed = data['maxOccupants'] ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 25),

                  CircleAvatar(
                    radius: 35,
                    backgroundColor: const Color(0xFF1976D2).withValues(alpha: 0.1),

                    child: const Icon(
                      Icons.description_outlined,
                      size: 35,
                      color: Color(0xFF1976D2),
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Tạo hợp đồng thuê phòng",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Hệ thống sẽ tự động tạo tài khoản cho khách thuê",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _whiteInput(
                "Email khách hàng (Tài khoản) *",
                "Email dùng để đăng nhập",
                tEmail,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _whiteInput(
                      "Phòng",
                      data['name'] ?? '',
                      null,
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _whiteInput("Số hợp đồng *", "", tNo)),
                ],
              ),
              const SizedBox(height: 15),
              _whiteInput("Tên khách hàng *", "", tName),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _whiteInput(
                      "Điện thoại *",
                      "",
                      tPhone,
                      type: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _whiteInput(
                      "Số CCCD *",
                      "",
                      tCCCD,
                      type: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _whiteInput("Địa chỉ thường trú khách", "", tAddress),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _whiteInput(
                      "Số người ở (Tối đa $maxAllowed)",
                      "",
                      tOccupants,
                      type: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _whiteInput(
                      "Tiền cọc thực tế (đ)",
                      "",
                      tDeposit,
                      type: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                  ),
                  onPressed: () async {
                    int inputOcc = int.tryParse(tOccupants.text) ?? 0;
                    if (inputOcc > maxAllowed) {
                      _showErrorAlert(
                        context,
                        "Quá số lượng",
                        "Phòng tối đa $maxAllowed người.",
                      );
                      return;
                    }
                    showDialog(
                      context: context,
                      builder: (ctx) =>
                          const Center(child: CircularProgressIndicator()),
                    );
                    String? tenantUid = await _createTenantAccount(
                      tEmail.text,
                      tName.text,
                      tPhone.text,
                    );
                    Navigator.pop(context);
                    if (tenantUid == null) {
                      _showErrorAlert(
                        context,
                        "Lỗi",
                        "Email đã tồn tại hoặc không hợp lệ.",
                      );
                      return;
                    }
                    await doc.reference.update({
                      'isRented': true,
                      'tenantUid': tenantUid,
                      'contractNo': tNo.text,
                      'tenantName': tName.text,
                      'tenantPhone': tPhone.text,
                      'tenantCCCD': tCCCD.text,
                      'tenantAddress': tAddress.text,
                      'contractDate': tDate.text,
                      'contractMonths': tMonths.text,
                      'occupantsCount': tOccupants.text,
                      'deposit': tDeposit.text,
                    });
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(tenantUid)
                        .update({
                          'room_name': data['name'],
                          'house_id': houseId,
                          'house_name': houseName,
                        });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "XÁC NHẬN KÝ HỢP ĐỒNG",

                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showViewContract(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String? tUid = data['tenantUid']; // Lấy ID khách thuê để xử lý

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.green.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.description,
                  size: 32,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Thông tin hợp đồng",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _whiteInput(
                      "Phòng",
                      data['name'] ?? '',
                      null,
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _whiteInput(
                      "Số HĐ",
                      data['contractNo'] ?? '',
                      null,
                      enabled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _whiteInput(
                "Khách thuê",
                data['tenantName'] ?? '',
                null,
                enabled: false,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _whiteInput(
                      "Ngày ký",
                      data['contractDate'] ?? '',
                      null,
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _whiteInput(
                      "Người ở",
                      "${data['occupantsCount']} người",
                      null,
                      enabled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _whiteInput(
                "Tiền cọc",
                "${data['deposit']} đ",
                null,
                enabled: false,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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

                        if (tUid != null && tUid.isNotEmpty) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(tUid)
                              .update({
                                'house_id': '',
                                'house_name': '',
                                'room_name': '',
                              });
                        }
                        QuerySnapshot oldBills = await FirebaseFirestore
                            .instance
                            .collection('bills')
                            .where('roomId', isEqualTo: doc.id)
                            .where('userId', isEqualTo: tUid)
                            .get();
                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .add({
                              'user_id': tUid,
                              'title': 'Thanh lý hợp đồng',
                              'message': 'Hợp đồng thuê phòng đã được thanh lý',
                              'is_read': false,
                              'createdAt': Timestamp.now(),
                            });
                        for (var bill in oldBills.docs) {
                          await bill.reference.update({'isOldTenant': true});
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text(
                        "THANH LÝ HĐ",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ĐÓNG"),
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

  void _confirmDelete(BuildContext context, Function onDelete, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận"),
        content: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            child: const Text("Xoá", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showErrorAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ĐÃ HIỂU"),
          ),
        ],
      ),
    );
  }

  Widget _whiteInput(
    String l,
    String h,
    TextEditingController? c, {
    bool enabled = true,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: c ?? TextEditingController(text: h),
        enabled: enabled,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: l,
          border: InputBorder.none,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _modernInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: TextField(
        controller: controller,
        keyboardType: type,

        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),

          labelText: label,
          hintText: hint,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),

          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  void _showRoomForm(BuildContext context, {DocumentSnapshot? doc}) {
    Map<String, dynamic>? data = doc?.data() as Map<String, dynamic>?;

    final n = TextEditingController(text: data?['name']);

    final p = TextEditingController(text: data?['price']);

    final d = TextEditingController(text: data?['defaultDeposit']);

    final m = TextEditingController(
      text: data?['maxOccupants']?.toString() ?? "2",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 22,
          right: 22,
          top: 25,
        ),

        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),

          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 5,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF1976D2).withValues(alpha: 0.1),

                    child: const Icon(
                      Icons.meeting_room_rounded,
                      color: Color(0xFF1976D2),
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Text(
                      doc == null ? "Thêm phòng mới" : "Cập nhật phòng",

                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _modernInput(
                label: "Tên phòng",
                hint: "Ví dụ: A101",
                controller: n,
                icon: Icons.home_work_outlined,
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _modernInput(
                      label: "Giá thuê",
                      hint: "0 đ",
                      controller: p,
                      type: TextInputType.number,
                      icon: Icons.attach_money,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _modernInput(
                      label: "Tiền cọc",
                      hint: "0 đ",
                      controller: d,
                      type: TextInputType.number,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _modernInput(
                label: "Số người tối đa",
                hint: "2",
                controller: m,
                type: TextInputType.number,
                icon: Icons.people_outline,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),

                    elevation: 2,
                  ),

                  onPressed: () async {
                    if (n.text.isEmpty) return;

                    final payload = {
                      'name': n.text,
                      'price': p.text,
                      'defaultDeposit': d.text,
                      'maxOccupants': int.tryParse(m.text) ?? 1,
                    };

                    if (doc == null) {
                      FirebaseFirestore.instance
                          .collection('houses')
                          .doc(houseId)
                          .collection('rooms')
                          .add({...payload, 'isRented': false});
                    } else {
                      doc.reference.update(payload);
                    }

                    Navigator.pop(context);
                  },

                  label: Text(
                    doc == null ? "THÊM PHÒNG" : "CẬP NHẬT PHÒNG",

                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
