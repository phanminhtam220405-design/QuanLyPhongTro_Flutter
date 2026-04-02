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
  double totalIncome = 0;
  double totalExpense = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateData();
  }

  Future<void> _fetchAndCalculateData() async {
    try {
      var billsSnapshot = await FirebaseFirestore.instance.collection('bills').where('userId', isEqualTo: uid).get();
      var expensesSnapshot = await FirebaseFirestore.instance.collection('expenses').where('userId', isEqualTo: uid).get();

      double tIncome = 0;
      double tExpense = 0;
      List<double> mIncome = List.filled(12, 0.0);
      List<double> mExpense = List.filled(12, 0.0);

      // Cộng dồn hóa đơn
      for (var doc in billsSnapshot.docs) {
        var data = doc.data();
        double amount = double.tryParse(data['totalAmount'].toString()) ?? 0;
        tIncome += amount;
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          DateTime date = (data['createdAt'] as Timestamp).toDate();
          mIncome[date.month - 1] += amount;
        }
      }

      // Cộng dồn chi phí
      for (var doc in expensesSnapshot.docs) {
        var data = doc.data();
        double amount = double.tryParse(data['amount'].toString()) ?? 0;
        tExpense += amount;
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          DateTime date = (data['createdAt'] as Timestamp).toDate();
          mExpense[date.month - 1] += amount;
        }
      }

      if (mounted) {
        setState(() {
          totalIncome = tIncome;
          totalExpense = tExpense;
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
                _buildSummaryCards(),
                const SizedBox(height: 25),
                const Text("Biểu đồ Thu - Chi năm nay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildChart(),
              ],
            ),
          ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _reportCard("TỔNG THU", totalIncome, Colors.green, Icons.arrow_upward)),
            const SizedBox(width: 10),
            Expanded(child: _reportCard("TỔNG CHI", totalExpense, Colors.red, Icons.arrow_downward)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: _reportCard("LỢI NHUẬN RÒNG", totalIncome - totalExpense, Colors.blue, Icons.account_balance_wallet, isBig: true))
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
            Text("${(value / 1000).toStringAsFixed(0)}K", style: TextStyle(fontSize: isBig ? 28 : 20, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 300, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('T${value.toInt() + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))))),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(12, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(toY: monthlyIncome[index], color: Colors.green, width: 8, borderRadius: BorderRadius.circular(2)),
                BarChartRodData(toY: monthlyExpense[index], color: Colors.red, width: 8, borderRadius: BorderRadius.circular(2)),
              ],
            );
          }),
        ),
      ),
    );
  }

  double _getMaxY() {
    double maxVal = 100000;
    for(int i=0; i<12; i++) {
      if (monthlyIncome[i] > maxVal) maxVal = monthlyIncome[i];
      if (monthlyExpense[i] > maxVal) maxVal = monthlyExpense[i];
    }
    return maxVal * 1.2;
  }
}