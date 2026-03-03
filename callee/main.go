package main

import (
	_ "context"
	"fmt"
	_ "log"
	_ "net"
	_ "os"
	_ "time"

	_ "google.golang.org/grpc"
	_ "google.golang.org/grpc/reflection"
)

func main() {

	fmt.Println("Starting callee app...")
}
