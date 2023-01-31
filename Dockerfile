ARG PORT TOKEN
FROM gitpod/openvscode-server:latest
# ----------
USER root
RUN apt-get update
RUN apt-get install -y openssl git curl wget unzip
RUN curl https://rclone.org/install.sh | bash
# ----------
USER openvscode-server
ENV OPENVSCODE_SERVER_ROOT=${OPENVSCODE_SERVER_ROOT}
ENV TOKEN=${TOKEN}
ENV PORT=${PORT}
# ----------
ENV SHELL=/bin/bash
ENV HOME=/home/openvscode-server
# Update PATH env
ENV PATH="$PATH:/home/.openvscode-server/bin"
RUN echo $PATH
# Apply development environment
COPY ./devenv /home/openvscode-server/devenv
# You can add custom software and dependencies for your environment below
# -----------

# Install a VS Code extension:
# RUN openvscode-server --install-extension esbenp.prettier-vscode

# Install apt packages:
# RUN sudo apt-get install -y ubuntu-make

# Copy files: 
# COPY ./tools /home/openvscode-server/tools

# -----------
# Apply VS Code settings
COPY conf/settings.json /tmp/settings.json
# Copy rclone tasks to /tmp, to potentially be used
COPY conf/rclone-tasks.json /tmp/rclone-tasks.json
ADD start.sh /_railway/start.sh
ENTRYPOINT [ "/bin/sh", "/_railway/start.sh" ]
