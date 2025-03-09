#!/usr/bin/python3

import os
import sys
import subprocess

from Alfred3 import Tools

Tools.logPyVersion()
Tools.log("Starting workspace opening process...")

f_path = Tools.getEnv('mypath')
Tools.log(f"Path to open: {f_path}")

def open_with_cursor(path):
    """Open a file or directory with Cursor"""
    cursor_path = "/Applications/Cursor.app/Contents/MacOS/Cursor"
    if not os.path.exists(cursor_path):
        Tools.log(f"Error: Cursor not found at {cursor_path}")
        return False
    
    try:
        subprocess.run([cursor_path, path], check=True)
        Tools.log(f"Successfully opened {path} with Cursor")
        return True
    except subprocess.CalledProcessError as e:
        Tools.log(f"Error opening with Cursor: {e}")
        return False

if os.path.isdir(f_path):
    Tools.log(f"Opening directory: {f_path}")
    if open_with_cursor(f_path):
        sys.stdout.write("DIR")
    else:
        sys.stdout.write("ERROR")
elif (f_path.endswith(".code-workspace") or f_path.endswith(".cursor-workspace")) and os.path.isfile(f_path):
    Tools.log(f"Opening workspace file: {f_path}")
    if open_with_cursor(f_path):
        sys.stdout.write("FILE")
    else:
        sys.stdout.write("ERROR")
else:
    Tools.log(f"Invalid path or file type: {f_path}")
    sys.stdout.write("ERROR")
