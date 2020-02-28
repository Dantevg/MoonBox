# Disk
Provides functions for file reading and writing, and path utility functions.
Some paths are different than others. For instance, the directories seen at `'/'`
are "drives", and the paths under `/rom/` are read-only.

## Path functions
### disk.getParts ( path )
Breaks `path` up in parts, separated by `'/'`.
Returns a table containing the parts.

### disk.getPath ( path )
Returns the path leading to the given file or folder.

### disk.getFilename ( path )
Returns the filename (the part after the last `'/'`) of `path`.

### disk.getExtension ( path )
Returns the extension of `path`, which is everything after the last `'.'`, *including the dot itself*.

### disk.getDrive ( path )
Returns the drive in which `path` is located,
or `'/'` when not in a drive.

### disk.absolute ( [path] )
Returns the absolute version of `path`.

### disk.getDrives ( )
Returns all available drives.
This is almost the same thing as `disk.list("/")`,
but including the root path `/`.

---
## Reading functions
### disk.list ( path [, showHidden] )
Returns a table with all files and folders under `path`,
which must be a dir. When `showHidden` is given,
also returns hidden files and folders (starting with a dot).

### disk.read ( path )
Returns the contents of the file located at `path`,
which must lead to a file.

### disk.readLines ( path )
The same as `disk.read`, except it returns a table with all lines from the file.

### disk.<span></span>info ( path ) <!-- use <span></span> to prevent auto linking -->
Returns a table containing the following elements:
- `type`, either `"dir"` or `"file"`.
- `size`, the size of the file in bytes.
- `modified`, the timestamp of the last modification.

When no file or dir exists at `path`, returns a table with `false`, `0` and `0`, respectively.

### disk.exists ( path )
Returns whether `path` leads to an existing file or dir.

---
## Writing functions
### disk.write ( path [, data] )
Writes `data` to the file at `path`.

### disk.append ( path [, data] )
The same as `disk.write`, except it doesn't overwrite
any file contents, but it appends them at the end.

### disk.mkdir ( path )
Creates a dir at `path`.

### disk.newFile ( path )
Creates a new empty file at `path`.

### disk.remove ( path )
Removes the file or *empty* dir at `path`.
Currently, it can't remove non-empty folders.