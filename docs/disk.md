# Disk
Provides functions for file reading and writing, and path utility functions.
Some paths are different than others. For instance, the directories seen at `'/'`
are "drives", and the paths under `/rom/` are read-only.

## Path functions
### disk.getParts ( path )

### disk.getPath ( path )

### disk.getFilename ( path )

### disk.getExtension ( path )

### disk.getDrive ( path )

### disk.absolute ( [path] )

### disk.getDrives ( )

---
## Reading functions
### disk.list ( [path [, showHidden]] )

### disk.read ( [path] )

### disk.readLines ( [path] )

### disk.<span></span>info ( [path] ) <!-- use <span></span> to prevent auto linking -->

### disk.exists ( [path] )

---
## Writing functions
### disk.write ( [path [, data]] )

### disk.append ( path, data )

### disk.mkdir ( [path] )

### disk.newFile ( [path] )

### disk.remove ( [path] )
