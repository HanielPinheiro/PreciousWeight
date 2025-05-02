package precious_weight.services;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import org.eclipse.paho.client.mqttv3.*;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import precious_weight.interfaces.iScale;
import precious_weight.models.ScaleModel;

@Service
public class MqttSubscriberService {
    private static final Logger logger = LoggerFactory.getLogger(MqttSubscriberService.class);
    @Autowired
    private IMqttAsyncClient mqttClient;
    @Autowired
    private iScale iScale;

    @PostConstruct
    public void startMonitoring() throws MqttException {
        String topic = "test"; // Use the exact topic you're publishing to
        int qos = 1;

        logger.info("Attempting to subscribe to topic: {}", topic);

        mqttClient.subscribe(topic, qos, (messageTopic, message) -> {
            String payload = new String(message.getPayload());
            logger.info("Received message - Topic: {} | Payload: {}", messageTopic, payload);

            // Add your message processing logic here
        });

        logger.info("Subscription request sent for topic: {}", topic);
    }

    @Scheduled(fixedRate = 300000) // Every 5 minutes
    public void logHeartbeat() {
        logger.info("MQTT subscriber is alive");
    }
}
