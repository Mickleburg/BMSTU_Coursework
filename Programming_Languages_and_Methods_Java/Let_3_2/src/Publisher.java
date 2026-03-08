import org.eclipse.paho.client.mqttv3.*;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;

public class Publisher {
    private static final String BROKER = "tcp://broker.emqx.io:1883";
    private static final String CLIENT_ID = "ChatPublisherGUI";
    private static final String TOPIC = "/iu9/mqttchat";
    private MqttClient client;

    public Publisher() throws MqttException {
        client = new MqttClient(BROKER, CLIENT_ID, new MemoryPersistence());
        MqttConnectOptions options = new MqttConnectOptions();
        options.setCleanSession(true);
        client.connect(options);
    }

    public void sendMessage(String message) throws MqttException {
        MqttMessage mqttMessage = new MqttMessage(message.getBytes());
        mqttMessage.setQos(2);
        client.publish(TOPIC, mqttMessage);
    }
}
