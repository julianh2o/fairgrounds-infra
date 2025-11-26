# fairgrounds-infra
Infrastructure for the fairgrounds

# TODO
* move docker compose files into here
* setup prometheus metrics
* setup secret management in a sane way
* look into creating a yml powered dashboard that tracks faigrounds services
* create script for refreshing seedbox: delete cookies file, output IP address, create new MAM session with IP address, retrieve mam_id, update docker_compose file, docker compose down/up seedboxapi