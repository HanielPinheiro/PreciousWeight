package precious_weight.services;

import org.eclipse.paho.client.mqttv3.*;
import org.springframework.stereotype.Service;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class MqttPublisherService {
    private static final Logger logger = LoggerFactory.getLogger(MqttPublisherService.class);

    private final IMqttAsyncClient mqttClient;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    public MqttPublisherService(IMqttAsyncClient mqttClient) {
        this.mqttClient = mqttClient;
    }

    public void sendCriticalCommand(String esp32Id, String command) {
        executor.submit(() -> {
            MqttMessage message = null;
            try {
                message = new MqttMessage(command.getBytes());
                message.setQos(2); // QoS 2 for medical commands
                mqttClient.publish("incubator/" + esp32Id + "/command", message).waitForCompletion(); // Block until confirmed
                logger.info("Sent QoS 2 command to ESP32 {}: {}", esp32Id, command);
            } catch (MqttException e) {
                logger.error("Failed to send command to ESP32 {}", esp32Id, e); // Error log
                try {
                    this.retryPublish("asd", message, 100);
                } catch (InterruptedException ex) {
                    logger.error("Critical Command Not Sent!", ex);
                }
            }
        });
    }

    // In MqttPublisher, add retry logic:
    private void retryPublish(String topic, MqttMessage message, int attempts) throws InterruptedException {
        try {
            logger.info("Retrying to send data to broker. Try {}: {} - {}", attempts, topic, message.toString());
            mqttClient.publish(topic, message).waitForCompletion();
        } catch (MqttException e) {
            if (attempts > 0) {
                Thread.sleep(1000);
                retryPublish(topic, message, attempts - 1);
            } else {
                logger.error("Permanent failure after retries: {}", topic, e);
            }
        }
    }
}
