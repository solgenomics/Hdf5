Hdf5
====

A REST-based SNP server with a Hdf5 backend

It implements a simple API based on the following URL structure:

/hdf5/get/&lt;row|col&gt;/&lt;dataset&gt;/&lt;name&gt;

"dataset" denotes an HDF5 file, name is the column or row name. 

Returns a JSON structure names and scores as keys and values, in the following data structure:

response = { 
  query: querydata,
  data: responsedata,
};
An 'error' key is present if an error occurs, with the value as the human readable error message. 

List available datasets:
/hdf5/datasets
JSON: 
response = { 
  datasets: datasetlist
}
