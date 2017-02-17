# alpine-cassandra
Cassandra using latest JRE on Alpine - Single node cluster 

## To build cassandra and cqlsh images

```
$ docker build -t shiva/alpine-cassandra --build-arg proxy=$http_proxy .
$ docker build -t shiva/cqlsh --build-arg proxy=$http_proxy --file cqlsh.Dockerfile .
```

## Run an instance of cassandra
```
$ docker run --name c1 -d shiva/alpine-cassandra 
```
## Run an cqlsh, for a client to cassandra. Once you get the prompt

```
$ docker run -it --link c1:c1 --rm shiva/cqlsh bash
bash> cqlsh c1
```

