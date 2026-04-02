import 'package:flutter/material.dart';

// Dialogs liên quan đến quản lý chi tiêu
class ExpenseDialogs {
  // Dialog để chọn danh mục chi tiêu
  static void showCategorySelector(
    BuildContext context,
    List<Map<String, dynamic>> categories,
    Map<String, dynamic>? selectedCategory,
    Function(Map<String, dynamic>) onCategorySelected,
  ) {
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
                      onCategorySelected(category);
                      Navigator.pop(modalContext);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: (category['color'] as Color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedCategory == category
                                  ? (category['color'] as Color)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            category['icon'] as IconData,
                            size: 30,
                            color: category['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

  // Dialog để chọn căn nhà khi lọc chi tiêu
  static void showHouseSelector(
    BuildContext context,
    String selectedHouse,
    Function(String) onHouseSelected,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home_work, color: Color(0xFF1976D2)),
              title: const Text(
                'Tất cả các nhà',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: selectedHouse == 'Tất cả các nhà'
                  ? const Icon(Icons.check, color: Color(0xFF1976D2))
                  : null,
              onTap: () {
                onHouseSelected('Tất cả các nhà');
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('123 Nguyễn Đình Chiểu, P5, Q3'),
              trailing: selectedHouse == '123 Nguyễn Đình Chiểu, P5, Q3'
                  ? const Icon(Icons.check, color: Color(0xFF1976D2))
                  : null,
              onTap: () {
                onHouseSelected('123 Nguyễn Đình Chiểu, P5, Q3');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('456 Lê Văn Sỹ, P13, Q3'),
              trailing: selectedHouse == '456 Lê Văn Sỹ, P13, Q3'
                  ? const Icon(Icons.check, color: Color(0xFF1976D2))
                  : null,
              onTap: () {
                onHouseSelected('456 Lê Văn Sỹ, P13, Q3');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Dialog sửa khoản chi
  static void showEditExpenseDialog(
    BuildContext context,
    Map<String, dynamic> expense,
    List<Map<String, dynamic>> categories,
    Function(Map<String, dynamic> updatedExpense) onSave,
  ) {
    final tempDateController = TextEditingController(text: expense['date']);
    final tempAmountController = TextEditingController(text: expense['amount']);
    final tempReasonController = TextEditingController(text: expense['reason']);
    Map<String, dynamic>? tempCategory = expense['category'];

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
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setDialogState(() {
                        tempDateController.text =
                            '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (innerContext) => Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Chọn danh mục',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: categories
                                  .map(
                                    (cat) => GestureDetector(
                                      onTap: () {
                                        setDialogState(() {
                                          tempCategory = cat;
                                        });
                                        Navigator.pop(innerContext);
                                      },
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: (cat['color'] as Color).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: tempCategory == cat
                                                    ? (cat['color'] as Color)
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              cat['icon'] as IconData,
                                              color: cat['color'] as Color,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            cat['name'] as String,
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    );
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
                            tempCategory!['icon'] as IconData,
                            color: tempCategory!['color'] as Color,
                          ),
                          const SizedBox(width: 10),
                          Text(tempCategory!['name'] as String),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
              onPressed: () {
                if (tempCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn danh mục!')),
                  );
                  return;
                }
                onSave({
                  'house': expense['house'],
                  'date': tempDateController.text,
                  'amount': tempAmountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                  'reason': tempReasonController.text,
                  'category': tempCategory,
                });
                Navigator.pop(context);
              },
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog xác nhận xóa khoản chi
  static void showDeleteConfirmation(
    BuildContext context,
    Function() onConfirm,
  ) {
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
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
