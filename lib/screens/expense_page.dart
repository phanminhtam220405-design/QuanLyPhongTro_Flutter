import 'package:flutter/material.dart';
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
  String selectedHouse = "Chọn căn nhà";
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic>? selectedCategory;

  final TextEditingController dateController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    categories = ExpenseCategories.getDefaults();
    expenses = ExpenseCategories.getSampleExpenses(categories);
    dateController.text = ExpenseUtils.getCurrentDate();
    amountController.text = '0';
  }

  // Lọc chi phí theo căn nhà được chọn
  List<Map<String, dynamic>> get filteredExpenses {
    return ExpenseUtils.filterExpensesByHouse(expenses, selectedHouse);
  }

  // Tính tổng chi tiêu
  String get totalExpense {
    return ExpenseUtils.calculateTotal(filteredExpenses);
  }

  // Hiển thị bottom sheet để chọn danh mục chi
  void _showCategorySelector() {
    ExpenseDialogs.showCategorySelector(
      context,
      categories,
      selectedCategory,
      (category) {
        setState(() {
          selectedCategory = category;
        });
      },
    );
  }

  // Hàm thêm khoản chi mới
  void _addExpense() {
    // Kiểm tra điều kiện trước khi thêm
    if (selectedHouse == "Chọn căn nhà") {
      _showMessage("Vui lòng chọn căn nhà!");
      return;
    }
    if (selectedHouse == "Tất cả các nhà") {
      _showMessage("Vui lòng chọn một căn nhà cụ thể để thêm chi!");
      return;
    }
    if (selectedCategory == null) {
      _showMessage("Vui lòng chọn danh mục chi!");
      return;
    }
    if (dateController.text.isEmpty ||
        amountController.text.isEmpty ||
        reasonController.text.isEmpty) {
      _showMessage("Vui lòng điền đầy đủ thông tin!");
      return;
    }

    // Thêm khoản chi mới vào danh sách
    setState(() {
      expenses.insert(0, {
        'house': selectedHouse, // Lưu thông tin căn nhà
        'date': dateController.text,
        'amount': amountController.text.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        ), // Lưu số tiền dưới dạng chuỗi chỉ chứa số
        'reason': reasonController.text,
        'category': selectedCategory,
      });
      amountController.text = '0';
      reasonController.text = '';
      selectedCategory = null;
    });
    _showMessage("Đã thêm khoản chi!");
  }

  // Hàm sửa khoản chi
  void _editExpense(int index) {
    ExpenseDialogs.showEditExpenseDialog(
      context,
      expenses[index],
      categories,
      (updatedExpense) {
        setState(() {
          expenses[index] = updatedExpense;
        });
        _showMessage("Đã cập nhật!");
      },
    );
  }

  // Hàm xóa khoản chi
  void _deleteExpense(int index) {
    ExpenseDialogs.showDeleteConfirmation(
      context,
      () {
        setState(() {
          expenses.removeAt(index);
        });
        _showMessage("Đã xóa!");
      },
    );
  }

  // Hàm hiển thị thông báo
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Quản lý chi", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Chọn căn nhà để quản lý chi",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            // Dropdown chọn căn nhà
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                ExpenseDialogs.showHouseSelector(
                  context,
                  selectedHouse,
                  (house) {
                    setState(() {
                      selectedHouse = house;
                    });
                  },
                );
              },
              child: ExpenseUtils.fakeDropdown(selectedHouse),
            ),
            const SizedBox(height: 20),

            // Hàng 1: Ngày chi + Danh mục chi
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dateController,
                    decoration: InputDecoration(
                      labelText: 'Ngày chi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    readOnly: true,
                    // Hiển thị DatePicker khi bấm vào TextField
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      // Cập nhật ngày đã chọn vào TextField
                      if (date != null) {
                        setState(() {
                          dateController.text =
                              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                        });
                      }
                    },
                  ),
                ),
                // Danh mục chi tiêu
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _showCategorySelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          if (selectedCategory != null) ...[
                            Icon(
                              selectedCategory!['icon'],
                              color: selectedCategory!['color'],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedCategory!['name'],
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else
                            const Expanded(
                              child: Text(
                                'Danh mục chi',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          const Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Hàng 2: Số tiền + Lý do + Nút Lưu
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Số tiền chi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onTap: () {
                      // Xóa số 0 khi bấm vào
                      if (amountController.text == '0') {
                        amountController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: 'Lý do chi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onPressed: _addExpense,
                  child: const Text(
                    "Lưu",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Hiển thị tổng chi tiêu
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade600],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đẩy 2 cụm ra 2 đầu
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Tổng chi tiêu:',
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Text(
                      totalExpense,
                      textAlign: TextAlign.end, // Căn lề phải
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Danh sách các khoản chi đã thêm
            const Text(
              "Danh sách phí đã chi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredExpenses.isEmpty
                  ? const EmptyDataWidget()
                  : ListView.builder(
                      itemCount: filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = filteredExpenses[index];
                        final actualIndex = expenses.indexOf(expense);

                        return ExpenseCard(
                          expense: expense,
                          formatCurrency: ExpenseUtils.formatCurrency,
                          onEdit: () => _editExpense(actualIndex),
                          onDelete: () => _deleteExpense(actualIndex),
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