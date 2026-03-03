package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	pb "github.com/axodevelopment/grpc-mesh-grpc/gen/hello/v1"
)

type server struct {
	pb.UnimplementedHelloServiceServer
	pod string
}

func (s *server) SayHello(ctx context.Context, req *pb.HellowRequest) (*pb.HelloReply, error) {
	msg := fmt.Sprintf("hello %q from callee pod=%s time=%s", req.GetName(), s.pod, time.Now().Format(time.RFC3339))
	log.Printf("SayHello: %s", msg)
	return &pb.HelloReply{Message: msg}, nil
}

func main() {
	fmt.Println("Starting callee app...")

	port := getenv("PORT", "50051")
	pod := getenv("POD_NAME", "unknown")

	lis, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatalf("listen: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterHelloServiceServer(s, &server{pod: pod})
	reflection.Register(s)

	log.Printf("callee listening on :%s", port)
	if err := s.Serve(lis); err != nil {
		log.Fatalf("serve: %v", err)
	}
}

func getenv(k, def string) string {
	v := os.Getenv(k)
	if v == "" {
		return def
	}
	return v
}
