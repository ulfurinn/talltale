.PHONY: image build push kube restart deploy logs sh iex psql default

image:
	docker build -t talltale .

snapshot:
	rm -f snapshot.db
	sqlite3 tall_tale_dev.db "VACUUM INTO 'snapshot.db'"

publish: snapshot
	(pod=$(shell kubectl get pod -l app=talltale -o jsonpath='{.items[0].metadata.name}'); kubectl cp snapshot.db $$pod:/var/lib/talltale/)

restart:
	kubectl rollout restart deployment talltale

logs:
	kubectl logs -f deployment/talltale

sh:
	kubectl exec -it deployments/talltale -- sh

iex:
	kubectl exec -it deployments/talltale -- sh -c "/app/bin/tall_tale remote"
