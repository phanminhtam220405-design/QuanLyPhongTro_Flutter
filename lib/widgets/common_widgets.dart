import 'package:flutter/material.dart';

// Thay thế fakeDropdown bằng một Container đơn giản
Widget fakeDropdown(String title) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(title), const Icon(Icons.arrow_drop_down)],
    ),
  );
}

Widget fakeInput(String label, String hint) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade400),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(
          hint.isEmpty ? "..." : hint,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class EmptyDataWidget extends StatelessWidget {
  const EmptyDataWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.face, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "Chưa có dữ liệu!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
