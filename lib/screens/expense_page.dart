import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qlphongtro/widgets/expense_card.dart';
import 'expense/expense_model.dart';
import 'expense/expense_utils.dart';
import 'expense/expense_dialogs.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});
  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
  final dateController = TextEditingController();
  final amountController = TextEditingController();
  final reasonController = TextEditingController();

  String selectedHouse = "Chọn căn nhà";
  List<String> houseList = [];
  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic>? selectedCategory;

  @override
  void initState() {
    super.initState();
    categories = ExpenseCategories.getDefaults();
    dateController.text = ExpenseUtils.getCurrentDate();
    amountController.text = '0';
    _fetchHouses();
  }

  void _fetchHouses() {
    if (uid.isEmpty) return;

    FirebaseFirestore.instance
        .collection('houses')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              houseList = snapshot.docs.map((doc) {
                String name = doc['name']?.toString() ?? "Không tên";
                String address = doc['address']?.toString() ?? "";
                return address.isNotEmpty ? "$name - $address" : name;
              }).toList();

              if (houseList.isNotEmpty && selectedHouse == "Chọn căn nhà") {
                selectedHouse = houseList[0];
              }
            });
          }
        });
  }

  void _saveToFirebase() async {
    if (selectedHouse == "Chọn căn nhà" ||
        selectedCategory == null ||
        reasonController.text.isEmpty) {
      _showMessage("Vui lòng nhập đầy đủ thông tin!");
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('expenses').add({
        'userId': uid,
        'house_id': selectedHouse,
        'reason': reasonController.text,
        'amount': amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'category': {
          'name': selectedCategory!['name'],
          'icon': selectedCategory!['icon'].codePoint,
          'color': selectedCategory!['color'].value,
        },
        'date': dateController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _showMessage("Đã lưu thành công!");
      reasonController.clear();
      amountController.text = '0';
    } catch (e) {
      _showMessage("Lỗi lưu dữ liệu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text("Quản lý chi phí"),
        backgroundColor: const Color(0xFF1976D2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      ExpenseDialogs.showHouseSelector(
                        context,
                        selectedHouse,
                        houseList,
                        (h) => setState(() => selectedHouse = h),
                      );
                    },
                    child: ExpenseUtils.fakeDropdown(selectedHouse),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                dateController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                              });
                            }
                          },
                          child: _buildInputLabel(
                            "Ngày chi",
                            dateController.text,
                            Icons.calendar_today,
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 20),
                      Expanded(
                        child: InkWell(
                          onTap: () => ExpenseDialogs.showCategorySelector(
                            context,
                            categories,
                            selectedCategory,
                            (c) => setState(() => selectedCategory = c),
                          ),
                          child: _buildInputLabel(
                            "Danh mục",
                            selectedCategory?['name'] ?? "Chọn danh mục",
                            Icons.category,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: "Lý do chi",
                      border: InputBorder.none,
                      icon: Icon(Icons.edit_note),
                    ),
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Số tiền",
                      border: InputBorder.none,
                      icon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _saveToFirebase,
                      child: const Text(
                        "LƯU KHOẢN CHI",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Danh sách đã chi",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('expenses')
                  .where('userId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Lỗi truy vấn: ${snapshot.error}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                }
                
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("Chưa có dữ liệu chi phí"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    Map<String, dynamic> formatted = {
                      'reason': data['reason'] ?? "",
                      'amount': data['amount'] ?? "0",
                      'date': data['date'] ?? "",
                      'house': data['house_id'] ?? "",
                      'category': {
                        'name': data['category']?['name'] ?? "Khác",
                        'icon': IconData(
                          data['category']?['icon'] ?? 58713,
                          fontFamily: 'MaterialIcons',
                        ),
                        'color': Color(
                          data['category']?['color'] ?? 0xFF9E9E9E,
                        ),
                      },
                    };
                    return ExpenseCard(
                      expense: formatted,
                      onEdit: () {},
                      onDelete: () => docs[index].reference.delete(),
                      formatCurrency: (v) => "${v}đ",
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            const SizedBox(width: 5),
            Text(value),
          ],
        ),
      ],
    );
  }

  void _showMessage(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}