package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pb "github.com/axodevelopment/grpc-mesh-grpc/gen/hello/v1"
)

func main() {
	target := getenv("CALLEE_ADDR", "callee:50051")
	httpPort := getenv("HTTP_PORT", "8080")

	// NOTE: App uses plaintext gRPC to Service DNS.
	// Mesh sidecars handle mTLS between proxies (no app code change). :contentReference[oaicite:4]{index=4}
	conn, err := grpc.Dial(target, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer conn.Close()

	client := pb.NewHelloServiceClient(conn)

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(200) })
	mux.HandleFunc("/call", func(w http.ResponseWriter, r *http.Request) {
		name := r.URL.Query().Get("name")
		if name == "" {
			name = "mesh"
		}

		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()

		resp, err := client.SayHello(ctx, &pb.HelloRequest{Name: name})
		if err != nil {
			http.Error(w, fmt.Sprintf("grpc error: %v", err), 500)
			return
		}
		w.Header().Set("content-type", "text/plain")
		_, _ = w.Write([]byte(resp.GetMessage() + "\n"))
	})

	log.Printf("caller http listening on :%s (grpc target=%s)", httpPort, target)
	if err := http.ListenAndServe(":"+httpPort, mux); err != nil {
		log.Fatalf("http serve: %v", err)
	}
}

func getenv(k, def string) string {
	v := os.Getenv(k)
	if v == "" {
		return def
	}
	return v
}
