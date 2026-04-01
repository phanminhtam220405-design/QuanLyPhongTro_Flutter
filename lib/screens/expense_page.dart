import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  // Biến lưu trữ căn nhà được chọn
  String selectedHouse = "Chọn căn nhà";
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic>? selectedCategory;

  // Controllers cho form thêm/sửa chi
  final TextEditingController dateController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Danh mục chi tiêu mặc định
    categories = [
      {'icon': Icons.water_drop, 'name': 'Tiền nước', 'color': Colors.blue},
      {'icon': Icons.bolt, 'name': 'Tiền điện', 'color': Colors.orange},
      {'icon': Icons.wifi, 'name': 'Internet', 'color': Colors.purple},
      {'icon': Icons.home, 'name': 'Tiền nhà', 'color': Colors.green},
      {'icon': Icons.build, 'name': 'Sửa chữa', 'color': Colors.brown},
      {'icon': Icons.more_horiz, 'name': 'Khác', 'color': Colors.teal},
    ];

    // Dữ liệu mẫu ban đầu
    expenses = [
      {
        'house': '123 Nguyễn Đình Chiểu, P5, Q3',
        'date': '01/03/2026',
        'amount': '500000',
        'reason': 'Sửa chữa ống nước',
        'category': categories[4],
      },
      {
        'house': '123 Nguyễn Đình Chiểu, P5, Q3',
        'date': '05/03/2026',
        'amount': '1200000',
        'reason': 'Mua thiết bị điện',
        'category': categories[1],
      },
      {
        'house': '456 Lê Văn Sỹ, P13, Q3',
        'date': '03/03/2026',
        'amount': '300000',
        'reason': 'Vệ sinh định kỳ',
        'category': categories[5],
      },
    ];
    dateController.text = _getCurrentDate();
    amountController.text = '0';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  // Lọc chi phí theo căn nhà được chọn
  List<Map<String, dynamic>> get filteredExpenses {
    if (selectedHouse == "Chọn căn nhà" || selectedHouse == "Tất cả các nhà") {
      return expenses;
    }
    return expenses
        .where((expense) => expense['house'] == selectedHouse)
        .toList();
  }

  // Hiển thị bottom sheet chọn danh mục
  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn danh mục chi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.2,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                      });
                      Navigator.pop(modalContext);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: category['color'].withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedCategory == category
                                  ? category['color']
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            category['icon'],
                            size: 30,
                            color: category['color'],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addExpense() {
    if (selectedHouse == "Chọn căn nhà") {
      _showMessage("Vui lòng chọn căn nhà!");
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

    setState(() {
      expenses.insert(0, {
        'house': selectedHouse,
        'date': dateController.text,
        'amount': amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'reason': reasonController.text,
        'category': selectedCategory,
      });
      amountController.text = '0';
      reasonController.text = '';
      selectedCategory = null;
    });
    _showMessage("Đã thêm khoản chi!");
  }

  void _editExpense(int index) {
    final tempDateController = TextEditingController(
      text: expenses[index]['date'],
    );
    final tempAmountController = TextEditingController(
      text: expenses[index]['amount'],
    );
    final tempReasonController = TextEditingController(
      text: expenses[index]['reason'],
    );
    Map<String, dynamic>? tempCategory = expenses[index]['category'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sửa khoản chi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tempDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Ngày chi',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        tempDateController.text =
                            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                // Chọn nhanh danh mục trong dialog
                GestureDetector(
                  onTap: () {
                    // Logic tương tự _showCategorySelector nhưng gọi setDialogState
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (tempCategory != null) ...[
                          Icon(
                            tempCategory['icon'],
                            color: tempCategory['color'],
                          ),
                          const SizedBox(width: 10),
                          Text(tempCategory['name']),
                        ] else
                          const Text('Chọn danh mục'),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tempAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tempReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Lý do chi',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
              ),
              onPressed: () {
                setState(() {
                  expenses[index] = {
                    'house': expenses[index]['house'],
                    'date': tempDateController.text,
                    'amount': tempAmountController.text.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    ),
                    'reason': tempReasonController.text,
                    'category': tempCategory,
                  };
                });
                Navigator.pop(context);
                _showMessage("Đã cập nhật!");
              },
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteExpense(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa khoản chi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                expenses.removeAt(index);
              });
              Navigator.pop(context);
              _showMessage("Đã xóa!");
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  String _formatCurrency(String amount) {
    try {
      final number = int.parse(amount.replaceAll(RegExp(r'[^0-9]'), ''));
      return '${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
    } catch (e) {
      return '0 đ';
    }
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
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // Hiển thị chọn nhà (Sheet)
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Tất cả các nhà'),
                        onTap: () {
                          setState(() {
                            selectedHouse = "Tất cả các nhà";
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('123 Nguyễn Đình Chiểu, P5, Q3'),
                        onTap: () {
                          setState(() {
                            selectedHouse = '123 Nguyễn Đình Chiểu, P5, Q3';
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('456 Lê Văn Sỹ, P13, Q3'),
                        onTap: () {
                          setState(() {
                            selectedHouse = '456 Lê Văn Sỹ, P13, Q3';
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
              child: fakeDropdown(selectedHouse),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Ngày chi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null)
                        setState(() {
                          dateController.text =
                              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                        });
                    },
                  ),
                ),
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
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else
                            const Expanded(
                              child: Text(
                                'Danh mục chi',
                                style: TextStyle(color: Colors.grey),
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
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền chi',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Lý do chi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
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
                        final category = expense['category'];
                        final actualIndex = expenses.indexOf(expense);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: category['color'].withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                category['icon'],
                                color: category['color'],
                              ),
                            ),
                            title: Text(
                              expense['reason'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${category['name']} • ${expense['date']}\n🏠 ${expense['house']}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatCurrency(expense['amount']),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Sửa'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Xóa',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                  onSelected: (val) => val == 'edit'
                                      ? _editExpense(actualIndex)
                                      : _deleteExpense(actualIndex),
                                ),
                              ],
                            ),
                          ),
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
