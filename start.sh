#!/bin/bash

# sometimes HOME DIR may not be right :(
HOME_PATH="/home/openvscode-server"

START_DIR="${START_DIR:-$HOME_PATH/project}"

PREFIX="OpenVSCode-Server"

OPENVSCODE_USER_PATH="$HOME_PATH/.openvscode-server/data/User"

[ -d "$OPENVSCODE_USER_PATH" ] || mkdir -p $OPENVSCODE_USER_PATH

OPENVSCODE_MACHINE_PATH="$HOME_PATH/.openvscode-server/data/Machine"

[ -d "$OPENVSCODE_MACHINE_PATH" ] || mkdir -p $OPENVSCODE_MACHINE_PATH

mkdir -p $START_DIR

# function to clone the git repo or add a user's first file if no repo was specified.
project_init () {
    [ -z "${GIT_REPO}" ] && echo "[$PREFIX] No GIT_REPO specified" && echo $(date) > $START_DIR/start.txt || git clone $GIT_REPO $START_DIR
}

# add rclone config and start rclone, if supplied
if [[ -z "${RCLONE_DATA}" ]]; then
    echo "[$PREFIX] RCLONE_DATA is not specified. Files will not persist"

    # start the project
    project_init

else
    echo "[$PREFIX] Copying rclone config..."
    mkdir -p $HOME_PATH/.config/rclone/
    touch $HOME_PATH/.config/rclone/rclone.conf
    echo $RCLONE_DATA | base64 -d > $HOME_PATH/.config/rclone/rclone.conf

    # default to true
    RCLONE_VSCODE_TASKS="${RCLONE_VSCODE_TASKS:-true}"
    RCLONE_AUTO_PUSH="${RCLONE_AUTO_PUSH:-true}"
    RCLONE_AUTO_PULL="${RCLONE_AUTO_PULL:-true}"

    if [ $RCLONE_VSCODE_TASKS = "true" ]; then
        # copy our tasks config to VS Code
        echo "[$PREFIX] Applying VS Code tasks for rclone"
        cp /tmp/rclone-tasks.json $OPENVSCODE_USER_PATH/tasks.json
        # install the extension to add to menu bar
        $OPENVSCODE_SERVER_ROOT/bin/openvscode-server --install-extension actboy168.tasks&
    else
        # user specified they don't want to apply the tasks
        echo "[$PREFIX] Skipping VS Code tasks for rclone"
    fi



    # Full path to the remote filesystem
    RCLONE_REMOTE_PATH=${RCLONE_REMOTE_NAME:-code-server-remote}:${RCLONE_DESTINATION:-code-server-files}
    RCLONE_SOURCE_PATH=${RCLONE_SOURCE:-$START_DIR}
    echo "rclone sync $RCLONE_SOURCE_PATH $RCLONE_REMOTE_PATH $RCLONE_FLAGS -vv" > $HOME_PATH/push_remote.sh
    chmod +x $HOME_PATH/push_remote.sh
    echo "rclone sync $RCLONE_REMOTE_PATH $RCLONE_SOURCE_PATH $RCLONE_FLAGS -vv" > $HOME_PATH/pull_remote.sh
    chmod +x $HOME_PATH/pull_remote.sh

    if rclone ls $RCLONE_REMOTE_PATH; then

        if [ $RCLONE_AUTO_PULL = "true" ]; then
            # grab the files from the remote instead of running project_init()
            echo "[$PREFIX] Pulling existing files from remote..."
            $HOME_PATH/pull_remote.sh&
        else
            # user specified they don't want to apply the tasks
            echo "[$PREFIX] Auto-pull is disabled"
        fi

    else

        if [ $RCLONE_AUTO_PUSH = "true" ]; then
            # we need to clone the git repo and sync
            echo "[$PREFIX] Pushing initial files to remote..."
            project_init
            $HOME_PATH/push_remote.sh&
        else
            # user specified they don't want to apply the tasks
            echo "[$PREFIX] Auto-push is disabled"
        fi

    fi

fi

# Add dotfiles, if set
if [ -n "$DOTFILES_REPO" ]; then
    # grab the files from the remote instead of running project_init()
    echo "[$PREFIX] Cloning dotfiles..."
    # mkdir -p $HOME/dotfiles
    mkdir -p $HOME_PATH/dotfiles
    git clone $DOTFILES_REPO $HOME/dotfiles

    DOTFILES_SYMLINK="${RCLONE_AUTO_PULL:-true}"

    # symlink repo to $HOME
    if [ $DOTFILES_SYMLINK = "true" ]; then
        shopt -s dotglob
        ln -sf source_file $HOME/dotfiles/* $HOME
    fi

    # run install script, if it exists
    # [ -f "$HOME/dotfiles/install.sh" ] && $HOME/dotfiles/install.sh
    [ -f "$HOME_PATH/dotfiles/install.sh" ] && $HOME_PATH/dotfiles/install.sh
fi

echo "[$PREFIX] Starting code-server..."
# Now we can run code-server with the default entrypoint
# /usr/bin/entrypoint.sh --bind-addr 0.0.0.0:8080 $START_DIR

# custom VS Code settings 
echo "[$PREFIX] Applying VS Code settings"
cp /tmp/settings.json $OPENVSCODE_MACHINE_PATH/settings.json

exec $OPENVSCODE_SERVER_ROOT/bin/openvscode-server --port $PORT --connection-token "${TOKEN:-$(openssl rand -hex 32)}" --host 0.0.0.0 -- $*