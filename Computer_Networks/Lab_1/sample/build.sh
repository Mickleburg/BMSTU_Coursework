#!/bin/bash
export GOPATH=`pwd`
export GO111MODULE=on
go get github.com/mgutz/logxi/v1
go get github.com/skorobogatov/input
go install ./src/client
go install ./src/server
