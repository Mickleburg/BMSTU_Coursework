import org.eclipse.paho.client.mqttv3.*;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;

public class Subscriber {
    private MessageHandler messageHandler;
    private static final String TOPIC = "/iu9/mqttchat";

    public interface MessageHandler {
        void handleMessage(String message);
    }

    public Subscriber(MessageHandler handler) throws MqttException {
        this.messageHandler = handler;
        String broker = "tcp://broker.emqx.io:1883";
        String clientId = "ChatSubscriber_" + System.currentTimeMillis();

        MqttClient client = new MqttClient(broker, clientId, new MemoryPersistence());

        // Добавляем настройки подключения
        MqttConnectOptions options = new MqttConnectOptions();
        options.setCleanSession(true);

        client.setCallback(new MqttCallback() {
            @Override
            public void connectionLost(Throwable throwable) {
                System.err.println("Connection lost: " + throwable.getMessage());
            }

            @Override
            public void messageArrived(String topic, MqttMessage message) {
                if (messageHandler != null) {
                    messageHandler.handleMessage(new String(message.getPayload()));
                }
            }

            @Override
            public void deliveryComplete(IMqttDeliveryToken token) {}
        });

        // Подключаемся с настройками
        client.connect(options);
        // Подписываемся на топик
        client.subscribe(TOPIC, 1);
    }
}