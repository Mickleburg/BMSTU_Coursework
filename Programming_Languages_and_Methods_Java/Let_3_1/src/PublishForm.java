import javax.swing.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.Locale;

public class PublishForm {
    private JTextField x1Field;
    private JTextField y1Field;
    private JTextField r1Field;
    private JTextField x2Field;
    private JTextField y2Field;
    private JTextField r2Field;
    private JPanel mainPanel;
    private JButton sendBtn;

    private Publisher publisher;

    public PublishForm() {
        // Инициализируем publisher
        publisher = new Publisher();

        sendBtn.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                try {
                    // Данные из полей
                    double x1 = Double.parseDouble(x1Field.getText());
                    double y1 = Double.parseDouble(y1Field.getText());
                    double r1 = Double.parseDouble(r1Field.getText());
                    double x2 = Double.parseDouble(x2Field.getText());
                    double y2 = Double.parseDouble(y2Field.getText());
                    double r2 = Double.parseDouble(r2Field.getText());

                    // Отправляем данные
                    publisher.publishData(x1, y1, r1, x2, y2, r2);
                    JOptionPane.showMessageDialog(mainPanel, "Данные успешно отправлены!");

                } catch (NumberFormatException ex) {
                    JOptionPane.showMessageDialog(mainPanel, "Ошибка формата данных! Введите числа.");
                } catch (Exception ex) {
                    JOptionPane.showMessageDialog(mainPanel, "Ошибка отправки: " + ex.getMessage());
                }
            }
        });
    }

    public static void main(String[] args) {
        JFrame frame = new JFrame("Отправка");
        frame.setContentPane(new PublishForm().mainPanel);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.pack();
        frame.setVisible(true);
    }
}