import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

void main() {
  runApp(const BLEApp());
}

class BLEApp extends StatelessWidget {
  const BLEApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 BLE',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BLEScreen(),
    );
  }
}

class BLEScreen extends StatefulWidget {
  const BLEScreen({Key? key}) : super(key: key);

  @override
  State<BLEScreen> createState() => _BLEScreenState();
}

class _BLEScreenState extends State<BLEScreen> {
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  bool isScanning = false;
  String SERVICE_UUID = "0daab708-9d00-4d6a-bc2a-578c1ae72c93";
  String CHARACTERISTIC_UUID = "2cad5999-443c-4448-900e-ddefa912d5a0";

  void startScan() async {
    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
        isScanning = false;
      });
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning) {
        setState(() => isScanning = false);
      }
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    await device.connect();
    setState(() => connectedDevice = device);

    // Discover services and characteristics
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == SERVICE_UUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            setState(() => targetCharacteristic = characteristic);
          }
          else if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {

          }
        }
        print('Device was found');
        break;
      }
    }
  }

  Future<void> sendText(String text) async {
    if (targetCharacteristic != null) {
      final NetworkInfo _networkInfo = NetworkInfo();
      String? ssid = await _networkInfo.getWifiName();

      final key = encrypt.Key.fromLength(32); // 32 bytes key
      final iv = encrypt.IV.fromLength(16);   // 16 bytes initialization vector
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypter.encrypt(json.encode({'ssid': ssid!, 'password': text}), iv: iv);

      List<int> bytes = utf8.encode(encrypted.base64);
      await targetCharacteristic!.write(bytes);
    }
  }

  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ESP32 BLE")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isScanning ? null : startScan,
            child: Text(isScanning ? "Scanning..." : "Start Scan"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                return ListTile(
                  title: Text(result.advertisementData.advName.isNotEmpty ? result.advertisementData.advName : "Unknown Device"),
                  subtitle: Text("ID: ${result.device.remoteId}"),
                  trailing: ElevatedButton(
                    onPressed: () => connectToDevice(result.device),
                    child: const Text("Connect"),
                  ),
                );
              },
            ),
          ),
          if (connectedDevice != null) ...[
            const Divider(),
            Text("Connected to: ${connectedDevice!.remoteId}", style: const TextStyle(fontSize: 16)),
            ListTile(
              title: TextField(
                controller: textController, // Add controller
                decoration: const InputDecoration(labelText: "Insert the Wi-Fi password"),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  String textToSend = textController.text; // Get the text from the TextField
                  sendText(textToSend); // Call the sendText function
                },
                child: const Text("Send"),
              ),
            )
          ],
        ],
      ),
    );
  }
}