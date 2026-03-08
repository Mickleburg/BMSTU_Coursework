package middleware

import (
    "net/http"
    "strings"
    "backend/internal/utils"
    
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
)

func CORSMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Header("Access-Control-Allow-Origin", "*")
        c.Header("Access-Control-Allow-Credentials", "true")
        c.Header("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
        c.Header("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }

        c.Next()
    }
}

func JWTAuth(jwtSecret string) gin.HandlerFunc {
    return func(c *gin.Context) {
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            utils.ErrorResponse(c, http.StatusUnauthorized, "Требуется авторизация", nil)
            c.Abort()
            return
        }

        // Проверяем формат "Bearer <token>"
        tokenParts := strings.Split(authHeader, " ")
        if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
            utils.ErrorResponse(c, http.StatusUnauthorized, "Неверный формат токена", nil)
            c.Abort()
            return
        }

        tokenString := tokenParts[1]

        // Парсим и проверяем токен
        token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
            if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
                return nil, jwt.ErrSignatureInvalid
            }
            return []byte(jwtSecret), nil
        })

        if err != nil || !token.Valid {
            utils.ErrorResponse(c, http.StatusUnauthorized, "Недействительный токен", err)
            c.Abort()
            return
        }

        // Извлекаем данные из токена
        if claims, ok := token.Claims.(jwt.MapClaims); ok {
            if userID, exists := claims["user_id"].(float64); exists {
                c.Set("user_id", int(userID))
            }
            if username, exists := claims["username"].(string); exists {
                c.Set("username", username)
            }
            if role, exists := claims["role"].(string); exists {
                c.Set("role", role)
            }
        }

        c.Next()
    }
}