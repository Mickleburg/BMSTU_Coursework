package config

import (
    "os"
    "fmt"
)

type Config struct {
    DatabaseURL string
    JWTSecret   string
    Port        string
}

func Load() *Config {
    return &Config{
        DatabaseURL: fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
            getEnv("DB_HOST", "localhost"),
            getEnv("DB_PORT", "5432"),
            getEnv("DB_USER", "forumuser"),
            getEnv("DB_PASSWORD", "secret"),
            getEnv("DB_NAME", "forumdb"),
        ),
        JWTSecret: getEnv("JWT_SECRET", "your-secret-key"),
        Port:      getEnv("PORT", "8080"),
    }
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}