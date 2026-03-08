package models

import "time"

type Message struct {
    ID        int       `json:"id" db:"id"`
    TopicID   int       `json:"topic_id" db:"topic_id"`
    AuthorID  int       `json:"author_id" db:"author_id"`
    Author    *User     `json:"author,omitempty"`
    Content   string    `json:"content" db:"content"`
    ParentID  *int      `json:"parent_id" db:"parent_id"`
    CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type CreateMessageRequest struct {
    TopicID  int    `json:"topic_id" binding:"required"`
    Content  string `json:"content" binding:"required,min=1"`
    ParentID *int   `json:"parent_id"`
}