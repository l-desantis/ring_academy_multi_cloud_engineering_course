docker stop order_service
docker rm order_service
docker run -d --name order_service order_service:latest