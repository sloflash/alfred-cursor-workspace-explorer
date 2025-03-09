#!/bin/bash

# Exit on error
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMP_DIR=$(mktemp -d)
WORKFLOW_NAME="Cursor Workspace Explorer.alfredworkflow"
OUTPUT_PATH="$SCRIPT_DIR/$WORKFLOW_NAME"

echo "Building $WORKFLOW_NAME..."
echo "Output will be saved to: $OUTPUT_PATH"

# Verify source files exist
required_files=(
    "src/info.plist"
    "src/Alfred3.py"
    "src/list.py"
    "src/open.py"
    "src/py3.sh"
    "src/back.png"
    "src/folder.png"
    "src/workspace.png"
    "src/icon.png"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$file" ]; then
        echo "Error: Required file $file not found!"
        exit 1
    fi
done

# Copy all necessary files
for file in "${required_files[@]}"; do
    cp "$SCRIPT_DIR/$file" "$TEMP_DIR/$(basename "$file")"
done

# Make scripts executable
chmod +x "$TEMP_DIR/py3.sh"
chmod +x "$TEMP_DIR/list.py"
chmod +x "$TEMP_DIR/open.py"

# Create the workflow file (zip)
cd "$TEMP_DIR"
zip -r "$OUTPUT_PATH" ./*

# Clean up
cd "$SCRIPT_DIR"
rm -rf "$TEMP_DIR"

# Verify the workflow file was created
if [ -f "$OUTPUT_PATH" ]; then
    echo "Successfully built $WORKFLOW_NAME"
    echo "Workflow file created at: $OUTPUT_PATH"
    echo "File size: $(du -h "$OUTPUT_PATH" | cut -f1)"
else
    echo "Error: Failed to create workflow file!"
    exit 1
fi 