Hdf5
====

A REST-based SNP server with an Hdf5 backend

To retrieve individual SNP calls, it implements a simple API based on the following URL structure:
```
/hdf5/get/< row | col >/<dataset>/<name>
```
"dataset" denotes an HDF5 file, name is the column or row name (marker name or accession id).

Returns a JSON structure names and scores as keys and values, in the following data structure:

response = { 
  query: querydata,
  data: responsedata,
};

An 'error' key is present if an error occurs, with the value as the human readable error message. 

Examples: 

* http://hdf5.sgn.cornell.edu/hdf5/get/col/hdf5_test/MARKER_5607

* http://hdf5.sgn.cornell.edu/hdf5/get/row/hdf5_test/39281


List available datasets:

```
/hdf5/datasets
```

JSON: 

response = { 
  datasets: datasetlist
}
