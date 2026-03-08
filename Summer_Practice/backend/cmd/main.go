package main

import (
    "log"
    "backend/internal/config"
    "backend/internal/database"
    "backend/internal/handlers"
    "backend/internal/middleware"

    "github.com/gin-gonic/gin"
    "github.com/joho/godotenv"
)

func main() {
    if err := godotenv.Load(); err != nil {
        log.Println("No .env file found")
    }

    cfg := config.Load()

    db, err := database.Connect(cfg.DatabaseURL)
    if err != nil {
        log.Fatal("Failed to connect to database:", err)
    }
    defer db.Close()

    if err = database.Migrate(db); err != nil {
        log.Fatal("Failed to run migrations:", err)
    }

    r := gin.Default()
    r.Use(middleware.CORSMiddleware())

    authHandler := handlers.NewAuthHandler(db, cfg.JWTSecret)
    topicHandler := handlers.NewTopicHandler(db)
    messageHandler := handlers.NewMessageHandler(db)

    api := r.Group("/api")
    {
        api.POST("/register", authHandler.Register)
        api.POST("/login", authHandler.Login)

        api.GET("/topics", topicHandler.GetTopics)
        api.GET("/topics/:id", topicHandler.GetTopic)
        api.POST("/topics", topicHandler.CreateTopic)

        api.GET("/messages/:id", messageHandler.GetMessage)
        api.GET("/topics/:id/messages", messageHandler.GetTopicMessages) // Добавлен маршрут!
        api.POST("/messages", messageHandler.CreateMessage)
    }

    log.Printf("Server starting on port %s", cfg.Port)
    r.Run(":" + cfg.Port)
}
