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
$ time ./lookup_sqlite.py $(shuf -n 100 sample | sort -V) 
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

Или взять файл [asn.txt с ftp.ripe.net](https://ftp.ripe.net/ripe/asnames/asn.txt) и импортировать его в БД.

Полнота данных
==============

Дамп с routeviews на 22 мая 2018 г. включает в себя 60674 AS и 712961 префикс.

Дамп asn.txt содержит информацию о 87637, включая AS геокодированые США, странами Африки и т.п., т.е. он включает в себя не только европейские сети региона RIPE NCC.

На первый взгляд, полнота этих данных достаточна для практического применения "примерно узнать, в какой сети очередной забаненный РКН IP адрес".

Но я кэширую whois!
===================

> There are only two hard things in Computer Science: cache invalidation and naming things.

Кэширование whois вместо использования данных маршрутизации может привести к забавным багам.

Представим, что адрес `8.8.254.254` был забанен РКН. `whois` припишет ему префикс `8.0.0.0/9` и имя asn `Level 3 Parent, LLC`. В кэш эта информация будет сохранена и последующий поиск адреса `8.8.8.8` припишет его также `Level 3`, что неверно.

При поиске по данным маршрутизации, ответ будет более точный:

```
$ docker exec --user postgres -it pg-originas psql -c "select * from originas join asn using(asn) where '8.8.254.254'::inet <<= origin"
 asn  |   origin   |              asname
------+------------+----------------------------------
 3356 | 8.0.0.0/12 | LEVEL3 - Level 3 Parent, LLC, US
(1 row)

$ docker exec --user postgres -it pg-originas psql -c "select * from originas join asn using(asn) where '8.8.8.8'::inet <<= origin"
  asn  |   origin   |              asname
-------+------------+----------------------------------
 15169 | 8.8.8.0/24 | GOOGLE - Google LLC, US
  3356 | 8.0.0.0/12 | LEVEL3 - Level 3 Parent, LLC, US
(2 rows)
```

Не всё так однозначно...
========================

К сожалению, использование AS-SET (группы автономных систем, объединенных для
маршрутизации) может порождать неоднозначности, когда один и тот же минимальный
покрывающий IP-адрес префикс может быть приписан разным AS. Например `20.134.1.42`:

```
$ docker exec --user postgres -it pg-originas psql -c "select * from originas join asn using(asn) where '20.134.1.42'::inet <<= origin"
  asn  |    origin     |                      asname
-------+---------------+---------------------------------------------------
 17916 | 20.134.0.0/20 | CSC-IGN-AUNZ-AP Computer Sciences Corporation, AU
  7474 | 20.134.0.0/20 | OPTUSCOM-AS01-AU SingTel Optus Pty Ltd, AU
(2 rows)
```

Хорошего рецепта для разрешения подобных неоднозначностей у меня нет.

Такой адрес смущает и [RIPE Stat](https://stat.ripe.net/20.134.1.42#tabId=routing): какие-то из полей утверждают, что _168 peers announcing 20.134.0.0/20 originated by AS0_, а виджет _Prefix Routing Consistency_ показывает уровень бардака.
