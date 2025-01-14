.PHONY: image build push kube restart deploy logs sh iex psql default

snapshot:
	rm -f database.db
	sqlite3 tall_tale_dev.db "VACUUM INTO 'database.db'"

image: snapshot
	docker build -t talltale -f Dockerfile .

build: image

push: image
	docker tag talltale:latest sage:32000/talltale:latest
	docker push sage:32000/talltale:latest

kube:
	kubectl apply -f talltale.yml

restart:
	kubectl rollout restart deployment talltale

deploy: push kube restart

logs:
	kubectl logs -f deployment/talltale

sh:
	kubectl exec -it deployments/talltale -- sh

iex:
	kubectl exec -it deployments/talltale -- sh -c "/app/bin/tall_tale remote"

default: build
