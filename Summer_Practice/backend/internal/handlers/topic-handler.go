package handlers

import (
	"backend/internal/models"
	"backend/internal/utils"
	"database/sql"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type TopicHandler struct {
	db *sql.DB
}

func NewTopicHandler(db *sql.DB) *TopicHandler {
	return &TopicHandler{db: db}
}

func (h *TopicHandler) CreateTopic(c *gin.Context) {
	var req models.CreateTopicRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Неверный формат данных", err)
		return
	}

	userID := 1 // Анонимный пользователь

	query := `
        INSERT INTO topics (title, author_id, rules, created_at)
        VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
        RETURNING id, created_at
    `

	var topic models.Topic
	err := h.db.QueryRow(query, req.Title, userID, req.Rules).Scan(&topic.ID, &topic.CreatedAt)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка создания темы", err)
		return
	}

	topic.Title = req.Title
	topic.AuthorID = userID
	topic.Rules = req.Rules

	utils.SuccessResponse(c, topic)
}

func (h *TopicHandler) GetTopics(c *gin.Context) {
	query := `
        SELECT t.id, t.title, t.author_id, t.rules, t.created_at, u.username, u.role
        FROM topics t
        JOIN users u ON t.author_id = u.id
        ORDER BY t.created_at DESC
    `

	rows, err := h.db.Query(query)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка получения тем", err)
		return
	}
	defer rows.Close()

	var topics []models.Topic
	for rows.Next() {
		var topic models.Topic
		var author models.User

		err := rows.Scan(&topic.ID, &topic.Title, &topic.AuthorID, &topic.Rules, &topic.CreatedAt,
			&author.Username, &author.Role)
		if err != nil {
			utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка чтения тем", err)
			return
		}

		author.ID = topic.AuthorID
		topic.Author = &author
		topics = append(topics, topic)
	}

	utils.SuccessResponse(c, topics)
}

func (h *TopicHandler) GetTopic(c *gin.Context) {
	idStr := c.Param("id")

	log.Printf("Получен запрос для темы с ID: %s", idStr)

	id, err := strconv.Atoi(idStr)
	if err != nil {
		log.Printf("Ошибка преобразования ID: %v", err)
		utils.ErrorResponse(c, http.StatusBadRequest, "Неверный ID темы", nil)
		return
	}

	topicQuery := `
        SELECT t.id, t.title, t.author_id, t.rules, t.created_at, u.username, u.role
        FROM topics t
        JOIN users u ON t.author_id = u.id
        WHERE t.id = $1
    `

	var topic models.Topic
	var author models.User
	err = h.db.QueryRow(topicQuery, id).Scan(
		&topic.ID, &topic.Title, &topic.AuthorID, &topic.Rules, &topic.CreatedAt,
		&author.Username, &author.Role)

	if err == sql.ErrNoRows {
		utils.ErrorResponse(c, http.StatusNotFound, "Тема не найдена", nil)
		return
	}
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка получения темы", err)
		return
	}

	author.ID = topic.AuthorID
	topic.Author = &author

	messagesQuery := `
        SELECT m.id, m.topic_id, m.author_id, m.content, m.parent_id, m.created_at,
               u.username, u.role
        FROM messages m
        JOIN users u ON m.author_id = u.id
        WHERE m.topic_id = $1
        ORDER BY m.created_at ASC
    `

	rows, err := h.db.Query(messagesQuery, id)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка получения сообщений", err)
		return
	}
	defer rows.Close()

	var messages []models.Message
	for rows.Next() {
		var message models.Message
		var msgAuthor models.User

		err := rows.Scan(
			&message.ID, &message.TopicID, &message.AuthorID, &message.Content,
			&message.ParentID, &message.CreatedAt,
			&msgAuthor.Username, &msgAuthor.Role,
		)
		if err != nil {
			utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка чтения сообщений", err)
			return
		}

		msgAuthor.ID = message.AuthorID
		message.Author = &msgAuthor
		messages = append(messages, message)
	}

	response := gin.H{
		"topic":    topic,
		"messages": messages,
	}

	log.Printf("Отправляемый ответ: %+v", response)

	utils.SuccessResponse(c, response)
}
