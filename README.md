Hdf5
====

A REST-based SNP server with a Hdf5 backend

It implements a simple API based on the following URL structure:

/hdf5/get/<row|col>/<file>/<name>

"File" denotes an HDF5 file, name is the column or row name. 

Returns a JSON structure with names and scores as keys and values.
