# Makefile for reMarkable Update Server

# Default values
HOST_IP ?= 10.11.99.2
CONTAINER_NAME = remarkable-update-server
IMAGE_NAME = remarkable-update

# Help target
.PHONY: help
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Setup and build
.PHONY: setup
setup: ## Create necessary directories and setup environment
	@echo "Setting up reMarkable update server..."
	@mkdir -p updates logs
	@chmod 755 updates logs
	@echo "Created updates/ and logs/ directories"
	@echo "Place your firmware files (.signed files) in the updates/ directory"

.PHONY: build
build: ## Build the Docker image
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME) .

.PHONY: build-no-cache
build-no-cache: ## Build the Docker image without cache
	@echo "Building Docker image without cache..."
	docker build --no-cache -t $(IMAGE_NAME) .

# Running services
.PHONY: up
up: setup ## Start the reMarkable update server
	@echo "Starting reMarkable update server with HOST_IP=$(HOST_IP)..."
	HOST_IP=$(HOST_IP) docker-compose up -d

.PHONY: down
down: ## Stop the reMarkable update server
	@echo "Stopping reMarkable update server..."
	docker-compose down

.PHONY: restart
restart: down up ## Restart the reMarkable update server

.PHONY: run
run: ## Run the server in foreground (for debugging)
	@echo "Running reMarkable update server in foreground with HOST_IP=$(HOST_IP)..."
	HOST_IP=$(HOST_IP) docker-compose up

# Monitoring and debugging
.PHONY: logs
logs: ## Show container logs
	docker-compose logs -f remarkable-update

.PHONY: status
status: ## Show container status
	docker-compose ps

.PHONY: shell
shell: ## Open a shell in the running container
	docker exec -it $(CONTAINER_NAME) /bin/bash

# Maintenance
.PHONY: clean
clean: ## Clean up containers and images
	@echo "Cleaning up..."
	docker-compose down -v --remove-orphans
	docker rmi $(IMAGE_NAME) 2>/dev/null || true
	docker system prune -f

.PHONY: clean-all
clean-all: clean ## Clean up everything including volumes
	@echo "Removing all data..."
	docker volume prune -f
	rm -rf logs/

# Firmware management
.PHONY: list-updates
list-updates: ## List available firmware files in updates directory
	@echo "Available firmware files:"
	@ls -la updates/ || echo "No files found in updates/ directory"

.PHONY: check-connection
check-connection: ## Test connection to the server
	@echo "Testing connection to server..."
	@curl -f http://localhost:8000 && echo "✓ Server is responding" || echo "✗ Server is not responding"

# reMarkable device helpers
.PHONY: show-device-config
show-device-config: ## Show the configuration that should be added to reMarkable device
	@echo ""
	@echo "=== reMarkable Device Configuration ==="
	@echo "SSH into your reMarkable device and edit: /usr/share/remarkable/update.conf"
	@echo ""
	@echo "Add this line:"
	@echo "SERVER=http://$(HOST_IP):8000"
	@echo ""
	@echo "Then run on the device:"
	@echo "systemctl start update-engine"
	@echo "update_engine_client -check_for_update"
	@echo ""

.PHONY: device-commands
device-commands: ## Show useful reMarkable device commands
	@echo ""
	@echo "=== Useful reMarkable Device Commands ==="
	@echo "SSH connection: ssh root@10.11.99.1"
	@echo "Edit config: nano /usr/share/remarkable/update.conf"
	@echo "Start update engine: systemctl start update-engine"
	@echo "Check for updates: update_engine_client -check_for_update"
	@echo "Monitor update progress: journalctl -u update-engine -f"
	@echo "Reboot device: reboot"
	@echo ""

# Quick start
.PHONY: quickstart
quickstart: setup build up show-device-config ## Complete setup and start (recommended for first time)
	@echo ""
	@echo "✓ reMarkable update server is now running!"
	@echo "✓ Place your firmware files in the updates/ directory"
	@echo "✓ Configure your reMarkable device as shown above"

# Set different host IP
.PHONY: set-usb-ip
set-usb-ip: ## Set HOST_IP for USB connection (10.11.99.2)
	$(MAKE) HOST_IP=10.11.99.2 up

.PHONY: set-wifi-ip
set-wifi-ip: ## Set HOST_IP for WiFi connection (you need to specify IP=your.ip.address)
ifndef IP
	@echo "Usage: make set-wifi-ip IP=192.168.1.25"
	@exit 1
endif
	$(MAKE) HOST_IP=$(IP) up
