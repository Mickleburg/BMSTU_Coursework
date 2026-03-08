#!/bin/bash
export GOPATH="$(pwd)"
go mod init lenta 2>/dev/null || true   # на случай, если go.mod ещё нет
go get github.com/mgutz/logxi/v1
go get golang.org/x/net/html
go build -o bin/lenta ./src/lenta