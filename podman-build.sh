podman build -f callee/Containerfile -t quay.io/axodevelopment/grpc_callee .

podman build -f caller/Containerfile -t quay.io/axodevelopment/grpc_caller .