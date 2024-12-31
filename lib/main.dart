import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SensorDataCharts(),
    );
  }
}

class SensorDataCharts extends StatefulWidget {
  @override
  _SensorDataChartsState createState() => _SensorDataChartsState();
}

class _SensorDataChartsState extends State<SensorDataCharts> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref('sensors');
  List<FlSpot> bodyTempData = [];
  List<FlSpot> ambientTempData = [];
  List<FlSpot> movementData = [];
  int _xIndex = 0;

  // Controllers for threshold input fields
  TextEditingController _bodyTempThresholdController = TextEditingController();
  TextEditingController _ambientTempThresholdController = TextEditingController();
  TextEditingController _movementThresholdController = TextEditingController();

  // Default threshold values
  double _bodyTempThreshold = 0.0;
  double _ambientTempThreshold = 0.0;
  double _movementThreshold = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _databaseReference.orderByKey().limitToLast(1).onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;

      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            final bodyTemp = double.tryParse(value['BodyTemp']?.toString() ?? '0') ?? 0.0;
            final ambientTemp = double.tryParse(value['AmbientTemp']?.toString() ?? '0') ?? 0.0;
            final movement = (value['Movement'] == 'Yes') ? 1.0 : 0.0;

            setState(() {
              bodyTempData.add(FlSpot(_xIndex.toDouble(), bodyTemp));
              ambientTempData.add(FlSpot(_xIndex.toDouble(), ambientTemp));
              movementData.add(FlSpot(_xIndex.toDouble(), movement));
              _xIndex++;
            });
          }
        });
      } else {
        print('Data format is not a Map: $data');
      }
    });
  }



  // Update threshold values
  void _updateThresholds() async {
    setState(() {
      _bodyTempThreshold = double.tryParse(_bodyTempThresholdController.text) ?? 0.0;
      _ambientTempThreshold = double.tryParse(_ambientTempThresholdController.text) ?? 0.0;
      _movementThreshold = double.tryParse(_movementThresholdController.text) ?? 0.0;
    });

    // Save thresholds to Firestore
    try {
      await FirebaseFirestore.instance.collection('thresholds').doc('sensorData').set({
        'bodyTempThreshold': _bodyTempThreshold,
        'ambientTempThreshold': _ambientTempThreshold,
        'movementThreshold': _movementThreshold,
      });

      print('Thresholds successfully saved to Firestore.');
    } catch (e) {
      print('Error saving thresholds to Firestore: $e');
    }

    // Re-fetch the data with updated thresholds
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor Data Charts'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildThresholdInputField("Body Temperature Threshold", _bodyTempThresholdController),
              SizedBox(height: 8),
              ElevatedButton(onPressed: _updateThresholds, child: Text("Update Thresholds")),
              Container(
                height: 200,
                child: _buildChart(bodyTempData, 'Body Temperature', Colors.blue, _bodyTempThreshold),
              ),
              SizedBox(height: 8),
              _buildThresholdInputField("Ambient Temperature Threshold", _ambientTempThresholdController),
              SizedBox(height: 8),
              ElevatedButton(onPressed: _updateThresholds, child: Text("Update Thresholds")),
              Container(
                height: 200,
                child: _buildChart(ambientTempData, 'Ambient Temperature', Colors.orange, _ambientTempThreshold),
              ),
              SizedBox(height: 8),
              _buildThresholdInputField("Movement Threshold", _movementThresholdController),
              SizedBox(height: 8),
              ElevatedButton(onPressed: _updateThresholds, child: Text("Update Thresholds")),
              Container(
                height: 200,
                child: _movementBuildChart(movementData, "Movement", Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(List<FlSpot> data, String title, Color color, double threshold) {
    bool isAboveThreshold = data.isNotEmpty && data.last.y > threshold;

    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: isAboveThreshold ? Colors.red : Colors.green,
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: SideTitles(showTitles: true),
                    bottomTitles: SideTitles(showTitles: false),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: true,
                      colors: [color],
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _movementBuildChart(List<FlSpot> data, String title, Color color) {
    double threshold = 1.0;
    bool isAboveThreshold = data.isNotEmpty && data.last.y == threshold;
    print(data.last.y);

    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Movement",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: isAboveThreshold ? Colors.red : Colors.green,
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: SideTitles(showTitles: true),
                    bottomTitles: SideTitles(showTitles: false),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: movementData,
                      isCurved: true,
                      colors: [Colors.green],
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildThresholdInputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}
