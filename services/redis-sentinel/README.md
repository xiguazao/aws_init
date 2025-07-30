docker compose up -d     
docker ps
docker logs redis-sentinel1

docker exec -it redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

docker logs redis-sentinel1

docker stop redis-master




docker exec redis-sentinel1 redis-cli -p 26379 sentinel master mymaster
docker exec redis-slave1 redis-cli info replication
docker exec redis-slav2 redis-cli info replication
docker exec redis-slave2 redis-cli info replicati

