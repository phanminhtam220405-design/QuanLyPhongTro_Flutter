import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  List<double> monthlyIncome = List.filled(12, 0.0);
  List<double> monthlyExpense = List.filled(12, 0.0);
  bool isLoading = true;
  int selectedFilter = 12; 
  
  String selectedHouseId = 'all';
  List<Map<String, dynamic>> housesList = [];

  @override
  void initState() {
    super.initState();
    _fetchHousesAndData();
  }

  String formatVND(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }

  Future<void> _fetchHousesAndData() async {
    try {
      var hSnap = await FirebaseFirestore.instance.collection('houses').where('userId', isEqualTo: uid).get();
      housesList = hSnap.docs.map((d) => {'id': d.id, 'name': d['name'], 'address': d['address']}).toList();
      _fetchAndCalculateData();
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAndCalculateData() async {
    try {
      var billsSnapshot = await FirebaseFirestore.instance.collection('bills').where('userId', isEqualTo: uid).get();
      var expensesSnapshot = await FirebaseFirestore.instance.collection('expenses').where('userId', isEqualTo: uid).get();

      List<double> mIncome = List.filled(12, 0.0);
      List<double> mExpense = List.filled(12, 0.0);
      int currentYear = DateTime.now().year;

      for (var doc in billsSnapshot.docs) {
        var data = doc.data();
        
        if (selectedHouseId != 'all' && data['houseId'] != selectedHouseId) continue;

        String status = data['status'] ?? '';
        if (status == 'Đã đóng' || status == 'Đóng một phần') {
          double amount = 0;
          if (status == 'Đã đóng') {
            amount = double.tryParse(data['totalAmount'].toString()) ?? 0;
          } else {
            amount = double.tryParse(data['paidAmount'].toString()) ?? 0;
          }

          if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
            DateTime date = (data['createdAt'] as Timestamp).toDate();
            if (date.year == currentYear) {
              mIncome[date.month - 1] += amount;
            }
          }
        }
      }

      for (var doc in expensesSnapshot.docs) {
        var data = doc.data();
        
        if (selectedHouseId != 'all') {
          var hList = housesList.where((element) => element['id'] == selectedHouseId).toList();
          if (hList.isEmpty) continue;
          
          var h = hList.first;
          String expHouse = data['house_id']?.toString() ?? '';
          String hName = h['name']?.toString() ?? "Không tên";
          String hAddr = h['address']?.toString() ?? "";
          String expectedHouseStr = hAddr.isNotEmpty ? "$hName - $hAddr" : hName;
          
          if (expHouse != expectedHouseStr) {
            continue;
          }
        }

        double amount = double.tryParse(data['amount'].toString()) ?? 0;
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          DateTime date = (data['createdAt'] as Timestamp).toDate();
          if (date.year == currentYear) {
            mExpense[date.month - 1] += amount;
          }
        }
      }

      if (mounted) {
        setState(() {
          monthlyIncome = mIncome;
          monthlyExpense = mExpense;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentMonth = DateTime.now().month;
    int startMonth = 1;
    int endMonth = 12;

    if (selectedFilter != 12) {
      startMonth = currentMonth - selectedFilter + 1;
      if (startMonth < 1) startMonth = 1;
      endMonth = currentMonth;
    }

    double displayIncome = 0;
    double displayExpense = 0;
    for (int i = startMonth; i <= endMonth; i++) {
      displayIncome += monthlyIncome[i - 1];
      displayExpense += monthlyExpense[i - 1];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white, title: const Text("Báo cáo & Thống kê")),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButton<String>(
                    value: selectedHouseId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text("Tất cả các nhà", style: TextStyle(fontWeight: FontWeight.w500))),
                      ...housesList.map((h) => DropdownMenuItem(value: h['id'], child: Text("${h['name']} - ${h['address']}", overflow: TextOverflow.ellipsis)))
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() { selectedHouseId = val; isLoading = true; });
                        _fetchAndCalculateData();
                      }
                    }
                  )
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _filterButton("3 tháng", 3),
                    _filterButton("6 tháng", 6),
                    _filterButton("12 tháng", 12),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSummaryCards(displayIncome, displayExpense),
                const SizedBox(height: 25),
                Text("Biểu đồ Thu - Chi ($selectedFilter tháng qua)", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildChart(startMonth, endMonth),
              ],
            ),
          ),
    );
  }

  Widget _filterButton(String label, int value) {
    bool isActive = selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() { selectedFilter = value; });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1976D2) : Colors.white,
          border: Border.all(color: isActive ? const Color(0xFF1976D2) : Colors.blue.shade200),
          borderRadius: BorderRadius.circular(5)
        ),
        child: Text(
          label, 
          style: TextStyle(color: isActive ? Colors.white : Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double totalInc, double totalExp) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _reportCard("TỔNG THU", totalInc, Colors.green, Icons.arrow_upward)),
            const SizedBox(width: 10),
            Expanded(child: _reportCard("TỔNG CHI", totalExp, Colors.red, Icons.arrow_downward)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: _reportCard("LỢI NHUẬN RÒNG", totalInc - totalExp, Colors.blue, Icons.account_balance_wallet, isBig: true))
      ],
    );
  }

  Widget _reportCard(String title, double value, Color color, IconData icon, {bool isBig = false}) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: color, size: isBig ? 24 : 18), const SizedBox(width: 5), Text(title, style: TextStyle(color: Colors.grey[700], fontSize: isBig ? 14 : 12, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 10),
            Text(formatVND(value), style: TextStyle(fontSize: isBig ? 24 : 16, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(int startMonth, int endMonth) {
    return Container(
      height: 300, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(startMonth, endMonth),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('T${value.toInt() + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))))),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: () {
            List<BarChartGroupData> groups = [];
            for (int i = startMonth; i <= endMonth; i++) {
              int index = i - 1;
              groups.add(
                BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(toY: monthlyIncome[index], color: Colors.green, width: selectedFilter <= 6 ? 16 : 8, borderRadius: BorderRadius.circular(2)),
                    BarChartRodData(toY: monthlyExpense[index], color: Colors.red, width: selectedFilter <= 6 ? 16 : 8, borderRadius: BorderRadius.circular(2)),
                  ],
                )
              );
            }
            return groups;
          }(),
        ),
      ),
    );
  }

  double _getMaxY(int startMonth, int endMonth) {
    double maxVal = 100000; 
    for(int i = startMonth; i <= endMonth; i++) {
      if (monthlyIncome[i - 1] > maxVal) maxVal = monthlyIncome[i - 1];
      if (monthlyExpense[i - 1] > maxVal) maxVal = monthlyExpense[i - 1];
    }
    return maxVal * 1.2; 
  }
}