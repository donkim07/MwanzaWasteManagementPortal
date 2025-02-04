import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VisualizationPage extends StatefulWidget {
  final User? user;

  const VisualizationPage({Key? key, required this.user}) : super(key: key);

  @override
  _VisualizationPageState createState() => _VisualizationPageState();
}

class _VisualizationPageState extends State<VisualizationPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  late TabController _tabController;
  
  // Data holders for charts
  Map<String, double> coverageData = {};
  Map<String, double> accessibilityData = {};
  Map<String, double> wasteCompositionData = {};
  Map<String, double> wasteSourcesData = {};
  Map<String, double> transportationData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final wasteDocs = await _firestore.collection('ilemelaWasteCollectionPoints').get();
      
      // Process data for each visualization
      _processWasteData(wasteDocs.docs);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processWasteData(List<QueryDocumentSnapshot> docs) {
    // Initialize counters
    Map<String, int> districtCounts = {};
    Map<String, int> accessibilityCounts = {};
    Map<String, double> compositionTotal = {};
    Map<String, int> sourceCounts = {};
    Map<String, int> transportCounts = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Process district coverage
      final district = data['location']?['district'];
      if (district != null) {
        districtCounts[district] = (districtCounts[district] ?? 0) + 1;
      }

      // Process accessibility
      final isAccessible = data['accessibility']?['isAccessible'] ?? false;
      accessibilityCounts[isAccessible ? 'Accessible' : 'Not Accessible'] = 
        (accessibilityCounts[isAccessible ? 'Accessible' : 'Not Accessible'] ?? 0) + 1;

      // Process waste composition
      final wasteTypes = data['wasteTypes'] as Map<String, dynamic>?;
      if (wasteTypes != null) {
        wasteTypes.forEach((type, percentage) {
          if (percentage is num) {
            compositionTotal[type] = (compositionTotal[type] ?? 0) + percentage;
          }
        });
      }

      // Process waste sources
      final sources = data['wasteSources']?['sources'] as List<dynamic>?;
      if (sources != null) {
        for (var source in sources) {
          sourceCounts[source.toString()] = (sourceCounts[source.toString()] ?? 0) + 1;
        }
      }

      // Process transportation
      final transport = data['transport']?['type'];
      if (transport != null) {
        transportCounts[transport.toString()] = (transportCounts[transport.toString()] ?? 0) + 1;
      }
    }

    // Convert counts to percentages
    setState(() {
      coverageData = _calculatePercentages(districtCounts);
      accessibilityData = _calculatePercentages(accessibilityCounts);
      wasteCompositionData = _normalizeComposition(compositionTotal);
      wasteSourcesData = _calculatePercentages(sourceCounts);
      transportationData = _calculatePercentages(transportCounts);
    });
  }

  Map<String, double> _calculatePercentages(Map<String, int> counts) {
    final total = counts.values.fold(0, (sum, count) => sum + count);
    return counts.map((key, value) => 
      MapEntry(key, (value / total) * 100));
  }

  Map<String, double> _normalizeComposition(Map<String, double> totals) {
    final total = totals.values.fold(0.0, (sum, value) => sum + value);
    return totals.map((key, value) => 
      MapEntry(key, (value / total) * 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: const Color(0xFF90EE90),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Coverage'),
            Tab(text: 'Accessibility'),
            Tab(text: 'Composition'),
            Tab(text: 'Sources'),
            Tab(text: 'Transportation'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCoverageChart(),
                _buildAccessibilityChart(),
                _buildCompositionChart(),
                _buildSourcesChart(),
                _buildTransportationChart(),
              ],
            ),
    );
  }

  Widget _buildCoverageChart() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'District Coverage',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Implement district names
                          return Text(coverageData.keys.elementAt(value.toInt()));
                        },
                      ),
                    ),
                  ),
                  barGroups: coverageData.entries
                      .map((entry) => BarChartGroupData(
                            x: coverageData.keys.toList().indexOf(entry.key),
                            barRods: [
                              BarChartRodData(
                                toY: entry.value,
                                color: Colors.greenAccent,
                                width: 20,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Similar implementations for other chart widgets...
  Widget _buildAccessibilityChart() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Accessibility Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                  sections: accessibilityData.entries.map((entry) {
                    return PieChartSectionData(
                      color: entry.key == 'Accessible' 
                          ? Colors.green.shade300 
                          : Colors.red.shade300,
                      value: entry.value,
                      title: '${entry.key}\n${entry.value.toStringAsFixed(1)}%',
                      radius: 150,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Continue with similar chart implementations for composition, sources, and transportation
  Widget _buildCompositionChart() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Waste Composition',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: wasteCompositionData.entries.map((entry) {
                    final index = wasteCompositionData.keys.toList().indexOf(entry.key);
                    final colors = [
                      Colors.green,
                      Colors.blue,
                      Colors.orange,
                      Colors.purple,
                      Colors.red,
                      Colors.yellow,
                      Colors.teal,
                    ];
                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: entry.value,
                      title: '${entry.key}\n${entry.value.toStringAsFixed(1)}%',
                      radius: 120,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourcesChart() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Waste Sources',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                wasteSourcesData.keys.elementAt(value.toInt()),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: wasteSourcesData.entries
                      .map((entry) => BarChartGroupData(
                            x: wasteSourcesData.keys.toList().indexOf(entry.key),
                            barRods: [
                              BarChartRodData(
                                toY: entry.value,
                                color: Colors.blueAccent,
                                width: 20,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildTransportationChart() {
  return Card(
    margin: const EdgeInsets.all(16),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Transportation Methods',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.circle,
                dataSets: [
                  RadarDataSet(
                    fillColor: Colors.blue.withOpacity(0.2),
                    borderColor: Colors.blue,
                    entryRadius: 2,
                    dataEntries: transportationData.entries
                        .map((entry) => RadarEntry(value: entry.value))
                        .toList(),
                  ),
                ],
                radarTouchData: RadarTouchData(
                  touchCallback: (FlTouchEvent event, response) {},
                ),
                getTitle: (index, angle) => RadarChartTitle(
                  text: transportationData.keys.elementAt(index),
                  angle: angle,
                ),
                titleTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                ),
                tickCount: 5,
                ticksTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                ),
                gridBorderData: BorderSide(
                  color: Colors.black26,
                  width: 2,
                ),
                tickBorderData: const BorderSide(
                  color: Colors.black26,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}