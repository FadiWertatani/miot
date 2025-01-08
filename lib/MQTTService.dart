import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  late MqttServerClient _client;

  Future<void> connect() async {
    // Replace with your MQTT broker details
    const String broker = 'broker.emqx.io';
    const int port = 1883; // Default MQTT port
    const String clientId = 'flutter_client';

    _client = MqttServerClient(broker, clientId);
    _client.port = port;
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = _onDisconnected;

    try {
      await _client.connect();
      print('Connected to MQTT broker.');
    } catch (e) {
      print('Failed to connect to MQTT broker: $e');
      _client.disconnect();
    }
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker.');
  }

  Future<void> sendMessage(String topic, String message) async {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    try {
      _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('Message sent: $message');
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  void disconnect() {
    _client.disconnect();
  }
}
