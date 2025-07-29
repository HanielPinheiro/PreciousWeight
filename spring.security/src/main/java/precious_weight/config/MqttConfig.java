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
        IMqttAsyncClient client = new MqttAsyncClient(brokerUrl, "PW_API_SERVICE");
        client.setCallback(new MqttCallbackExtended() {
            @Override
            public void connectionLost(Throwable throwable) {
            }

            @Override
            public void messageArrived(String s, MqttMessage mqttMessage) throws Exception {
            }

            @Override
            public void deliveryComplete(IMqttDeliveryToken iMqttDeliveryToken) {
            }

            @Override
            public void connectComplete(boolean reconnect, String serverURI) {
                logger.info("RECONNECTING to MQTT broker...");

                try {
                    MqttMessage onlineMessage = new MqttMessage("RECONNECTED".getBytes());
                    onlineMessage.setQos(2);
                    onlineMessage.setRetained(true);
                    client.publish("api/status", onlineMessage);
                } catch (MqttException e) {
                    logger.error("Failed to send RECONNECTED status", e);
                }

                logger.info("RECONNECTED");
            }
        });

        MqttConnectOptions options = new MqttConnectOptions();
        options.setCleanSession(false); // Persistent session (QoS 2)
        options.setAutomaticReconnect(true);
        options.setConnectionTimeout(10);

        client.connect(options).waitForCompletion();
        MqttMessage onlineMessage = new MqttMessage("ONLINE".getBytes());
        onlineMessage.setQos(2);
        onlineMessage.setRetained(true);
        client.publish("api/status", onlineMessage);

        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            try {
                MqttMessage message = new MqttMessage("OFFLINE".getBytes());
                message.setQos(2);
                message.setRetained(true);
                client.publish("api/status", message);
                client.disconnect();
            } catch (MqttException e) {
                logger.error("Failed to send offline status on shutdown", e);
            }
        }));

        return client;
    }
}