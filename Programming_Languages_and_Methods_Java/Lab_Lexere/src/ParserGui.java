import javax.swing.*;
import java.awt.*;

public class ParserGui extends JFrame {
    private JTextArea inputArea = new JTextArea(10, 40);
    private JTextArea outputArea = new JTextArea(10, 40);

    public ParserGui() {
        setTitle("LL(1) Parser");
        setLayout(new BorderLayout());

        JButton parseBtn = new JButton("Parse");
        parseBtn.addActionListener(e -> parseInput());

        add(new JScrollPane(inputArea), BorderLayout.NORTH);
        add(parseBtn, BorderLayout.CENTER);
        add(new JScrollPane(outputArea), BorderLayout.SOUTH);

        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        pack();
        setVisible(true);
    }

    private void parseInput() {
        try {
            Lexer lexer = new Lexer(inputArea.getText());
            Parser parser = new Parser(lexer);
            outputArea.setText(String.join("\n", parser.parse()));
        } catch (Exception ex) {
            outputArea.setText(ex.getMessage());
        }
    }

    public static void main(String[] args) {
        new ParserGui();
    }
}
