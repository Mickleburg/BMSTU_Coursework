package utils

import (
    "log"
    "github.com/gin-gonic/gin"
)

type ErrorDetail struct {
    Message string      `json:"message"`
    Error   interface{} `json:"error,omitempty"`
}

type Response struct {
    Success bool        `json:"success"`
    Data    interface{} `json:"data,omitempty"`
    Error   *ErrorDetail `json:"error,omitempty"`
}

func SuccessResponse(c *gin.Context, data interface{}) {
    c.JSON(200, Response{
        Success: true,
        Data:    data,
    })
}

func ErrorResponse(c *gin.Context, status int, message string, err error) {
    errorDetail := &ErrorDetail{
        Message: message,
    }

    if err != nil {
        log.Printf("Error: %v", err)
        errorDetail.Error = err.Error()
    }

    c.JSON(status, Response{
        Success: false,
        Error:   errorDetail,
    })
}