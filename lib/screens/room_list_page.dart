import 'package:flutter/material.dart';

class RoomListScreen extends StatelessWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1976D2),
          title: const Text("Danh sách phòng", style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.home, color: Colors.white)),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white), onPressed: () {}),
          ],
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: "Phòng trống"), Tab(text: "Phòng đã thuê")],
          ),
        ),
        body: const TabBarView(children: [RoomEmptyTab(), RoomRentedTab()]),
      ),
    );
  }
}

class RoomEmptyTab extends StatelessWidget {
  const RoomEmptyTab({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      roomCard(roomName: "P.102", isRented: false, price: "3.000.000 đ/tháng"),
    ]);
  }
}

class RoomRentedTab extends StatelessWidget {
  const RoomRentedTab({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      roomCard(roomName: "P.101", isRented: true, price: "3.500.000 đ/tháng"),
      roomCard(roomName: "P.103", isRented: true, price: "3.500.000 đ/tháng"),
    ]);
  }
}

Widget roomCard({required String roomName, required bool isRented, required String price}) {
  final statusText = isRented ? "Đang thuê" : "Đang trống";
  final statusColor = isRented ? Colors.green : Colors.red;

  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 3,
    margin: const EdgeInsets.only(bottom: 15),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(roomName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.circle, size: 10, color: statusColor), const SizedBox(width: 5), Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold))]),
                    Text(price),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.close, color: Colors.blue), onPressed: () {}),
                ],
              )
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: statusColor),
              onPressed: () {},
              child: Text(isRented ? "Xem hợp đồng" : "Tạo hợp đồng", style: const TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    ),
  );
}