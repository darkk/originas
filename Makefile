.PHONY: run-psql fill-psql lookup-psql clean

run-psql :
	docker run -v `pwd`:/mnt:ro --rm -ti --name pg-originas -e POSTGRES_PASSWORD=`dd if=/dev/urandom bs=1 count=24 | base64` postgres:10

fill-psql : originas.tsv.psql asn.tsv
	docker exec --user postgres -ti pg-originas psql -f /mnt/fill_psql.sql

lookup-psql : query-ips
	docker exec --user postgres -i pg-originas psql --no-align --field-separator='	' --set="qfile='/mnt/$^'" -f /mnt/lookup_psql.sql

clean :
	rm -f originas.sqlite originas.tsv.psql originas.tsv.sqlite

originas.sqlite : originas.tsv.sqlite
	sqlite3 -echo $@~ <fill_sqlite.sql && mv $@~ $@

originas.tsv.psql : originas.bz2
	# `sort -u` is required as there are some duplicate records
	bzcat originas.bz2 | env ORIGINAS_MODE=PSQL ./originas2tsv.py | sort -uV >$@~ && mv $@~ $@

originas.tsv.sqlite : originas.bz2
	# `sort -u` is required as there are some duplicate records
	bzcat originas.bz2 | env ORIGINAS_MODE=SQLITE ./originas2tsv.py | sort -uV >$@~ && mv $@~ $@

asn.tsv : asn.txt
	sed 's/ /	/' <$^ | iconv -f latin1 -t utf-8 >$@ # only first space is touched

asn.txt :
	wget -O $@ https://ftp.ripe.net/ripe/asnames/asn.txt

originas.bz2 originas.zone :
	wget -O $@ http://archive.routeviews.org/dnszones/$@ # no https :(
