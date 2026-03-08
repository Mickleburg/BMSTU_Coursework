package handlers

import (
    "database/sql"
    "net/http"
    "strconv"
    "backend/internal/models"
    "backend/internal/utils"

    "github.com/gin-gonic/gin"
)

type MessageHandler struct {
    db *sql.DB
}

func NewMessageHandler(db *sql.DB) *MessageHandler {
    return &MessageHandler{db: db}
}

func (h *MessageHandler) CreateMessage(c *gin.Context) {
    var req models.CreateMessageRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        utils.ErrorResponse(c, http.StatusBadRequest, "Неверный формат данных", err)
        return
    }

    userID := 1

    query := `
        INSERT INTO messages (topic_id, author_id, content, parent_id, created_at)
        VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
        RETURNING id, created_at
    `

    var message models.Message
    err := h.db.QueryRow(query, req.TopicID, userID, req.Content, req.ParentID).
        Scan(&message.ID, &message.CreatedAt)
    if err != nil {
        utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка создания сообщения", err)
        return
    }

    message.TopicID = req.TopicID
    message.AuthorID = userID
    message.Content = req.Content
    message.ParentID = req.ParentID

    utils.SuccessResponse(c, message)
}

func (h *MessageHandler) GetMessage(c *gin.Context) {
    idStr := c.Param("id")
    id, err := strconv.Atoi(idStr)
    if err != nil {
        utils.ErrorResponse(c, http.StatusBadRequest, "Неверный ID сообщения", nil)
        return
    }

    query := `
        SELECT m.id, m.topic_id, m.author_id, m.content, m.parent_id, m.created_at,
               u.username, u.role
        FROM messages m
        JOIN users u ON m.author_id = u.id
        WHERE m.id = $1
    `

    var message models.Message
    var author models.User
    err = h.db.QueryRow(query, id).Scan(
        &message.ID, &message.TopicID, &message.AuthorID, &message.Content,
        &message.ParentID, &message.CreatedAt,
        &author.Username, &author.Role,
    )

    if err == sql.ErrNoRows {
        utils.ErrorResponse(c, http.StatusNotFound, "Сообщение не найдено", nil)
        return
    }
    if err != nil {
        utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка получения сообщения", err)
        return
    }

    author.ID = message.AuthorID
    message.Author = &author

    utils.SuccessResponse(c, message)
}

func (h *MessageHandler) GetTopicMessages(c *gin.Context) {
    topicIDStr := c.Param("id")
    topicID, err := strconv.Atoi(topicIDStr)
    if err != nil {
        utils.ErrorResponse(c, http.StatusBadRequest, "Неверный ID темы", nil)
        return
    }

    query := `
        SELECT m.id, m.topic_id, m.author_id, m.content, m.parent_id, m.created_at,
               u.username, u.role
        FROM messages m
        JOIN users u ON m.author_id = u.id
        WHERE m.topic_id = $1
        ORDER BY m.created_at ASC
    `

    rows, err := h.db.Query(query, topicID)
    if err != nil {
        utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка получения сообщений", err)
        return
    }
    defer rows.Close()

    var messages []models.Message
    for rows.Next() {
        var message models.Message
        var author models.User

        err := rows.Scan(
            &message.ID, &message.TopicID, &message.AuthorID, &message.Content,
            &message.ParentID, &message.CreatedAt,
            &author.Username, &author.Role,
        )
        if err != nil {
            utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка чтения сообщений", err)
            return
        }

        author.ID = message.AuthorID
        message.Author = &author
        messages = append(messages, message)
    }

    utils.SuccessResponse(c, messages)
}
