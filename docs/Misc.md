### Postgres

`docker run --name symbollab-postgres -v /Users/ianruh/Dev/SymbolLab/Data/postgresql-data:/var/lib/postgresql/data -e POSTGRES_USER=symbollab -e POSTGRES_PASSWORD=************ -d postgres`

### Generate YOLO Data

This relies on the inkscape commandline tool to get jpg of the svg. Make sure to set the path
for inkscape in the make file.