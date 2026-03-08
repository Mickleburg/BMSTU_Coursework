import org.eclipse.paho.client.mqttv3.*;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;

public class Subscriber {
    private static Integer lastResult = null;

    public static void start() {
        String broker = "tcp://broker.emqx.io:1883";
        String clientId = "ShalimovSubscriber";
        String topic = "bmstu/iu9/shalimov";
        int qos = 1;

        try {
            MqttClient client = new MqttClient(broker, clientId, new MemoryPersistence());
            MqttConnectOptions options = new MqttConnectOptions();
            options.setCleanSession(true);

            client.setCallback(new MqttCallback() {
                @Override
                public void connectionLost(Throwable cause) {
                    System.err.println("Connection lost: " + cause.getMessage());
                }

                @Override
                public void messageArrived(String topic, MqttMessage message) {

                    String payload = new String(message.getPayload());
                    String[] parts = payload.split(";");
                    if (parts.length != 6) return;

                    try {
                        double x1 = Double.parseDouble(parts[0].trim());
                        double y1 = Double.parseDouble(parts[1].trim());
                        double r1 = Double.parseDouble(parts[2].trim());
                        double x2 = Double.parseDouble(parts[3].trim());
                        double y2 = Double.parseDouble(parts[4].trim());
                        double r2 = Double.parseDouble(parts[5].trim());

                        double dx = x2 - x1;
                        double dy = y2 - y1;
                        double distance = Math.sqrt(dx * dx + dy * dy);
                        lastResult = (distance + r2 <= r1) ? 1 : 0;

                    } catch (NumberFormatException e) {
                        lastResult = null;
                    }
                }

                @Override
                public void deliveryComplete(IMqttDeliveryToken token) {}
            });

            client.connect(options);
            client.subscribe(topic, qos);
            System.out.println("Subscribed. Waiting for messages...");

            new Thread(() -> {
                while (true) {
                    try {
                        Thread.sleep(1000);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            }).start();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static Integer getLastResult() {
        return lastResult;
    }
}