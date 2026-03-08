import org.eclipse.paho.client.mqttv3.*;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;
import java.util.Locale;

public class Publisher {
    private static final String BROKER = "tcp://broker.emqx.io:1883";
    private static final String CLIENT_ID = "ShalimovPublisherGUI";
    private static final String TOPIC = "bmstu/iu9/shalimov";

    private MqttClient client;

    public Publisher() {
        try {
            client = new MqttClient(BROKER, CLIENT_ID, new MemoryPersistence());
            MqttConnectOptions options = new MqttConnectOptions();
            options.setCleanSession(true);
            client.connect(options);
        } catch (MqttException e) {
            throw new RuntimeException("Ошибка подключения к брокеру", e);
        }
    }

    public void publishData(double x1, double y1, double r1,
                            double x2, double y2, double r2) throws MqttException {
        String content = String.format(Locale.US,
                "%.2f;%.2f;%.2f;%.2f;%.2f;%.2f",
                x1, y1, r1, x2, y2, r2
        );

        MqttMessage message = new MqttMessage(content.getBytes());
        message.setQos(2);
        client.publish(TOPIC, message);
    }
}