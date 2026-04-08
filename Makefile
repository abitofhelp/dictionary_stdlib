# =============================================================================
# Project Makefile
# =============================================================================
# Project: dictionary
# Purpose: REST dictionary microservice — Ada 2022, standard library only
#
# This Makefile provides:
#   - Build targets (build, clean, rebuild, run)
#   - Test infrastructure (test, test-unit, test-integration, test-e2e)
#   - Quality targets (check, format, stats)
#   - Development tools (deps, refresh, compress)
# =============================================================================

PROJECT_NAME := dictionary_stdlib

.PHONY: all build build-dev build-opt build-release build-tests check \
        clean clean-deep compress deps docs-formal \
		help prereqs rebuild refresh run stats test test-all test-framework \
		test-integration test-unit test-e2e \
		format format-all format-src format-tests \
		docker-build docker-run docker-stop docker-test docker-clean

# =============================================================================
# OS Detection
# =============================================================================

UNAME := $(shell uname -s)

# =============================================================================
# Colors for Output
# =============================================================================

GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
BLUE := \033[0;34m
ORANGE := \033[38;5;208m
CYAN := \033[0;36m
BOLD := \033[1m
NC := \033[0m

# =============================================================================
# Tool Paths
# =============================================================================

ALR := alr
GPRBUILD := gprbuild
GNATFORMAT := gnatformat
PYTHON3 := python3

# =============================================================================
# Tool Flags
# =============================================================================

# Build flags (compiler options only)
ALR_BUILD_FLAGS := -j0

# =============================================================================
# Directories
# =============================================================================

BUILD_DIR := obj
BIN_DIR := bin
TEST_DIR := test

# =============================================================================
# Default Target
# =============================================================================

all: build

# =============================================================================
# Help Target
# =============================================================================

help: ## Display this help message
	@echo "$(CYAN)$(BOLD)╔══════════════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)$(BOLD)║  Dictionary_Stdlib — Ada 2022 REST Microservice   ║$(NC)"
	@echo "$(CYAN)$(BOLD)╚══════════════════════════════════════════════════╝$(NC)"
	@echo " "
	@echo "$(YELLOW)Build Commands:$(NC)"
	@echo "  build              - Build project (development mode)"
	@echo "  build-dev          - Build with development flags"
	@echo "  build-opt          - Build with validation profile"
	@echo "  build-release      - Build in release mode"
	@echo "  build-tests        - Build all test executables"
	@echo "  run                - Build and run the dictionary service"
	@echo "  clean              - Clean build artifacts"
	@echo "  clean-deep         - Deep clean (includes Alire cache)"
	@echo "  compress           - Create compressed source archive (tgz)"
	@echo "  rebuild            - Clean and rebuild"
	@echo ""
	@echo "$(YELLOW)Testing Commands:$(NC)"
	@echo "  test               - Run comprehensive test suite (main runner)"
	@echo "  test-unit          - Run unit tests only"
	@echo "  test-integration   - Run integration tests only"
	@echo "  test-e2e           - Run E2E tests only"
	@echo "  test-all           - Run all test executables"
	@echo "  test-framework     - Run all test suites (unit + integration + e2e)"
	@echo ""
	@echo "$(YELLOW)Quality Commands:$(NC)"
	@echo "  check              - Run static analysis"
	@echo "  format-src         - Auto-format source code only"
	@echo "  format-tests       - Auto-format test code only"
	@echo "  format-all         - Auto-format all code"
	@echo "  format             - Alias for format-all"
	@echo "  stats              - Display project statistics"
	@echo ""
	@echo "$(YELLOW)Docker Commands:$(NC)"
	@echo "  docker-build       - Build the production Docker image"
	@echo "  docker-run         - Run the service in Docker (port 8080)"
	@echo "  docker-stop        - Stop the running container"
	@echo "  docker-test        - Build, run, and test all endpoints"
	@echo "  docker-clean       - Remove the Docker image"
	@echo ""
	@echo "$(YELLOW)Documentation Commands:$(NC)"
	@echo "  docs-formal        - Compile Typst formal docs (SRS, SDS, STG) to PDF"
	@echo ""
	@echo "$(YELLOW)Utility Commands:$(NC)"
	@echo "  deps               - Show dependency information"
	@echo "  prereqs            - Verify prerequisites are satisfied"
	@echo "  refresh            - Refresh Alire dependencies"

# =============================================================================
# Build Commands
# =============================================================================

prereqs:
	@echo "$(GREEN)✓ All prerequisites satisfied$(NC)"

build: build-dev

build-dev: prereqs
	@echo "$(GREEN)Building $(PROJECT_NAME) (development mode)...$(NC)"
	@$(ALR) build --development -- $(ALR_BUILD_FLAGS)
	@echo "$(GREEN)✓ Development build complete$(NC)"
	@echo "$(GREEN)  Output: $(BIN_DIR)/$(PROJECT_NAME)$(NC)"

build-opt: prereqs
	@echo "$(GREEN)Building $(PROJECT_NAME) (validation profile)...$(NC)"
	@$(ALR) build --validation -- $(ALR_BUILD_FLAGS)
	@echo "$(GREEN)✓ Validation build complete$(NC)"
	@echo "$(GREEN)  Output: $(BIN_DIR)/$(PROJECT_NAME)$(NC)"

build-release: prereqs
	@echo "$(GREEN)Building $(PROJECT_NAME) (release mode)...$(NC)"
	@$(ALR) build --release -- $(ALR_BUILD_FLAGS)
	@echo "$(GREEN)✓ Release build complete$(NC)"
	@echo "$(GREEN)  Output: $(BIN_DIR)/$(PROJECT_NAME)$(NC)"

build-tests: prereqs
	@echo "$(GREEN)Building test suites...$(NC)"
	@if [ -f "$(TEST_DIR)/unit/unit_tests.gpr" ]; then \
		$(ALR) exec -- $(GPRBUILD) -P $(TEST_DIR)/unit/unit_tests.gpr -p $(ALR_BUILD_FLAGS); \
		echo "$(GREEN)✓ Unit tests built$(NC)"; \
	else \
		echo "$(YELLOW)Unit test project not found$(NC)"; \
	fi
	@if [ -f "$(TEST_DIR)/integration/integration_tests.gpr" ]; then \
		$(ALR) exec -- $(GPRBUILD) -P $(TEST_DIR)/integration/integration_tests.gpr -p $(ALR_BUILD_FLAGS); \
		echo "$(GREEN)✓ Integration tests built$(NC)"; \
	else \
		echo "$(YELLOW)Integration test project not found$(NC)"; \
	fi
	@if [ -f "$(TEST_DIR)/e2e/e2e_tests.gpr" ]; then \
		$(ALR) exec -- $(GPRBUILD) -P $(TEST_DIR)/e2e/e2e_tests.gpr -p $(ALR_BUILD_FLAGS); \
		echo "$(GREEN)✓ E2E tests built$(NC)"; \
	else \
		echo "$(YELLOW)E2E test project not found$(NC)"; \
	fi

clean:
	@echo "$(YELLOW)Cleaning project build artifacts (keeps dependencies)...$(NC)"
	@$(ALR) exec -- gprclean -P $(PROJECT_NAME).gpr -q 2>/dev/null || true
	@$(ALR) exec -- gprclean -P $(TEST_DIR)/unit/unit_tests.gpr -q 2>/dev/null || true
	@$(ALR) exec -- gprclean -P $(TEST_DIR)/integration/integration_tests.gpr -q 2>/dev/null || true
	@rm -rf $(BUILD_DIR) $(BIN_DIR) $(TEST_DIR)/bin $(TEST_DIR)/obj
	@rm -f alire/alire.lock
	@find . -name "*.backup" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Project artifacts cleaned (dependencies preserved for fast rebuild)$(NC)"

clean-deep:
	@echo "$(YELLOW)Deep cleaning ALL artifacts including dependencies...$(NC)"
	@$(ALR) clean
	@rm -rf $(BUILD_DIR) $(BIN_DIR) $(TEST_DIR)/bin $(TEST_DIR)/obj
	@find . -name "*.backup" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Deep clean complete (next build will be slow)$(NC)"

compress:
	@echo "$(CYAN)Creating compressed source archive...$(NC)"
	git archive --format=tar.gz -o "$(PROJECT_NAME).tar.gz" HEAD
	@echo "$(GREEN)✓ Archive created: $(PROJECT_NAME).tar.gz$(NC)"

rebuild: clean build

run: build ## Build and run the dictionary service
	@echo "$(GREEN)Running $(PROJECT_NAME)...$(NC)"
	@./$(BIN_DIR)/$(PROJECT_NAME)

# =============================================================================
# Testing Commands
# =============================================================================

test: test-all

test-all: build build-tests
	@echo "$(GREEN)Running all test executables...$(NC)"
	@failed=0; \
	if [ -d "$(TEST_DIR)/bin" ]; then \
		for test in $(TEST_DIR)/bin/*_runner; do \
			if [ -x "$$test" ] && [ -f "$$test" ]; then \
				echo "$(CYAN)Running $$test...$(NC)"; \
				$$test || failed=1; \
				echo ""; \
			fi; \
		done; \
	else \
		echo "$(YELLOW)No test executables found in $(TEST_DIR)/bin$(NC)"; \
	fi; \
	if [ $$failed -eq 0 ]; then \
		echo ""; \
		echo "\033[1;92m########################################"; \
		echo "###                                  ###"; \
		echo "###   ALL TEST SUITES: SUCCESS      ###"; \
		echo "###   All tests passed!              ###"; \
		echo "###                                  ###"; \
		echo "########################################\033[0m"; \
		echo ""; \
	else \
		echo ""; \
		echo "\033[1;91m########################################"; \
		echo "###                                  ###"; \
		echo "###   ALL TEST SUITES: FAILURE      ###"; \
		echo "###   Some tests failed!             ###"; \
		echo "###                                  ###"; \
		echo "########################################\033[0m"; \
		echo ""; \
		exit 1; \
	fi

test-unit: build build-tests
	@echo "$(GREEN)Running unit tests...$(NC)"
	@if [ -f "$(TEST_DIR)/bin/unit_runner" ]; then \
		$(TEST_DIR)/bin/unit_runner; \
		if [ $$? -eq 0 ]; then \
			echo "$(GREEN)✓ Unit tests passed$(NC)"; \
		else \
			echo "$(RED)✗ Unit tests failed$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(YELLOW)Unit test runner not found at $(TEST_DIR)/bin/unit_runner$(NC)"; \
		exit 1; \
	fi

test-integration: build build-tests
	@echo "$(GREEN)Running integration tests...$(NC)"
	@if [ -f "$(TEST_DIR)/bin/integration_runner" ]; then \
		$(TEST_DIR)/bin/integration_runner; \
		if [ $$? -eq 0 ]; then \
			echo "$(GREEN)✓ Integration tests passed$(NC)"; \
		else \
			echo "$(RED)✗ Integration tests failed$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(YELLOW)Integration test runner not found at $(TEST_DIR)/bin/integration_runner$(NC)"; \
		exit 1; \
	fi

test-e2e: build
	@echo "$(GREEN)Running E2E tests...$(NC)"
	@if [ -f "$(TEST_DIR)/e2e/e2e_test.sh" ]; then \
		$(TEST_DIR)/e2e/e2e_test.sh; \
		if [ $$? -eq 0 ]; then \
			echo "$(GREEN)✓ E2E tests passed$(NC)"; \
		else \
			echo "$(RED)✗ E2E tests failed$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(YELLOW)E2E test script not found at $(TEST_DIR)/e2e/e2e_test.sh$(NC)"; \
		exit 1; \
	fi

test-framework: test-unit test-integration test-e2e ## Run all test suites
	@echo "$(GREEN)$(BOLD)✓ All test suites completed$(NC)"

# =============================================================================
# Quality & Code Formatting Commands
# =============================================================================

check:
	@echo "$(GREEN)Running code checks...$(NC)"
	@$(ALR) build --development -- $(ALR_BUILD_FLAGS)
	@echo "$(GREEN)✓ Code checks complete$(NC)"

format-src: ## Format source code
	@echo "$(GREEN)Formatting source code...$(NC)"
	@$(ALR) exec -- $(GNATFORMAT) src/
	@echo "$(GREEN)✓ Source code formatted$(NC)"

format-tests: ## Format test code
	@echo "$(GREEN)Formatting test code...$(NC)"
	@$(ALR) exec -- $(GNATFORMAT) $(TEST_DIR)/
	@echo "$(GREEN)✓ Test code formatted$(NC)"

format-all: format-src format-tests ## Format all code
	@echo "$(GREEN)✓ All code formatting complete$(NC)"

format: format-all ## Alias for format-all

# =============================================================================
# Development Commands
# =============================================================================

stats:
	@echo "$(CYAN)$(BOLD)Project Statistics for $(PROJECT_NAME)$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════$(NC)"
	@echo ""
	@echo "Ada Source Files:"
	@echo "  Specs (.ads):  $$(find src -name '*.ads' 2>/dev/null | wc -l | tr -d ' ')"
	@echo "  Bodies (.adb): $$(find src -name '*.adb' 2>/dev/null | wc -l | tr -d ' ')"
	@echo ""
	@echo "Lines of Code:"
	@find src -name "*.ads" -o -name "*.adb" 2>/dev/null | \
	  xargs wc -l 2>/dev/null | tail -1 | awk '{printf "  Total: %d lines\n", $$1}' || echo "  Total: 0 lines"
	@echo ""
	@echo "Build Artifacts:"
	@if [ -f "./$(BIN_DIR)/$(PROJECT_NAME)" ]; then \
		echo "  Binary: $$(ls -lh ./$(BIN_DIR)/$(PROJECT_NAME) 2>/dev/null | awk '{print $$5}')"; \
	else \
		echo "  No binary found (run 'make build')"; \
	fi

deps: ## Display project dependencies
	@echo "$(CYAN)Project dependencies from alire.toml:$(NC)"
	@grep -A 10 "\[\[depends-on\]\]" alire.toml || echo "$(YELLOW)No dependencies found$(NC)"
	@echo ""
	@echo "$(CYAN)Alire dependency tree:$(NC)"
	@$(ALR) show --solve || echo "$(YELLOW)Could not resolve dependencies$(NC)"

refresh: ## Refresh Alire dependencies
	@echo "$(CYAN)Refreshing Alire dependencies...$(NC)"
	@$(ALR) update
	@echo "$(GREEN)✓ Dependencies refreshed$(NC)"

# =============================================================================
# Documentation Commands
# =============================================================================

docs-formal: ## Compile Typst formal docs (SRS, SDS, STG) to PDF
	@$(PYTHON3) scripts/python/compile_formal_docs.py

# =============================================================================
# Docker Commands
# =============================================================================

DOCKER_IMAGE := $(PROJECT_NAME)
DOCKER_CONTAINER := $(PROJECT_NAME)
DOCKER_PORT := 8080

docker-build: ## Build the production Docker image
	@echo "$(CYAN)Building Docker production image...$(NC)"
	docker build -t $(DOCKER_IMAGE):latest .
	@echo "$(GREEN)✓ Docker image built: $(DOCKER_IMAGE):latest$(NC)"
	@docker images $(DOCKER_IMAGE):latest --format "  Size: {{.Size}}"

docker-run: ## Run the service in Docker (port 8080)
	@echo "$(GREEN)Starting $(DOCKER_CONTAINER) on port $(DOCKER_PORT)...$(NC)"
	@docker run -d --rm \
		--name $(DOCKER_CONTAINER) \
		-p $(DOCKER_PORT):8080 \
		--read-only \
		--security-opt no-new-privileges:true \
		$(DOCKER_IMAGE):latest
	@echo "$(GREEN)✓ Running at http://localhost:$(DOCKER_PORT)$(NC)"

docker-stop: ## Stop the running container
	@echo "$(YELLOW)Stopping $(DOCKER_CONTAINER)...$(NC)"
	@docker stop $(DOCKER_CONTAINER) 2>/dev/null || true
	@echo "$(GREEN)✓ Stopped$(NC)"

docker-test: docker-build ## Build, run, and test all endpoints
	@echo "$(CYAN)Running Docker integration tests...$(NC)"
	@docker run -d --rm --name $(DOCKER_CONTAINER)-test \
		-p 18080:8080 $(DOCKER_IMAGE):latest
	@sleep 2
	@failed=0; \
	echo ""; \
	echo "--- Health ---"; \
	curl -sf http://localhost:18080/health && echo "" || failed=1; \
	echo "--- Create ---"; \
	curl -sf -w " HTTP %{http_code}\n" -X POST http://localhost:18080/entries \
		-d '{"key":"alpha","value":"First letter"}' || failed=1; \
	curl -sf -w " HTTP %{http_code}\n" -X POST http://localhost:18080/entries \
		-d '{"key":"beta","value":"Second letter"}' || failed=1; \
	echo "--- List (sorted) ---"; \
	curl -sf http://localhost:18080/entries && echo "" || failed=1; \
	echo "--- Get one ---"; \
	curl -sf http://localhost:18080/entries/alpha && echo "" || failed=1; \
	echo "--- Update ---"; \
	curl -sf -w " HTTP %{http_code}\n" -X PUT http://localhost:18080/entries/alpha \
		-d '{"key":"alpha","value":"Updated first"}' || failed=1; \
	echo "--- Delete ---"; \
	curl -sf -w " HTTP %{http_code}\n" -X DELETE http://localhost:18080/entries/beta || failed=1; \
	echo "--- Duplicate (409) ---"; \
	curl -s -w " HTTP %{http_code}\n" -X POST http://localhost:18080/entries \
		-d '{"key":"alpha","value":"dup"}' || true; \
	echo "--- Not found (404) ---"; \
	curl -s -w " HTTP %{http_code}\n" http://localhost:18080/entries/missing || true; \
	echo ""; \
	docker stop $(DOCKER_CONTAINER)-test 2>/dev/null || true; \
	if [ $$failed -eq 0 ]; then \
		echo "$(GREEN)$(BOLD)✓ All Docker integration tests passed$(NC)"; \
	else \
		echo "$(RED)$(BOLD)✗ Some Docker integration tests failed$(NC)"; \
		exit 1; \
	fi

docker-clean: ## Remove the Docker image
	@echo "$(YELLOW)Removing Docker image...$(NC)"
	@docker stop $(DOCKER_CONTAINER) 2>/dev/null || true
	@docker rmi $(DOCKER_IMAGE):latest 2>/dev/null || true
	@echo "$(GREEN)✓ Docker image removed$(NC)"

.DEFAULT_GOAL := help
