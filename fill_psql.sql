BEGIN;

DROP TABLE IF EXISTS originas;

CREATE TABLE originas (
    origin  cidr    NOT NULL,
    asn     int4    NOT NULL
);

COPY originas FROM '/mnt/originas.tsv.psql';

CREATE INDEX ON originas USING gist (origin inet_ops);

ANALYZE originas;

DROP TABLE IF EXISTS asn;

CREATE TABLE asn (
    asn     int4 PRIMARY KEY NOT NULL,
    asname  text NOT NULL
);

COPY asn FROM '/mnt/asn.tsv';

COMMIT;
