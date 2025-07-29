package precious_weight.services;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import org.eclipse.paho.client.mqttv3.*;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class MqttSubscriberService {
    private static final Logger logger = LoggerFactory.getLogger(MqttSubscriberService.class);

    @Autowired
    private IMqttAsyncClient mqttClient;

    @Autowired
    private WeightService weightService;

    @PostConstruct
    public void startMonitoring() throws MqttException {
        int qos = 1;

        String topic_scale = "scale/#";
        logger.info("Attempting to subscribe to topic: {}", topic_scale);
        mqttClient.subscribe(topic_scale, qos, (messageTopic, message) -> {
            //esse metodo apenas loga o trafego no topico scale
            String payload = new String(message.getPayload());
            log(messageTopic, payload);
        });
        logger.info("Subscription request sent for topic: {}", topic_scale);

        String topic_weight = "weight/#";
        logger.info("Attempting to subscribe to topic: {}", topic_weight);
        mqttClient.subscribe(topic_weight, qos, (messageTopic, message) -> {
            String payload = new String(message.getPayload());
            try{
                logger.info("Receive new weight in topic : {} | Weight: {}", messageTopic, payload);
                weightService.saveWeightFromScale(messageTopic.replace("weight/", ""), payload);
                log(messageTopic, payload);
                logger.info("Weight saved in topic: {}", messageTopic);
            }
            catch (Exception e){
                logger.error("Error when try to save weight - Topic: {} | Weight: {} - Error: {}", messageTopic, payload, e.getMessage(), e);
            }
        });
        logger.info("Subscription request sent for topic: {}", topic_weight);
    }

    @Scheduled(fixedRate = 300000) // Every 5 minutes
    public void logHeartbeat() {
        logger.info("MQTT subscriber is alive");
    }

    private void log(String messageTopic, String payload){
        logger.info("Received message - Topic: {} | Payload: {}", messageTopic, payload);
    }
}
