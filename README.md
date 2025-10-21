# FedBench HeFQUIN

This project is intended to be used as a benchmark for analyzing the behavior of the HeFQUIN engine under various conditions.

## Setup
Download the data by running:
```bash
./download.sh
```

This will download the following files:
- https://users.iit.demokritos.gr/~gmouchakis/dumps/ChEBI.tar.gz
- https://users.iit.demokritos.gr/~gmouchakis/dumps/DrugBank.tar.gz
- https://users.iit.demokritos.gr/~gmouchakis/dumps/KEGG.tar.gz
- https://users.iit.demokritos.gr/~gmouchakis/dumps/GeoNames.tar.gz
- https://users.iit.demokritos.gr/~gmouchakis/dumps/Jamendo.tar.gz
- https://users.iit.demokritos.gr/~gmouchakis/dumps/LMDB.tar.gz
- https://users.iit.demokritos.gr/~gmouchakis/dumps/NYT.tar.gz
- https://users.iit.demokritos.gr/~gmouchakis/dumps/SWDFood.tar.gz
- https://users.iit.demokritos.gr/~gmouchakis/dumps/DBPedia-Subset.tar.gz
- https://www.ida.liu.se/~robke04/dump/SP2B.tar.gz
(Generated from the source code with a value of 10M)

# Run Virtuoso
Start Virtuoso:
```bash
docker compose up virtuoso -d
```

and run the loader:
```bash
docker compose up loader
```

Verify that no errors are reported (especially when loading DBPedia, since it can be problematic).
