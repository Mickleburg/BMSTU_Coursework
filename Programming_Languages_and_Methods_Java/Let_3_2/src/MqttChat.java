import org.eclipse.paho.client.mqttv3.MqttException;

import javax.swing.*;
import java.awt.*;

public class MqttChat {
    //Gui элементы
    private JPanel mainPanel;
    private JTextArea chatArea;
    private JScrollPane scrollPane1;
    private JTextField inputField;
    private JButton sendButton;
    private JButton themeButton;
    private JPanel emojiPanel;

    //Вспомогательные элементы
    private Publisher publisher;
    private boolean isDarkTheme = false;

    public MqttChat() {
        try {
            publisher = new Publisher();
            new Subscriber(message ->
                    SwingUtilities.invokeLater(() ->
                            chatArea.append(message + "\n")
                    )
            );
        } catch (MqttException e) {
            JOptionPane.showMessageDialog(mainPanel, "Ошибка подключения к MQTT");
        }

        initEmojiPanel();

        sendButton.addActionListener(e -> sendMessage());
        inputField.addActionListener(e -> sendMessage());
        themeButton.addActionListener(e -> changeTheme());
    }

    private void initEmojiPanel() {
        String[] emojis = {
                "😀", "😃", "😄", "😁", "😆",
                "😅", "😂", "🤣", "😊", "😇",
                "\uD83D\uDC40", "\uD83E\uDD21", "\uD83D\uDC8B", "\uD83D\uDC80", "\uD83D\uDC7A",
                "\uD83D\uDCA9", "\uD83D\uDC4D", "\uD83D\uDC4E", "\uD83D\uDC4C", "\uD83E\uDD19"
        };

        emojiPanel.setLayout(new GridLayout(0, 5, 5, 5)); // 5 колонок, отступы 5px

        for (String emoji : emojis) {
            JButton emojiBtn = new JButton(emoji);
            emojiBtn.addActionListener(e ->
                    inputField.setText(inputField.getText() + emoji)
            );
            emojiPanel.add(emojiBtn);
        }
    }

    private void changeTheme() {
        if (isDarkTheme) {
            mainPanel.setBackground(Color.WHITE);

            chatArea.setBackground(Color.WHITE);
            chatArea.setForeground(Color.BLACK);

            inputField.setBackground(Color.WHITE);
            inputField.setForeground(Color.BLACK);
        } else {
            mainPanel.setBackground(Color.DARK_GRAY);

            chatArea.setBackground(Color.BLACK);
            chatArea.setForeground(Color.WHITE);

            inputField.setBackground(Color.BLACK);
            inputField.setForeground(Color.WHITE);
        }
        isDarkTheme = !isDarkTheme;
    }

    private void sendMessage() {
        String message = inputField.getText().trim();
        if (!message.isEmpty()) {
            try {
                publisher.sendMessage(message);
                inputField.setText("");
            } catch (MqttException e) {
                JOptionPane.showMessageDialog(mainPanel, "Ошибка отправки");
            }
        }
    }

    public static void main(String[] args) {
        JFrame frame = new JFrame("MqttChat");
        frame.setContentPane(new MqttChat().mainPanel);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.pack();
        frame.setVisible(true);
    }
}
