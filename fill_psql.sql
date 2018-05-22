BEGIN;

CREATE TABLE originas (
    origin  cidr    NOT NULL,
    asn     int4    NOT NULL
);

COPY originas FROM '/mnt/originas.tsv.psql';

CREATE INDEX ON originas USING gist (origin inet_ops);

ANALYZE originas;

COMMIT;
