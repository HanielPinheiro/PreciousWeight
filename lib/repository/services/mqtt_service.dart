// import 'dart:async';
// import 'dart:io';
// import 'package:mqtt_client/mqtt_client.dart';
// import 'package:mqtt_client/mqtt_server_client.dart';
//
// class MqttService {
//   int _pongCount = 0;
//   int _pingCount = 0;
//   bool hasErrors = false;
//   String errorMessage = '';
//   bool isConnected = false;
//   bool isListen = false;
//   late final client;
//   static const url = '192.168.0.10';
//   static const identifier = "MyApp";
//   static const topic = "test";
//   static const pubTopic = 'test';
//   static const port = 5278;
//
//   MqttService() {
//     client = MqttServerClient(url, identifier);
//     client.port = port;
//     client.logging(on: true);
//     client.setProtocolV311();
//
//     /// Set the correct MQTT protocol for mosquito
//     client.keepAlivePeriod = 20;
//
//     /// If you intend to use a keep alive you must set it here otherwise keep alive will be disabled.
//     client.onConnected = onConnected;
//     client.onDisconnected = onDisconnected;
//     client.onSubscribed = onSubscribed;
//     client.pongCallback = pong;
//     client.pingCallback = ping;
//
//     client.connectionMessage = MqttConnectMessage()
//         .withClientIdentifier(identifier)
//         .withWillTopic(topic) // If you set this you must set a will message
//         .withWillMessage('My App is speaking')
//         .withWillQos(MqttQos.atLeastOnce);
//   }
//
//   void onConnected() {
//     isConnected = true;
//   }
//
//   void onDisconnected() {
//     if (client.connectionStatus!.disconnectionOrigin == MqttDisconnectionOrigin.solicited)
//       isConnected = false;
//     else {
//       hasErrors = true;
//       errorMessage = 'Disconnected callback is unsolicited or none, this is incorrect - exiting';
//       exit(-1);
//     }
//   }
//
//   void onSubscribed(String topic) {
//     print('EXAMPLE::Subscription confirmed for topic $topic');
//   }
//
//   void pong() {
//     _pongCount++;
//   }
//
//   void ping() {
//     _pingCount++;
//   }
//
//   Future<void> close() async {
//     client.unsubscribe(topic);
//     await MqttUtilities.asyncSleep(2);
//     client.disconnect();
//   }
//
//   Future<void> start() async {
//     /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
//     /// in some circumstances the broker will just disconnect us, see the spec about this, we however will
//     /// never send malformed messages.
//     try {
//       await client.connect();
//     } on NoConnectionException catch (e) { // Raised by the client when connection fails.
//       hasErrors = true;
//       errorMessage = 'Client exception - $e';
//       client.disconnect();
//     } on SocketException catch (e) {
//       hasErrors = true;
//       errorMessage = 'Socket exception - $e';
//       client.disconnect();
//     } on Exception catch (e) {
//       hasErrors = true;
//       errorMessage = 'Non treated exception - $e';
//       client.disconnect();
//     }
//
//     if (client.connectionStatus!.state == MqttConnectionState.connected)
//       print('EXAMPLE::Mosquitto client connected');
//     else {
//       hasErrors = true;
//       errorMessage = 'ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}';
//       client.disconnect();
//       exit(-1);
//     }
//
//     client.subscribe(topic, MqttQos.atMostOnce);
//
//     client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
//       final recMess = c![0].payload as MqttPublishMessage;
//       final pt = MqttPublishPayload.bytesToStringAsString(
//         recMess.payload.message,
//       );
//
//       /// The payload is a byte buffer, this will be specific to the topic
//       print(
//         'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->',
//       );
//       print('');
//     });
//
//     /// If needed you can listen for published messages that have completed the publishing
//     /// handshake which is Qos dependant. Any message received on this stream has completed its
//     /// publishing handshake with the broker.
//     client.published!.listen((MqttPublishMessage message) {
//       print(
//         'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}',
//       );
//     });
//
//     /// Lets publish to our topic
//     /// Use the payload builder rather than a raw buffer Our known topic to publish to
//     final builder = MqttClientPayloadBuilder();
//     builder.addString('Hello from mqtt_client');
//     client.subscribe(pubTopic, MqttQos.exactlyOnce);
//     client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
//
//
//     // await MqttUtilities.asyncSleep(60);
//     //
//     //
//     // /// Finally, unsubscribe and exit gracefully
//     // client.unsubscribe(topic);
//     // await MqttUtilities.asyncSleep(2);
//     // client.disconnect();
//     // return 0;
//   }
// }
