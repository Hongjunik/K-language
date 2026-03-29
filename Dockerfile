FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        nasm \
        binutils \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . .

RUN chmod +x scripts/build.sh

CMD ["bash", "-lc", "bash scripts/build.sh && cat build/program_output.txt"]
