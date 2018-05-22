Пример того, как можно сравнительно быстро преобразовывать IP-адрес в AS по дампу зоны originas с [routeviews.org](http://archive.routeviews.org/).

- 30ms при использовании sqlite
- 2ms при использовании posgresql

NB: для одного адреса теоретически может быть несколько разных AS, если они указаны указаны как AS-SET для наименьшего покрывающего данный IP адрес префикса.

IP в ASN
========

Подготовка БД:

```
# для sqlite
$ make originas.bz2 && make originas.sqlite
# для postgres
$ make run-psql
$ make originas.bz2 && make fill-psql
```

Поиск адресов:

```
$ time ./lookup.py $(shuf -n 100 sample | sort -V) 
23.253.109.158	23.253.64.0/18	AS33070
47.74.14.56	47.74.0.0/18	AS45102
47.74.21.219	47.74.0.0/18	AS45102
47.254.146.161	47.254.128.0/18	AS45102
[...]
212.71.237.224	212.71.232.0/21	AS63949
212.111.42.144	212.111.40.0/22	AS63949
213.52.128.13	213.52.128.0/23	AS63949

real	0m3.732s
user	0m2.908s
sys	0m0.824s
```

```
$ shuf -n 100 sample >query-ips
$ time make lookup-psql 
docker exec  --user postgres -i pg-originas psql --no-align --field-separator='	' --set="qfile='/mnt/query-ips'" -f /mnt/lookup_psql.sql
CREATE TABLE
COPY 100
ip	origin	asn
23.253.149.26	23.253.128.0/19	27357
47.74.23.84	47.74.0.0/18	45102
47.254.35.224	47.254.32.0/21	45102
47.254.129.145	47.254.128.0/18	45102
47.254.130.24	47.254.128.0/18	45102
47.254.144.74	47.254.128.0/18	45102
...
213.168.250.173	213.168.248.0/22	63949
(100 rows)

real	0m0.312s
user	0m0.020s
sys	0m0.012s
```

ASN в имя AS
============

Можно использовать [JSON API от stat.ripe.net](https://stat.ripe.net/docs/data_api#AsOverview), например, для [AS8997](https://stat.ripe.net/data/as-overview/data.json?resource=AS8997).

Или взять файл asn.txt с https://ftp.ripe.net/ripe/asnames/asn.txt
