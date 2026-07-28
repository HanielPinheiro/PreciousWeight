package precious_weight.auth.services;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import org.eclipse.paho.client.mqttv3.*;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import precious_weight.app.services.ScaleService;

import static precious_weight.config.system.MqttConstants.MQTT_TOPIC_SUB_SCALE;
import static precious_weight.config.system.MqttConstants.MQTT_TOPIC_SUB_STATUS;
import static precious_weight.config.system.MqttConstants.MQTT_TOPIC_SUB_WEIGHT;

@Service
public class MqttSubscriberService {
    private static final Logger logger = LoggerFactory.getLogger(MqttSubscriberService.class);

    @Autowired
    private IMqttAsyncClient mqttClient;

    @Autowired
    private ScaleService scaleService;

    @PostConstruct
    public void startMonitoring() throws MqttException {
        int qos = 2;
        logger.info("Attempting to subscribe to topic: {}", MQTT_TOPIC_SUB_SCALE);
        mqttClient.subscribe(MQTT_TOPIC_SUB_SCALE, qos, (messageTopic, message) -> {
            String payload = new String(message.getPayload());
            try {
                boolean saved = scaleService.SaveWifiStrengthFromScale(messageTopic.replace("/scales/", ""), payload);
                log(messageTopic, payload);
                if (saved) logger.info("WiFi strength saved in topic: {}", messageTopic);
            } catch (Exception e) {
                logger.error("Error when try to save wifi strength - Topic: {} | Payload: {} - Error: {}", messageTopic, payload, e.getMessage(), e);
            }
        });
        logger.info("Subscription request sent for topic: {}", MQTT_TOPIC_SUB_SCALE);

        logger.info("Attempting to subscribe to topic: {}", MQTT_TOPIC_SUB_STATUS);
        mqttClient.subscribe(MQTT_TOPIC_SUB_STATUS, qos, (messageTopic, message) -> {
            String payload = new String(message.getPayload());
            String scaleMac = messageTopic.replace("/status/", "");

            if ("CONNECTED".equalsIgnoreCase(payload)) {
                scaleService.UpdateConnectionStatusFromBroker(scaleMac, true);
                log(messageTopic, payload);
                return;
            }

            if ("DISCONNECTED".equalsIgnoreCase(payload)) {
                scaleService.UpdateConnectionStatusFromBroker(scaleMac, false);
                log(messageTopic, payload);
                return;
            }

            logger.warn("Ignoring unsupported status payload - Topic: {} | Payload: {}", messageTopic, payload);
        });
        logger.info("Subscription request sent for topic: {}", MQTT_TOPIC_SUB_STATUS);

        logger.info("Attempting to subscribe to topic: {}", MQTT_TOPIC_SUB_WEIGHT);
        mqttClient.subscribe(MQTT_TOPIC_SUB_WEIGHT, qos, (messageTopic, message) -> {
            String payload = new String(message.getPayload());
            try{
                logger.info("Receive new weight in topic : {} | Weight: {}", messageTopic, payload);
                scaleService.SaveWeightFromScale(messageTopic.replace("/weights/", ""), payload);
                log(messageTopic, payload);
                logger.info("Weight saved in topic: {}", messageTopic);
            }
            catch (Exception e){
                logger.error("Error when try to save weight - Topic: {} | Weight: {} - Error: {}", messageTopic, payload, e.getMessage(), e);
            }
        });
        logger.info("Subscription request sent for topic: {}", MQTT_TOPIC_SUB_WEIGHT);
    }

    @Scheduled(fixedRate = 300000) // Every 5 minutes
    public void logHeartbeat() {
        logger.info("MQTT subscriber is alive");
    }

    private void log(String messageTopic, String payload){
        logger.info("Received message - Topic: {} | Payload: {}", messageTopic, payload);
    }
}
