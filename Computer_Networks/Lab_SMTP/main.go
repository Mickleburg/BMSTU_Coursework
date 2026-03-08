package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/smtp"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

const (
	dbHost = "students.yss.su"
	dbPort = "3306"
	dbName = "iu9networkslabs"
	dbUser = "iu9networkslabs"
	dbPass = "Je2dTYr6"

	tableEmails = "iu9shalimov"
	tableLogs   = "iu9shalimov_logs"
)

type SMTPConfig struct {
	Host     string // "smtp.mail.ru"
	Port     string // "587"
	Username string // "test@shalimov.123aaa.ru"
	Password string // "mo3LK5ZKZKJe2dpgJaro"
	From     string // "test@shalimov.123aaa.ru"
}

type MailSender struct {
	db   *sql.DB
	smtp SMTPConfig
}

func NewMailSender(cfg SMTPConfig) (*MailSender, error) {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True", dbUser, dbPass, dbHost, dbPort, dbName)
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, fmt.Errorf("ошибка подключения к БД: %w", err)
	}
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("не удалось пингануть БД: %w", err)
	}
	return &MailSender{db: db, smtp: cfg}, nil
}

// Получаем активные email
func (ms *MailSender) GetMailingList() ([]string, error) {
	query := fmt.Sprintf("SELECT email FROM %s WHERE is_active = TRUE", tableEmails)
	rows, err := ms.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("ошибка запроса списка рассылки: %w", err)
	}
	defer rows.Close()

	var emails []string
	for rows.Next() {
		var email string
		if err := rows.Scan(&email); err != nil {
			return nil, fmt.Errorf("ошибка сканирования email: %w", err)
		}
		if strings.TrimSpace(email) != "" {
			emails = append(emails, email)
		}
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("ошибка итерации по строкам: %w", err)
	}
	return emails, nil
}

// Логируем отправку (в вашу таблицу с логами)
func (ms *MailSender) LogSending(email, subject, status, errorMsg string) error {
	query := fmt.Sprintf(
		"INSERT INTO %s (email, subject, status, error_message) VALUES (?, ?, ?, ?)",
		tableLogs,
	)
	_, err := ms.db.Exec(query, email, subject, status, errorMsg)
	if err != nil {
		return fmt.Errorf("ошибка записи лога для %s: %w", email, err)
	}
	return nil
}

// Отправка одного письма с HTML-телом
func (ms *MailSender) SendEmail(to, subject, htmlBody string) error {
	smtpAddr := ms.smtp.Host + ":" + ms.smtp.Port

	// MIME-headers + HTML
	headers := []string{
		"From: " + ms.smtp.From,
		"To: " + to,
		"Subject: " + subject,
		"MIME-Version: 1.0",
		"Content-Type: text/html; charset=UTF-8",
		"Content-Transfer-Encoding: 8bit",
		"List-Unsubscribe: <mailto:test@shalimov.123aaa.ru?subject=UNSUBSCRIBE>",
		"List-Unsubscribe-Post: List-Unsubscribe=One-Click",
	}
	message := strings.Join(headers, "\r\n") + "\r\n\r\n" + htmlBody

	auth := smtp.PlainAuth("", ms.smtp.Username, ms.smtp.Password, ms.smtp.Host)

	err := smtp.SendMail(smtpAddr, auth, ms.smtp.From, []string{to}, []byte(message))
	status := "success"
	errorMsg := ""
	if err != nil {
		status = "failed"
		errorMsg = err.Error()
		log.Printf("Ошибка отправки на %s: %v", to, err)
	} else {
		log.Printf("Отправлено: %s", to)
	}

	// Логируем — даже если ошибка записи лога, продолжаем
	if logErr := ms.LogSending(to, subject, status, errorMsg); logErr != nil {
		log.Printf("Не удалось записать лог для %s: %v", to, logErr)
	}

	return err
}

func (ms *MailSender) BulkSend(subject, htmlBody string, delay time.Duration) error {
	emails, err := ms.GetMailingList()
	if err != nil {
		return fmt.Errorf("ошибка получения списка рассылки: %w", err)
	}
	if len(emails) == 0 {
		return fmt.Errorf("в таблице %s нет активных email'ов", tableEmails)
	}

	log.Printf("Начинаем рассылку «%s» для %d получателей", subject, len(emails))

	success := 0
	for i, email := range emails {
		log.Printf("[%d/%d] Готовлюсь отправить на %s...", i+1, len(emails), email)

		err := ms.SendEmail(email, subject, htmlBody)
		if err == nil {
			success++
		}

		if i < len(emails)-1 { // не ждём после последнего
			time.Sleep(delay)
		}
	}

	log.Printf("Рассылка завершена: %d из %d писем успешно отправлено", success, len(emails))
	return nil
}

func main() {
	smtpCfg := SMTPConfig{
		Host:     "smtp.mail.ru",
		Port:     "587",
		Username: "test@shalimov.123aaa.ru",
		Password: "mo3LK5ZKZKJe2dpgJaro",
		From:     "test@shalimov.123aaa.ru",
	}

	sender, err := NewMailSender(smtpCfg)
	if err != nil {
		log.Fatalf("Не удалось инициализировать рассыльщик: %v", err)
	}
	defer sender.db.Close()

	subject := "Шалимов_Отчет"

	htmlBody := `<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>Письмо-отчет</title>
</head>
<body style="font-family: Georgia, serif; line-height: 1.6; color: #222; max-width: 640px; margin: 2em auto; padding: 0 1em;">
  <div style="border-left: 2px solid #555; padding-left: 1.2em;">
    <p style="font-size: 1.1em; margin: 1.2em 0;">Не осуждая позднего раскаянья,<br>
    не искажая истины условной,<br>
    ты отражаешь Авеля и Каина,<br>
    как будто отражаешь маски клоуна.</p>

    <p style="font-size: 1.1em; margin: 1.2em 0;">Как будто все мы – только гости поздние,<br>
    как будто наспех поправляем галстуки,<br>
    как будто одинаково – погостами —<br>
    покончим мы, разнообразно алчущие.</p>

    <p style="font-size: 1.1em; margin: 1.2em 0;">Но, сознавая собственную зыбкость,<br>
    Ты будешь вновь разглядывать улыбки<br>
    и различать за мишурою ценность,<br>
    как за щитом самообмана – нежность...</p>

    <p style="font-size: 1.1em; margin: 1.2em 0;">О, ощути за суетностью цельность<br>
    и на обычном циферблате – вечность!</p>
  </div>

  <p style="margin-top: 2em; font-style: italic; color: #666;">
    С уважением,<br>
    Даниил Шалимов
  </p>

  <p style="font-size: 0.85em; color: #999; margin-top: 2em;">
    Это письмо отправлено в рамках учебного проекта.<br>
  </p>
</body>
</html>`

	// задержка 3 сек
	delay := 3 * time.Second

	err = sender.BulkSend(subject, htmlBody, delay)
	if err != nil {
		log.Fatalf("Ошибка при рассылке: %v", err)
	}

	log.Println("Рассылка успешно завершена!")
}
