package models

import "time"

type Topic struct {
    ID        int       `json:"id" db:"id"`
    Title     string    `json:"title" db:"title"`
    AuthorID  int       `json:"author_id" db:"author_id"`
    Author    *User     `json:"author,omitempty"`
    Rules     string    `json:"rules" db:"rules"`
    CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type CreateTopicRequest struct {
    Title string `json:"title" binding:"required,min=1,max=128"`
    Rules string `json:"rules"`  
}
