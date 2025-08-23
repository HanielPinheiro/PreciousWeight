package precious_weight.config.system;

public class MqttConstants {
    public static final String MQTT_API_SERVICE_NAME = "PW_API_SERVICE";

    public static final String MQTT_TOPIC_PUB_STATUS_API ="api/status";
    public static final String MQTT_TOPIC_PUB_SCALE ="/scales/"; // send data to scale

    public static final String MQTT_TOPIC_SUB_SCALE ="/scales/#"; // check data to scale topic for all scales
    public static final String MQTT_TOPIC_SUB_WEIGHT ="/weight/#"; // check data in weight topic for all babies

    public static final String DEFAULT_WEIGHT_TIME= "12:00";
    public static final String MQTT_COMMAND_RUN = "[RUN]"; // send scale to start monitoring time to weight
    public static final String MQTT_COMMAND_BABY = "[BAB]"; // inform scale a new baby id
    public static final String MQTT_COMMAND_CLEAR = "[CLE]"; // remove data from last baby from scale
    public static final String MQTT_COMMAND_WEIGHT_TIME = "[TIM]"; //send a weight time to scale
    public static final String MQTT_COMMAND_MEASURE = "[MEA]"; // get a weight measure from scale
    public static final String MQTT_COMMAND_CALIBRATE = "[CAL]"; // run calibration routine in scale
}
