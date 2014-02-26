#!/bin/bash
if [ -z "$1" ]
  then
    echo "usage : gophercon.sh 3 -- start three new instances"
	exit -1
fi


echo "Getting currently running gophercon containers"
OLDPORTS=( `docker ps | grep gophercon | awk '{print $1}'` )

echo "pulling new version"
docker pull quay.io/bketelsen/gophercon

echo "starting new containers"
for i in `seq 1 $1` ; do
echo "inside loop $1"
	JOB=`docker run -d -p 80 quay.io/bketelsen/gophercon | cut -c1-12`
	echo "adding new container $JOB"
	PORT=`docker inspect $JOB | grep HostPort | cut -d '"' -f 4 | head -1`
	curl http://127.0.0.1:4001/v2/keys/gophercon/upstream/$JOB -XPUT -d value="127.0.0.1:$PORT"
done

echo "removing old containers"
for i in ${OLDPORTS[@]}
do
	echo "removing old container $i"
	etcdctl rm /gophercon/upstream/$i
	confd -onetime
	sleep 1
	docker kill $i
done