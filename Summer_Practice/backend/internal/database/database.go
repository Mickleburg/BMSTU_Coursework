package database

import (
    "database/sql"
    "io/ioutil"
    "path/filepath"
    
    _ "github.com/lib/pq"
)

func Connect(databaseURL string) (*sql.DB, error) {
    db, err := sql.Open("postgres", databaseURL)
    if err != nil {
        return nil, err
    }

    if err := db.Ping(); err != nil {
        return nil, err
    }

    return db, nil
}

func Migrate(db *sql.DB) error {
    migrationFile := filepath.Join("migrations", "001_initial.sql")
    
    content, err := ioutil.ReadFile(migrationFile)
    if err != nil {
        return err
    }

    _, err = db.Exec(string(content))
    return err
}