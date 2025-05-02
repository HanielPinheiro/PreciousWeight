package precious_weight.config;

import org.eclipse.paho.client.mqttv3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.UUID;

@Configuration
public class MqttConfig {
    private static final Logger logger = LoggerFactory.getLogger(MqttConfig.class);
    @Value("${mqtt.broker.url}") // e.g., "tcp://mosquitto:1883"
    private String brokerUrl;

    @Bean
    public IMqttAsyncClient mqttAsyncClient() throws MqttException {
        IMqttAsyncClient client = new MqttAsyncClient(brokerUrl,"PW_API_" + UUID.randomUUID().toString());

        client.setCallback(new MqttCallbackExtended() {
            @Override
            public void connectComplete(boolean reconnect, String serverURI) {
                logger.info("Connected to MQTT broker. Reconnect: {}", reconnect);
            }

            @Override
            public void connectionLost(Throwable cause) {
                logger.error("Connection lost!", cause);
            }

            @Override
            public void messageArrived(String topic, MqttMessage message) {
                logger.info("Message arrived - Topic: {} | Payload: {}", topic, new String(message.getPayload()));

            }

            @Override
            public void deliveryComplete(IMqttDeliveryToken token) {
                logger.debug("Delivery complete for message with ID: {}", token.getMessageId());
            }
        });

        MqttConnectOptions options = new MqttConnectOptions();
        options.setCleanSession(false); // Persistent session (QoS 2)
        options.setAutomaticReconnect(true);
        options.setConnectionTimeout(10);
        options.setWill("api/status", "OFFLINE".getBytes(), 2, true); // LWT

        client.connect(options).waitForCompletion();
        return client;
    }
}