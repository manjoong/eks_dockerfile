FROM alpine:3.7

ENV GOPATH /go

ENV GOLANG_VERSION 1.9.4
ENV GOLANG_SRC_URL https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz
ENV GOLANG_SRC_SHA256 0573a8df33168977185aa44173305e5a0450f55213600e94541604b75d46dc06

ENV TERRAFORM_VERSION 0.12.23

ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN apk add --no-cache \
    curl \
    unzip \
    git \
    bash \
    jq \
    openssl \
    python \
    openssh \
    openrc

RUN set -ex \
	&& apk update \
	&& apk add --no-cache ca-certificates  \
	&& apk add --no-cache --virtual .build-deps \
	&& apk add bash gcc musl-dev openssl zip make bash git go curl py-pip \
	&& curl -s https://raw.githubusercontent.com/docker-library/golang/221ee92559f2963c1fe55646d3516f5b8f4c91a4/1.9/alpine3.7/no-pic.patch -o /no-pic.patch \
	&& cat /no-pic.patch \
	&& export GOROOT_BOOTSTRAP="$(go env GOROOT)" \
	&& wget -q "$GOLANG_SRC_URL" -O golang.tar.gz \
	&& echo "$GOLANG_SRC_SHA256  golang.tar.gz" | sha256sum -c - \
	&& tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz \
	&& cd /usr/local/go/src \
	&& patch -p2 -i /no-pic.patch \
	&& ./make.bash \
        && rm -rf /*.patch \
	&& apk del .build-deps

ADD ./provision_eks.tar /root


RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

WORKDIR $GOPATH/bin

RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

RUN unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip

RUN chmod +x terraform

RUN rm -rf terraform_${TERRAFORM_VERSION}_linux_amd64.zip

#---

RUN mkdir /var/run/sshd

RUN echo 'root:skcc6400skcc' | chpasswd


RUN rc-update add sshd

RUN rc-status

RUN touch /run/openrc/softlevel

RUN /etc/init.d/sshd start

RUN sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config

RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

RUN /etc/init.d/sshd restart

RUN rc-status



#---


WORKDIR "/root"

RUN apk --no-cache add gettext ca-certificates openssl \
	&& wget https://storage.googleapis.com/kubernetes-release/release/v1.13.6/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
        && chmod a+x /usr/local/bin/kubectl

RUN pip install awscli

RUN curl -Ls https://api.github.com/repos/kubernetes-incubator/metrics-server/tarball/v0.3.6 -o metrics-server-0.3.6.tar.gz

RUN curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator \
    & wait \
    && chmod +x ./aws-iam-authenticator \
    && mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator \
    && echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc


RUN echo 'root:skcc6400skcc' | chpasswd





#COPY eks /root/

RUN mkdir -p ~/.kube


