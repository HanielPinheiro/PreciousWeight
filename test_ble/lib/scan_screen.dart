import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  void startScan() async {
    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    // Start scanning
    await FlutterBluePlus.startScan( withServices: [], // Remove service filter
                                      timeout: Duration(seconds: 20));

    FlutterBluePlus.isScanning.listen((val) {
      if (!val) {
        print('acabou');

        var scanSubscription = FlutterBluePlus.scanResults.listen((results) {
          print('scanResults');
          print(results);
          setState(() {
            isScanning = false;
            scanResults = results;
          });
        }, onError: (e) => print(e));

        FlutterBluePlus.cancelWhenScanComplete(scanSubscription);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Bluetooth Devices")),
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
                  trailing: Text("RSSI: ${result.rssi}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
