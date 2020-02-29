# Programs
These programs are located in `/rom/programs`. This path is added to `shell.path`,
so you don't have to specify the path when in the shell.

### about
Shows information about MoonBox, in a neofetch-like style.

### cd \<path>
Changes the current directory.

### clear
Clears the screen.

### cp \<source> \<destination>
When `destination` leads to a (nonexisting) file,
copies the file from `source` to `destination`.  
When it leads to an existing folder,
copies the file to that folder, keeping the original name.

### edit \<path>
Text editing program.

### help
Displays help.

### hexview
Displays file in binary and hexadecimal notation,
useful for viewing files like `.png`.

### info

### ls [path] [-h]
Lists all files and folders at `path`, or the current directory.
When `-h` is present, also lists hidden files.

### lua [-g, --global]
Interactive Lua prompt. When `-g` or `--global` is present,
the code is executed in the global env.

### mkdir \<path>
Creates a directory.

### mv \<source> \<destination>
Equal to `cp`, but doesn't keep the original file.

### paint [file], &nbsp;&nbsp; paint --new \<w> \<h>, &nbsp;&nbsp; paint --exportresources [--encode64] \<path>
Image editing prgram. Opens `file`, or when `--new` is present,
creates a new image with given dimensions.
`--exportresources` exports the images for the brushes,
embedded in the program, (optionally base64-encoded) to `path`.

### reboot
Reboots MoonBox.

### rename \<from> \<to>
Renames the file or folder at `from` to `to`.

### rm \<path>
Removes the file or *empty* folder at `path`.

### shutdown
Shuts down MoonBox.