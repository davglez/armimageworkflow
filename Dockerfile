FROM --platform=linux/arm64 ubuntu:22.04 AS build_arm64
RUN apt-get update && apt-get install -y --no-install-recommends\
apt-transport-https \
ca-certificates \
curl \
dnsutils \
gnupg \
gnupg2 \
jq \
libc6-dev \
libsodium-dev \
lsb-release \
make \
pkg-config \
software-properties-common \
unzip \
vim \
wget \
xz-utils && \
rm -rf /var/lib/apt/lists/*

FROM build_arm64 AS kubectl_builder

ADD https://dl.k8s.io/release/v1.32.2/bin/linux/arm64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

FROM build_arm64 AS awscli_builder

ADD https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip /awscliv2.zip
RUN unzip /awscliv2.zip && ./aws/install && \
rm -rf /var/lib/apt/lists/* aws /awscliv2.zip

FROM build_arm64 AS final
# Node.js and Quorum Genesis Tool
ARG NODE_VERSION=22.14.0

ADD https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz /node.tar.xz
RUN tar -xJf /node.tar.xz -C /usr/local --strip-components=1 && \
rm /node.tar.xz

ARG QGT_VERSION=0.2.18
RUN npm install -g quorum-genesis-tool@${QGT_VERSION} && npm cache clean --force

# Kubectl
COPY --from=kubectl_builder /usr/local/bin/kubectl /usr/local/bin/kubectl

# AWS CLI
COPY --from=awscli_builder /usr/local/aws-cli /usr/local/aws-cli
COPY --from=awscli_builder /usr/local/bin/aws /usr/local/bin/aws

ENV PATH="/usr/local/aws-cli/v2/current/bin:$PATH"