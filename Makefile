NAME = inception
DATA_DIR = /home/opopov42/data
WP_DIR = $(DATA_DIR)/wordpress
DB_DIR = $(DATA_DIR)/mariadb

all: build

build:
	@mkdir -p $(WP_DIR)
	@mkdir -p $(DB_DIR)
	docker compose -f srcs/docker-compose.yml up -d --build

up:
	docker compose -f srcs/docker-compose.yml up -d

down:
	docker compose -f srcs/docker-compose.yml down

clean: down
	docker system prune -af

fclean: clean
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@sudo rm -rf $(DATA_DIR)

re: fclean build

.PHONY: all build up down clean fclean re
