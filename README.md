# HeFQUIN FedBench

This project is intended to provide an easy-to-use benchmark for analyzing the behavior of the HeFQUIN engine under various conditions.


## Getting started

Download and clean up the FedBench data using:
```bash
./prepare_fedbench_datasets.sh
``` 
This will take around 15 minutes to complete but only needs to be executed once.

Next, prepared the HDT files that will be used by the LDF servers. Navigate to `hdt-converter` and run:
```bash
docker compose up
```
This will convert each of the datasets into a single `.hdt` that can be used by the LDF endpoints.

## Running the servers

The FedBench datasets can be hosted using multiple configurations depending on the requirements. The different options are described below:

### Run as a single Virtuoso endpoint
The dataset can be run in a single SPARQL endpoint with the datasets made available as named graphs. Navigate to 

`experiments/virtuoso-named-graphs` and run:
```bash
docker compose up
```

This will expose a single Virtuoso endpoint available at `http://localhost:8890/sparql`. The named graphs are listed below: 
- http://example.org/graph/chebi
- http://example.org/graph/dbpedia
- http://example.org/graph/drugbank
- http://example.org/graph/geonames
- http://example.org/graph/jamendo
- http://example.org/graph/kegg
- http://example.org/graph/lmdb
- http://example.org/graph/nyt
- http://example.org/graph/sp2b
- http://example.org/graph/swdfood

This configuration is useful for establishing a source assignment for the FedBench queries, since the named graphs can be bound to variables.

### Run as SPARQL endpoints
The datasets can be hosted in separate SPARQL endpoints. Navigate to `experiments/virtuoso-endpoints` and run:
```bash
docker compose up
```
A proxy container will make the containers available at the following endpoints:

- http://sparql.chebi.localhost
- http://sparql.dbpedia.localhost
- http://sparql.drugbank.localhost
- http://sparql.geonames.localhost
- http://sparql.jamendo.localhost
- http://sparql.kegg.localhost
- http://sparql.lmdb.localhost
- http://sparql.nyt.localhost
- http://sparql.sp2b.localhost
- http://sparql.swdfood.localhost

### Run as LDF server endpoints
The datasets can be hosted in separate LDF endpoints that support both `TPF` and `brTPF` by default. Navigate to `experiments/ldf-endpoints` and run:
```bash
docker compose up
```
A proxy container will make the containers available at the following endpoints:

- http://ldf.chebi.localhost
- http://ldf.dbpedia.localhost
- http://ldf.drugbank.localhost
- http://ldf.geonames.localhost
- http://ldf.jamendo.localhost
- http://ldf.kegg.localhost
- http://ldf.lmdb.localhost
- http://ldf.nyt.localhost
- http://ldf.sp2b.localhost
- http://ldf.swdfood.localhost


### Run both SPARQL and LDF endpoints
The datasets can be hosted as both SPARQL and LDF endpoints in parallell. Navigate to `experiments/all-endpoints` and run:
```bash
docker compose up
```
A proxy container will make the SPARQL endpoints available at:

- http://sparql.chebi.localhost
- http://sparql.dbpedia.localhost
- http://sparql.drugbank.localhost
- http://sparql.geonames.localhost
- http://sparql.jamendo.localhost
- http://sparql.kegg.localhost
- http://sparql.lmdb.localhost
- http://sparql.nyt.localhost
- http://sparql.sp2b.localhost
- http://sparql.swdfood.localhost

A proxy container will make the LDF endpoints available at:

- http://ldf.chebi.localhost
- http://ldf.dbpedia.localhost
- http://ldf.drugbank.localhost
- http://ldf.geonames.localhost
- http://ldf.jamendo.localhost
- http://ldf.kegg.localhost
- http://ldf.lmdb.localhost
- http://ldf.nyt.localhost
- http://ldf.sp2b.localhost
- http://ldf.swdfood.localhost