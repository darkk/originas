CREATE TEMPORARY TABLE q (ip inet NOT NULL);

COPY q FROM :qfile;

SELECT ip, origin, asn FROM (
    SELECT 
        ip,
        origin,
        asn,
        MAX(masklen(origin)) OVER (PARTITION BY ip) AS most_specific
    FROM q
    LEFT JOIN originas ON (origin >>= ip)
) t1
WHERE origin IS NULL OR masklen(origin) = most_specific
ORDER BY ip;
