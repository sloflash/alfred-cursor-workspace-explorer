#!/usr/bin/python3

import os
import platform
import sys
from pathlib import PurePath

from Alfred3 import Items, Tools


def get_files(r_path):
    Tools.log(f"Searching for files in: {r_path}")
    file_list = list()
    for root, dirs, files in os.walk(r_path):
        f_lst = ["{0}/{1}".format(root, f) for f in files]
        file_list.extend(f_lst)
    Tools.log(f"Found {len(file_list)} files")
    return file_list


def get_dirs(r_path):
    Tools.log(f"Searching for directories in: {r_path}")
    dir_list = list()
    for p in os.listdir(r_path):
        if os.path.isdir(r_path):
            d = "{0}/{1}".format(r_path, p)
            dir_list.append(d)
    Tools.log(f"Found {len(dir_list)} directories")
    return dir_list


Tools.logPyVersion()
Tools.log("Starting workspace listing process...")

f_path = Tools.getEnv('mypath')
Tools.log(f"Current path from environment: {f_path}")

ws_home = f_path if f_path else os.path.expanduser(Tools.getEnv('workspaces_home'))
Tools.log(f"Workspace home directory: {ws_home}")

p_path = str(PurePath(f_path).parent) if f_path and f_path != Tools.getEnv('workspaces_home') else str()
Tools.log(f"Parent path: {p_path}")

query = Tools.getArgv(1)
Tools.log(f"Search query: '{query}'")

if query == str():
    Tools.log("No query - listing directories")
    it = sorted(get_dirs(ws_home))
else:
    Tools.log("Query present - listing files")
    it = sorted(get_files(ws_home))

wf = Items()
if p_path:
    Tools.log(f"Adding back button to {p_path}")
    wf.setItem(
        title='Back',
        arg=p_path
    )
    wf.setIcon(m_path='back.png', m_type='image')
    wf.addItem()

if len(it) > 0:
    Tools.log(f"Processing {len(it)} items")
    for i in it:
        pp = PurePath(i).stem.lower()
        if (query == str() or query.lower() in PurePath(i).stem.lower()) and not(os.path.basename(i).startswith('.')):
            ic = 'folder.png' if os.path.isdir(i) else 'workspace.png'
            sub = 'Folder' if os.path.isdir(i) else "Workspace in Cursor"
            title = os.path.basename(i)
            # Handle both workspace file types
            title = title.replace('.code-workspace', '').replace('.cursor-workspace', '')
            Tools.log(f"Adding item: {title} ({i})")
            wf.setItem(
                title=title,
                subtitle=f'\u23CE to open {sub}',
                arg=i
            )
            wf.setIcon(m_path=ic, m_type='image')
            wf.addItem()
    if len(wf.getItems(response_type='dict').get('items')) == 0:
        Tools.log("No matching items found")
        wf.setItem(
            title="Search does not match a workspace",
            subtitle="...try again",
            valid=False
        )
        wf.addItem()
else:
    Tools.log("No items found")
    wf.setItem(
        title="No Workspace files or Folders found",
        valid=False
    )
    wf.addItem()

Tools.log("Writing final results")
wf.write()
