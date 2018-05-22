CREATE TABLE IF NOT EXISTS originas (
    netaddr text    not null,
    netmask integer not null,
    asn     integer not null,
    ip_hi   integer not null,
    ip_lo   integer not null
);

.separator "	"
.import originas.tsv.sqlite originas

-- 1. ip_lo is not completely ignored
-- 2. making index covered one makes things worse
CREATE INDEX IF NOT EXISTS originas_hilo ON originas (ip_hi, ip_lo);
