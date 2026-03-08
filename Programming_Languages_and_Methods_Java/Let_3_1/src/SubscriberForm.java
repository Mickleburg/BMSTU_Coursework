import javax.swing.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

public class SubscriberForm {
    private JTextField resField;
    private JPanel mainPanel;
    private JButton getBtn;
    private static boolean isSubscriberStarted = false;

    public SubscriberForm() {
        getBtn.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                // Запускаем подписчик при первом нажатии
                if (!isSubscriberStarted) {
                    Subscriber.start();
                    isSubscriberStarted = true;
                }

                // Получаем результат и обновляем поле
                Integer result = Subscriber.getLastResult();
                resField.setText(result != null ? result.toString() : "N/A");
            }
        });
    }

    public static void main(String[] args) {
        JFrame frame = new JFrame("Приём");
        frame.setContentPane(new SubscriberForm().mainPanel);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.pack();
        frame.setVisible(true);
    }
}