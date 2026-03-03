protoc \
  -I proto \
  --plugin=protoc-gen-go=$HOME/go/bin/protoc-gen-go \
  --plugin=protoc-gen-go-grpc=$HOME/go/bin/protoc-gen-go-grpc \
  --go_out=./gen --go_opt=paths=source_relative \
  --go-grpc_out=./gen --go-grpc_opt=paths=source_relative \
  proto/hello.proto