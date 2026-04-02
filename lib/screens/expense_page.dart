import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/expense_card.dart';
import '../widgets/common_widgets.dart';
import 'expense/expense_model.dart';
import 'expense/expense_utils.dart';
import 'expense/expense_dialogs.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});
  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // Chỉ giữ lại 1 bộ controller duy nhất để tránh nhầm lẫn
  final dateController = TextEditingController();
  final amountController = TextEditingController();
  final reasonController = TextEditingController();

  String selectedHouse = "Chọn căn nhà";
  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic>? selectedCategory;

  @override
  void initState() {
    super.initState();
    categories = ExpenseCategories.getDefaults();
    dateController.text = ExpenseUtils.getCurrentDate();
    amountController.text = '0';
  }

  void _showCategorySelector() {
    ExpenseDialogs.showCategorySelector(context, categories, selectedCategory, (
      category,
    ) {
      setState(() {
        selectedCategory = category;
      });
    });
  }

  // Hàm lưu trực tiếp lên Firestore
  void _saveToFirebase() async {
    if (selectedHouse == "Chọn căn nhà" || selectedHouse == "Tất cả các nhà") {
      _showMessage("Vui lòng chọn một căn nhà cụ thể!");
      return;
    }
    if (selectedCategory == null) {
      _showMessage("Vui lòng chọn danh mục chi!");
      return;
    }
    if (reasonController.text.isEmpty || amountController.text == '0') {
      _showMessage("Vui lòng nhập lý do và số tiền!");
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('expenses').add({
        'userId': uid,
        'house_id': selectedHouse,
        'reason': reasonController.text,
        'amount': amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'category_name': selectedCategory!['name'],
        'date': dateController.text, // Hoặc dùng FieldValue.serverTimestamp()
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showMessage("Đã lưu khoản chi lên hệ thống!");

      // Xóa form sau khi lưu thành công
      reasonController.clear();
      amountController.text = '0';
      setState(() {
        selectedCategory = null;
      });
    } catch (e) {
      _showMessage("Lỗi: $e");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        title: const Text("Quản lý chi phí"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // 1. KHU VỰC NHẬP LIỆU (Card trắng)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                children: [
                  // Chọn căn nhà
                  GestureDetector(
                    onTap: () => ExpenseDialogs.showHouseSelector(
                      context,
                      selectedHouse,
                      (house) {
                        setState(() => selectedHouse = house);
                      },
                    ),
                    child: ExpenseUtils.fakeDropdown(selectedHouse),
                  ),
                  const Divider(),
                  // Ngày và Danh mục
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateController,
                          decoration: const InputDecoration(
                            labelText: "Ngày chi",
                            border: InputBorder.none,
                          ),
                          readOnly: true,
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(
                                () => dateController.text =
                                    "${picked.day}/${picked.month}/${picked.year}",
                              );
                            }
                          },
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        child: InkWell(
                          onTap: _showCategorySelector,
                          child: Text(
                            selectedCategory?['name'] ?? "Chọn danh mục",
                            style: TextStyle(
                              color: selectedCategory == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Lý do và Số tiền
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: "Lý do chi",
                      border: InputBorder.none,
                    ),
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Số tiền",
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                      ),
                      onPressed: _saveToFirebase,
                      child: const Text(
                        "LƯU KHOẢN CHI",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Danh sách đã chi (Từ Firebase)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 2. DANH SÁCH CHI PHÍ (StreamBuilder)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('expenses')
                    .where('userId', isEqualTo: uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return Center(child: Text("Lỗi: ${snapshot.error}"));
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  var docs = snapshot.data!.docs;
                  if (docs.isEmpty)
                    return const Center(child: Text("Chưa có dữ liệu."));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: const Icon(
                            Icons.money_off,
                            color: Colors.red,
                          ),
                          title: Text(data['reason'] ?? ""),
                          subtitle: Text(
                            "${data['date']} - ${data['house_id']}",
                          ),
                          trailing: Text(
                            "-${data['amount']}đ",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onLongPress: () => docs[index].reference.delete(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
