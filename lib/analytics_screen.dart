import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final res = await http.get(
        Uri.parse('https://ubuntu-4gb-hel1-2.tail7f4de4.ts.net:10000/api/stats/analytics'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _data = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value == ThemeMode.dark;
    final bgColor = isDark ? const Color(0xFF080d14) : const Color(0xFFf8fafc);
    final cardBg = isDark ? const Color(0xFF141b28) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0f172a);
    final accent = isDark ? const Color(0xFF00d9ff) : const Color(0xFF0891b2);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 1,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: accent), onPressed: () => Navigator.pop(context)),
        title: Text(AppTranslations.t('analytics.title'), style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPeriodCard("1D", _data['daily'] ?? {}, cardBg, textColor, accent),
                const SizedBox(height: 12),
                _buildPeriodCard("1W", _data['weekly'] ?? {}, cardBg, textColor, accent),
                const SizedBox(height: 12),
                _buildPeriodCard("1M", _data['monthly'] ?? {}, cardBg, textColor, accent),
                const SizedBox(height: 12),
                _buildPeriodCard("1Y", _data['yearly'] ?? {}, cardBg, textColor, accent),
              ],
            ),
    );
  }

  Widget _buildPeriodCard(String title, Map<String, dynamic> metrics, Color cardBg, Color textColor, Color accent) {
    // القيم قد تكون مفقودة أو null، نستخدم 0.0 كافتراضي
    final double pnl = (metrics['period_profit'] as num? ?? 0.0).toDouble();
    final int trades = (metrics['total_trades'] as num? ?? 0).toInt();
    final double winRate = (metrics['win_rate'] as num? ?? 0.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: textColor.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppTranslations.t('analytics.pnl'), style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11)),
                Text('\$${pnl.toStringAsFixed(2)}', style: TextStyle(color: pnl >= 0 ? const Color(0xFF10b981) : const Color(0xFFef4444), fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppTranslations.t('analytics.trades'), style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11)),
                Text('$trades', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppTranslations.t('analytics.win_rate'), style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11)),
                Text('${winRate.toStringAsFixed(1)}%', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}
