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

The FedBench datasets can be hosted using multiple configurations depending on the requirements. For exposing all `FedBench` datasets using both `SPARQL` and `TPF/brTPF` interfaces, navigate to `experiments/all-endpoints` and run `docker compose up`.


## Endpoint Overview

This deployment exposes two types of federation-accessible endpoints:

- **brTPF/TPF endpoints** (under `/ldf/...`)
- **SPARQL endpoints** (under `/sparql/.../`)

All endpoints are reverse-proxied through Nginx on:

```
http://localhost:8080/
```

---

## brTPF / TPF Endpoints

Each dataset is available as a Triple Pattern Fragment (TPF) or brTPF endpoint at:

```
/ldf/<dataset>
```

| Dataset  | Endpoint |
|----------|----------|
| chebi    | http://localhost:8080/ldf/chebi |
| dbpedia  | http://localhost:8080/ldf/dbpedia |
| drugbank | http://localhost:8080/ldf/drugbank |
| geonames | http://localhost:8080/ldf/geonames |
| jamendo  | http://localhost:8080/ldf/jamendo |
| kegg     | http://localhost:8080/ldf/kegg |
| lmdb     | http://localhost:8080/ldf/lmdb |
| nyt      | http://localhost:8080/ldf/nyt |
| sp2b     | http://localhost:8080/ldf/sp2b |
| swdfood  | http://localhost:8080/ldf/swdfood |

Each endpoint forwards to the internal LDF server on port `3000`.

---

## SPARQL Endpoints

Each dataset is also exposed as a SPARQL endpoint at:

```
/sparql/<dataset>/
```

| Dataset  | Endpoint |
|----------|----------|
| chebi    | http://localhost:8080/sparql/chebi/ |
| dbpedia  | http://localhost:8080/sparql/dbpedia/ |
| drugbank | http://localhost:8080/sparql/drugbank/ |
| geonames | http://localhost:8080/sparql/geonames/ |
| jamendo  | http://localhost:8080/sparql/jamendo/ |
| kegg     | http://localhost:8080/sparql/kegg/ |
| lmdb     | http://localhost:8080/sparql/lmdb/ |
| nyt      | http://localhost:8080/sparql/nyt/ |
| sp2b     | http://localhost:8080/sparql/sp2b/ |
| swdfood  | http://localhost:8080/sparql/swdfood/ |

Each endpoint forwards to a Virtuoso SPARQL service on port `8890`.

---

