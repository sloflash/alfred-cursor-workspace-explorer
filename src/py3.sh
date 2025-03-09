#!/bin/bash
#Set to 0 to use the first Python3 version found
PREFER_LATEST=0

# Enable debug output
DEBUG=1

#Array of python3 paths
PYPATHS=(
    /usr/bin
    /usr/local/bin
    /opt/homebrew/bin
    /opt/local/bin
    "$HOME/.pyenv/shims"
    "$HOME/Library/Python/3.*/bin"
    "/Library/Frameworks/Python.framework/Versions/3.*/bin"
)

log_debug() {
    [ "$DEBUG" = "1" ] && echo "DEBUG: $*" >&2
}

#Input arguments
SCR="${1}"
QUERY="${2}"
WF_DATA_DIR="${alfred_workflow_data:-$HOME/.alfred-workflow-data}"

log_debug "Script: $SCR"
log_debug "Query: $QUERY"
log_debug "Workflow data dir: $WF_DATA_DIR"

#Create wf data dir if not available with proper permissions
if [ ! -d "$WF_DATA_DIR" ]; then
    log_debug "Creating workflow data directory: $WF_DATA_DIR"
    mkdir -p "$WF_DATA_DIR"
    chmod 755 "$WF_DATA_DIR"
fi

SCRPATH="$0"
SCRIPT_DIR="$(dirname "$SCRPATH")"

#Cache file for python binary
PYALIAS="$WF_DATA_DIR/py3"

CONFIG_PREFIX="Config"

pyrun() {
    log_debug "Running python script with: $py3 ${SCR} ${QUERY}"
    $py3 "${SCR}" "${QUERY}"
    RES=$?
    [[ $RES -eq 127 ]] && handle_py_notfound
    return $RES
}

handle_py_notfound() {
    log_debug "python3 configuration changed, attempting to reconfigure"
    setup_python_alias
}

verify_not_stub() {
    PYBIN="${1}"
    log_debug "Verifying python at: $PYBIN"
    if [ ! -f "$PYBIN" ]; then
        log_debug "Python binary not found at: $PYBIN"
        return 1
    fi
    if ! "$PYBIN" -V &> /dev/null; then
        log_debug "Python verification failed for: $PYBIN"
        return 1
    fi
    log_debug "Python verified at: $PYBIN"
    return 0
}

getver() {
    PYBIN="${1}"
    VER=$("$PYBIN" -V 2>&1 | cut -f2 -d" " | sed -E 's/\.([0-9]+)$/\1/')
    echo "$VER"
    log_debug "Version for $PYBIN: $VER"
}

make_alias() {
    PYBIN="${1}"
    PYVER="$2"
    #last sanitization
    [ -z "${PYBIN}" ] && log_msg "Error: invalid python3 path" && exit 255
    [ -z "${PYVER}" ] && PYVER="$(getver "$PYBIN")"
    echo "export py3='$PYBIN'" > "$PYALIAS"
    chmod +x "$PYALIAS"
    log_debug "Created Python alias at $PYALIAS for $PYBIN"
    # After creating alias, source it and run the script
    . "$PYALIAS"
    pyrun
}

log_msg() {
    log_json "$CONFIG_PREFIX: $1" "$2"
    log_debug "$1"
}

log_json() {
    title="$1"
    sub="$2"
    [ -z "$sub" ] && sub="$title"
    cat <<EOF
{
    "items": [
        {
            "title": "$title",
            "subtitle": "$sub"
        }
    ]
}
EOF
}

setup_python_alias() {
    log_debug "Starting Python search..."
    
    # First try the system Python3
    if [ -f "/usr/bin/python3" ] && verify_not_stub "/usr/bin/python3"; then
        log_debug "Found system Python3"
        make_alias "/usr/bin/python3"
        return 0
    fi
    
    # Then try python3 from PATH
    if command -v python3 &> /dev/null; then
        python3_path=$(command -v python3)
        log_debug "Found python3 in PATH at: $python3_path"
        if verify_not_stub "$python3_path"; then
            make_alias "$python3_path"
            return 0
        fi
    fi
    
    # Then try our predefined paths
    for p in "${PYPATHS[@]}"; do
        log_debug "Checking path: $p"
        if [ -f "$p/python3" ] && verify_not_stub "$p/python3"; then
            make_alias "$p/python3"
            return 0
        fi
    done
    
    log_debug "No valid Python installation found"
    log_msg "Error: no valid python3 version found" "Please ensure Python 3 is installed and accessible"
    exit 255
}

#Main
if [ -f "$PYALIAS" ]; then
    log_debug "Found existing Python alias at: $PYALIAS"
    . "$PYALIAS"
    pyrun
else
    log_debug "No Python alias found, searching for Python..."
    setup_python_alias
fi