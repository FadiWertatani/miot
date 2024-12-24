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
    _databaseReference.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;

      if (data is Map) {
        // Clear the lists for new data
        List<FlSpot> newBodyTempData = [];
        List<FlSpot> newAmbientTempData = [];
        List<FlSpot> newMovementData = [];

        data.forEach((key, value) {
          // Ensure the value is a Map and contains the necessary keys
          if (value is Map) {
            final bodyTemp = double.tryParse(value['BodyTemp']?.toString() ?? '0') ?? 0.0;
            final ambientTemp = double.tryParse(value['AmbientTemp']?.toString() ?? '0') ?? 0.0;
            final movement = (value['Movement'] == 'Yes') ? 1.0 : 0.0;

            // Filter data based on thresholds
            if (bodyTemp >= _bodyTempThreshold) {
              newBodyTempData.add(FlSpot(_xIndex.toDouble(), bodyTemp));
            }
            if (ambientTemp >= _ambientTempThreshold) {
              newAmbientTempData.add(FlSpot(_xIndex.toDouble(), ambientTemp));
            }
            if (movement >= _movementThreshold) {
              newMovementData.add(FlSpot(_xIndex.toDouble(), movement));
            }
            _xIndex++;
          }
        });

        setState(() {
          bodyTempData = newBodyTempData;
          ambientTempData = newAmbientTempData;
          movementData = newMovementData;
        });
      } else {
        print('Data format is not a Map: $data');
      }
    });
  }

  // Update threshold values
  void _updateThresholds() {
    setState(() {
      _bodyTempThreshold = double.tryParse(_bodyTempThresholdController.text) ?? 0.0;
      _ambientTempThreshold = double.tryParse(_ambientTempThresholdController.text) ?? 0.0;
      _movementThreshold = double.tryParse(_movementThresholdController.text) ?? 0.0;
    });
    _fetchData(); // Re-fetch the data with updated thresholds
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
                child: _buildChart(bodyTempData, 'Body Temperature', Colors.blue),
              ),
              SizedBox(height: 8),
              _buildThresholdInputField("Ambient Temperature Threshold", _ambientTempThresholdController),
              SizedBox(height: 8),
              ElevatedButton(onPressed: _updateThresholds, child: Text("Update Thresholds")),

              Container(
                height: 200,
                child: _buildChart(ambientTempData, 'Ambient Temperature', Colors.orange),
              ),
              SizedBox(height: 8),
              _buildThresholdInputField("Movement Threshold", _movementThresholdController),
              SizedBox(height: 8),
              ElevatedButton(onPressed: _updateThresholds, child: Text("Update Thresholds")),
              Container(
                height: 200,
                child: Card(
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Movement",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(List<FlSpot> data, String title, Color color) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
