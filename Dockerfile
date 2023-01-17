ARG PORT TOKEN
FROM gitpod/openvscode-server:latest
USER root
RUN apt-get install -y openssl git curl wget
USER openvscode-server
ENV OPENVSCODE_SERVER_ROOT=${OPENVSCODE_SERVER_ROOT}
ENV TOKEN=${TOKEN}
ENV PORT=${PORT}
ADD start.sh /_railway/start.sh
ENTRYPOINT [ "/bin/sh", "/_railway/start.sh" ]
