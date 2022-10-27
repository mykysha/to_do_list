run:
	flutter run --web-port=8999

docker-build:
	docker build --no-cache -t dynamic-2-do-list .

docker-run:
	echo "Running on port 8999"
	docker run --rm -d -p 8999:80 --name 2dolist dynamic-2-do-list

docker-stop:
	docker stop 2dolist

docker-remove:
	make docker-stop
	docker rm 2dolist

docker-deploy:
	make docker-build
	make docker-run
