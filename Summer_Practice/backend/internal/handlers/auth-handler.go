package handlers

import (
    "database/sql"
    "net/http"
    "time"
    "backend/internal/models"
    "backend/internal/utils"
    
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
    "golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
    db        *sql.DB
    jwtSecret string
}

func NewAuthHandler(db *sql.DB, jwtSecret string) *AuthHandler {
    return &AuthHandler{
        db:        db,
        jwtSecret: jwtSecret,
    }
}

func (h *AuthHandler) Register(c *gin.Context) {
    var req models.UserRegister
    if err := c.ShouldBindJSON(&req); err != nil {
        utils.ErrorResponse(c, http.StatusBadRequest, "Неверный формат данных", err)
        return
    }

    // Проверяем, существует ли пользователь
    var exists bool
    checkQuery := "SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)"
    err := h.db.QueryRow(checkQuery, req.Username).Scan(&exists)
    if err != nil {
        utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка проверки пользователя", err)
        return
    }

    if exists {
        utils.ErrorResponse(c, http.StatusConflict, "Пользователь уже существует", nil)
        return
    }

    // Хешируем пароль
    hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
    if err != nil {
        utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка хеширования пароля", err)
        return
    }

    // Создаем пользователя
    insertQuery := `
        INSERT INTO users (username, password_hash, role, created_at)
        VALUES ($1, $2, 'user', CURRENT_TIMESTAMP)
        RETURNING id, created_at
    `

    var user models.User
    err = h.db.QueryRow(insertQuery, req.Username, string(hashedPassword)).
        Scan(&user.ID, &user.CreatedAt)
    if err != nil {
        utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка создания пользователя", err)
        return
    }

    user.Username = req.Username
    user.Role = "user"

    // Генерируем JWT токен
    token, err := h.generateJWT(user.ID, user.Username, user.Role)
    if err != nil {
        utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка генерации токена", err)
        return
    }

    response := models.LoginResponse{
        Token: token,
        User:  user,
    }

    utils.SuccessResponse(c, response)
}

func (h *AuthHandler) Login(c *gin.Context) {
    var req models.UserLogin
    if err := c.ShouldBindJSON(&req); err != nil {
        utils.ErrorResponse(c, http.StatusBadRequest, "Неверный формат данных", err)
        return
    }

    // Ищем пользователя
    query := "SELECT id, username, password_hash, role, created_at FROM users WHERE username = $1"
    
    var user models.User
    err := h.db.QueryRow(query, req.Username).Scan(
        &user.ID, &user.Username, &user.PasswordHash, &user.Role, &user.CreatedAt,
    )

    if err == sql.ErrNoRows {
        utils.ErrorResponse(c, http.StatusUnauthorized, "Неверные учетные данные", nil)
        return
    }
    if err != nil {
        utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка поиска пользователя", err)
        return
    }

    // Проверяем пароль
    err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password))
    if err != nil {
        utils.ErrorResponse(c, http.StatusUnauthorized, "Неверные учетные данные", nil)
        return
    }

    // Генерируем JWT токен
    token, err := h.generateJWT(user.ID, user.Username, user.Role)
    if err != nil {
        utils.ErrorResponse(c, http.StatusInternalServerError, "Ошибка генерации токена", err)
        return
    }

    response := models.LoginResponse{
        Token: token,
        User:  user,
    }

    utils.SuccessResponse(c, response)
}

func (h *AuthHandler) generateJWT(userID int, username, role string) (string, error) {
    claims := jwt.MapClaims{
        "user_id":  userID,
        "username": username,
        "role":     role,
        "exp":      time.Now().Add(time.Hour * 24).Unix(), // 24 часа
        "iat":      time.Now().Unix(),
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(h.jwtSecret))
}