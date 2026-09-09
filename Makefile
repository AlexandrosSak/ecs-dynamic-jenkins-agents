.PHONY: help build-base build-jenkins build-final build-all push push-all-layers clean test ecr-login prepare-aws-ec2 list verify-ecr get-git-ip clone-master-public verify-git pull-base pull-jenkins pull-all-layers push-base push-jenkins push-final-only smart-rebuild-final smart-rebuild-jenkins final jenkins base all

# === CONFIGURATION ===
AWS_REGION ?= eu-west-1
AWS_ACCOUNT_ID ?= 111111111111
REPO_NAME ?= jenkins-agents
TAG ?= v1.0
ECR_REGISTRY ?= ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Git server configuration
GIT_SERVER_REGION ?= us-west-2
GIT_INSTANCE_TAG ?= "Name=tag:Name,Values=git"
MASTER_PUBLIC_DIR ?= master_public

# Layer names for ECR
BASE_IMAGE_NAME = base-tools
BASE_ECR_TAG = base-layer
JENKINS_IMAGE_NAME = jenkins-agent-base
JENKINS_ECR_TAG = jenkins-layer
FINAL_IMAGE_NAME = ${REPO_NAME}

# Timestamp for versioning
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
RED := \033[0;31m
NC := \033[0m

help:
	@echo -e "${BLUE}=== Jenkins Agent Build System (With ECR Layer Caching) ===${NC}"
	@echo ""
	@echo -e "${YELLOW}Configuration:${NC}"
	@echo "  AWS Region: ${AWS_REGION}"
	@echo "  ECR Registry: ${ECR_REGISTRY}"
	@echo "  ECR Images: ${BASE_IMAGE_NAME}, ${JENKINS_IMAGE_NAME},${FINAL_IMAGE_NAME}"
	@echo "  Tag: ${TAG}"
	@echo ""
	@echo -e "${GREEN}Build Commands:${NC}"
	@echo "  make build-base          - Build base-tools layer"
	@echo "  make build-jenkins       - Build jenkins-agent-base layer"
	@echo "  make build-final         - Build final composite image"
	@echo "  make build-all           - Build all layers"
	@echo ""
	@echo -e "${GREEN}Push Commands (All layers to ECR):${NC}"
	@echo "  make push-base           - Build + push base-tools to ECR"
	@echo "  make push-jenkins        - Build + push jenkins-agent-base to ECR"
	@echo "  make push-final-only     - Push final image to ECR"
	@echo "  make push-all-layers     - Build + push ALL layers to ECR"
	@echo "  make push                - Alias for push-all-layers"
	@echo ""
	@echo -e "${GREEN}Pull Commands (from ECR cache):${NC}"
	@echo "  make pull-base           - Pull base-tools from ECR"
	@echo "  make pull-jenkins        - Pull jenkins-agent-base from ECR"
	@echo "  make pull-all-layers     - Pull all layers from ECR"
	@echo ""
	@echo -e "${YELLOW}Smart Rebuild Workflow:${NC}"
	@echo "  # Only app code changed:"
	@echo "  make pull-base pull-jenkins build-final push-final-only"
	@echo ""
	@echo "  # Jenkins setup changed:"
	@echo "  make pull-base build-jenkins build-final push-jenkins push-final-only"
	@echo ""
	@echo "  # System tools changed:"
	@echo "  make build-all push-all-layers"
	@echo ""

# === GIT SERVER DISCOVERY ===
get-git-ip:
	@echo -e "${BLUE}Discovering git server IP in${GIT_SERVER_REGION}...${NC}" 	@GIT_IP=$$(aws ec2 describe-instances \
		--region ${GIT_SERVER_REGION} \
		--filters ${GIT_INSTANCE_TAG} "Name=instance-state-name,Values=running" \
		--query "Reservations[0].Instances[0].PrivateIpAddress" \
		--output text 2>/dev/null); \
	if [ -n "$$GIT_IP" ] && [ "$$GIT_IP" != "None" ]; then \
		echo -e "${GREEN} Found git server:$$GIT_IP${NC}"; \ 		echo "$$GIT_IP" > .git-ip; \
	else \
		echo -e "${RED} Could not discover git server IP${NC}"; \
		exit 1; \
	fi

# === CLONE MASTER_PUBLIC ===
clone-master-public: get-git-ip
	@GIT_IP=$$(cat .git-ip); \
	echo -e "${BLUE}Cloning master_public from git://$$GIT_IP/master_public.git...${NC}"; \
	if [ -d "${MASTER_PUBLIC_DIR}" ]; then \
		echo -e "${YELLOW}master_public exists, updating...${NC}"; \
		cd ${MASTER_PUBLIC_DIR} && git fetch --all && git reset --hard origin/master; \
		cd ..; \
	else \
		echo -e "${YELLOW}Cloning repository...${NC}"; \ 		git clone --depth 1 git://$$GIT_IP/master_public.git ${MASTER_PUBLIC_DIR}; \
	fi; \
	echo -e "${GREEN} master_public repository ready${NC}"

# === AWS CONFIG FOR EC2 ===
prepare-aws-ec2:
	@echo -e "${BLUE}Creating AWS config for EC2 IAM Role...${NC}"
	@rm -rf .docker-aws 2>/dev/null || true
	@mkdir -p .docker-aws
	@echo "[default]" > .docker-aws/config
	@echo "region = ${AWS_REGION}" >> .docker-aws/config
	@echo "output = json" >> .docker-aws/config
	@touch .docker-aws/credentials
	@echo -e "${GREEN} AWS config for EC2 IAM Role created${NC}"

# === ECR LOGIN ===
ecr-login:
	@echo -e "${BLUE}Logging into ECR...${NC}"
	@aws ecr get-login-password --region ${AWS_REGION} | \
		docker login --username AWS --password-stdin ${ECR_REGISTRY}
	@echo -e "${GREEN} Logged into ECR${NC}"

# === BUILD COMMANDS ===
build-base: prepare-aws-ec2
	@echo -e "${BLUE}Building base-tools...${NC}"
	@docker build \
		--build-arg AWS_REGION="${AWS_REGION}" \
		-t ${BASE_IMAGE_NAME}:${TAG} \
		-t ${BASE_IMAGE_NAME}:latest \
		-t ${BASE_IMAGE_NAME}:${TIMESTAMP} \
		-f docker/base-tools.Dockerfile .
	@echo -e "${GREEN} Built ${BASE_IMAGE_NAME}:${TAG}, latest, ${TIMESTAMP}${NC}"

build-jenkins: pull-base
	@echo -e "${BLUE}Building jenkins-agent-base...${NC}"
	@BASE_IMAGE_ARG=""; \
	if docker image inspect ${BASE_IMAGE_NAME}:latest >/dev/null 2>&1; then \
		BASE_IMAGE_ARG="${BASE_IMAGE_NAME}:latest"; \
	else \
		BASE_IMAGE_ARG="${ECR_REGISTRY}/${REPO_NAME}:${BASE_ECR_TAG}"; \
	fi; \
	echo "Using base image: $$BASE_IMAGE_ARG"; \ 	docker build \ 		--build-arg BASE_IMAGE="$$BASE_IMAGE_ARG" \
		--build-arg AWS_REGION="${AWS_REGION}" \
		-t ${JENKINS_IMAGE_NAME}:${TAG} \
		-t ${JENKINS_IMAGE_NAME}:latest \
		-t ${JENKINS_IMAGE_NAME}:${TIMESTAMP} \
		-f docker/jenkins-agent-base.Dockerfile .
	@echo -e "${GREEN} Built ${JENKINS_IMAGE_NAME}:${TAG}, latest, ${TIMESTAMP}${NC}"

build-final: pull-jenkins get-git-ip
	@GIT_IP=$$(cat .git-ip); \ 	echo "Using Git IP: $$GIT_IP"; \
	JENKINS_IMAGE_ARG=""; \
	if docker image inspect ${JENKINS_IMAGE_NAME}:latest >/dev/null 2>&1; then \
		JENKINS_IMAGE_ARG="${JENKINS_IMAGE_NAME}:latest"; \
	else \
		JENKINS_IMAGE_ARG="${ECR_REGISTRY}/${REPO_NAME}:${JENKINS_ECR_TAG}"; \
	fi; \
	echo "Using base image: $$JENKINS_IMAGE_ARG"; \ 	docker build \ 		--build-arg JENKINS_IMAGE="$$JENKINS_IMAGE_ARG" \
		--build-arg AWS_REGION="${AWS_REGION}" \ 		--build-arg GIT_IP="$$GIT_IP" \
		-t ${FINAL_IMAGE_NAME}:${TAG} \
		-t ${FINAL_IMAGE_NAME}:latest \
		-t ${FINAL_IMAGE_NAME}:${TIMESTAMP} \
		-f docker/final-jenkins-agent.Dockerfile .
	@echo -e "${GREEN} Built ${FINAL_IMAGE_NAME}:${TAG}, latest, ${TIMESTAMP}${NC}"

build-all: build-final
	@echo -e "${GREEN} All layers built locally!${NC}"

# === PUSH ALL LAYERS TO ECR ===
push-base: build-base ecr-login
	@echo -e "${BLUE}Pushing base-tools to ECR (as${REPO_NAME}:${BASE_ECR_TAG})...${NC}"
	@docker tag ${BASE_IMAGE_NAME}:${TAG} ${ECR_REGISTRY}/${REPO_NAME}:${BASE_ECR_TAG}-${TAG}
	@docker tag ${BASE_IMAGE_NAME}:latest${ECR_REGISTRY}/${REPO_NAME}:${BASE_ECR_TAG}
	@docker push ${ECR_REGISTRY}/${REPO_NAME}:${BASE_ECR_TAG}-${TAG}
	@docker push ${ECR_REGISTRY}/${REPO_NAME}:${BASE_ECR_TAG}
	@echo -e "${GREEN} Pushed base-tools to ECR as${REPO_NAME}:${BASE_ECR_TAG}${NC}"

push-jenkins: build-jenkins ecr-login
	@echo -e "${BLUE}Pushing jenkins-agent-base to ECR (as${REPO_NAME}:${JENKINS_ECR_TAG})...${NC}"
	@docker tag ${JENKINS_IMAGE_NAME}:${TAG} ${ECR_REGISTRY}/${REPO_NAME}:${JENKINS_ECR_TAG}-${TAG}
	@docker tag ${JENKINS_IMAGE_NAME}:latest${ECR_REGISTRY}/${REPO_NAME}:${JENKINS_ECR_TAG}
	@docker push ${ECR_REGISTRY}/${REPO_NAME}:${JENKINS_ECR_TAG}-${TAG}
	@docker push ${ECR_REGISTRY}/${REPO_NAME}:${JENKINS_ECR_TAG}
	@echo -e "${GREEN} Pushed jenkins-agent-base to ECR as${REPO_NAME}:${JENKINS_ECR_TAG}${NC}"

push-final-only: ecr-login
	@echo -e "${BLUE}Pushing final image to ECR (as${REPO_NAME}:${TAG})...${NC}"
	@docker tag ${FINAL_IMAGE_NAME}:${TAG}${ECR_REGISTRY}/${REPO_NAME}:${TAG}
	@docker tag ${FINAL_IMAGE_NAME}:latest ${ECR_REGISTRY}/${REPO_NAME}:latest
	@docker push ${ECR_REGISTRY}/${REPO_NAME}:${TAG}
	@docker push ${ECR_REGISTRY}/${REPO_NAME}:latest
	@echo -e "${GREEN} Pushed final image to ECR as${REPO_NAME}:${TAG} and :latest${NC}"

push-all-layers: push-base push-jenkins push-final-only
	@echo -e "${GREEN} All layers pushed to ECR!${NC}"

# === PULL FROM ECR CACHE ===
pull-base: ecr-login
	@echo -e "${BLUE}Pulling base-tools from ECR cache...${NC}"
	@docker pull ${ECR_REGISTRY}/${REPO_NAME}:${BASE_ECR_TAG} 2>/dev/null && \
		docker tag ${ECR_REGISTRY}/${REPO_NAME}:${BASE_ECR_TAG}${BASE_IMAGE_NAME}:latest 2>/dev/null && \
		echo -e "${GREEN} base-tools pulled from ECR${NC}" || \
		echo -e "${YELLOW} base-tools not in ECR, will build if needed${NC}"

pull-jenkins: ecr-login
	@echo -e "${BLUE}Pulling jenkins-agent-base from ECR cache...${NC}"
	@docker pull ${ECR_REGISTRY}/${REPO_NAME}:${JENKINS_ECR_TAG} 2>/dev/null && \
		docker tag ${ECR_REGISTRY}/${REPO_NAME}:${JENKINS_ECR_TAG}${JENKINS_IMAGE_NAME}:latest 2>/dev/null && \
		echo -e "${GREEN} jenkins-agent-base pulled from ECR${NC}" || \
		echo -e "${YELLOW} jenkins-agent-base not in ECR, will build if needed${NC}"

pull-all-layers: pull-jenkins
	@echo -e "${GREEN} All layers pulled from ECR cache${NC}"

# === SMART REBUILD COMMANDS ===
smart-rebuild-final: pull-jenkins clone-master-public build-final push-final-only
	@echo -e "${GREEN} Smart rebuild of final layer complete${NC}"

smart-rebuild-jenkins: pull-base build-jenkins build-final push-jenkins push-final-only
	@echo -e "${GREEN} Smart rebuild of jenkins layer complete${NC}"

# === ALIASES ===
push: push-all-layers
final: build-final
jenkins: build-jenkins
base: build-base
all: build-all

# === CLEANUP ===
clean:
	@echo -e "${YELLOW}Cleaning local images and artifacts...${NC}"
	@-docker rmi ${BASE_IMAGE_NAME}:${TAG}${BASE_IMAGE_NAME}:latest ${BASE_IMAGE_NAME}:${TIMESTAMP} 2>/dev/null || true
	@-docker rmi ${JENKINS_IMAGE_NAME}:${TAG}${JENKINS_IMAGE_NAME}:latest ${JENKINS_IMAGE_NAME}:${TIMESTAMP} 2>/dev/null || true
	@-docker rmi ${FINAL_IMAGE_NAME}:${TAG}${FINAL_IMAGE_NAME}:latest ${FINAL_IMAGE_NAME}:${TIMESTAMP} 2>/dev/null || true
	@rm -rf .docker-aws ${MASTER_PUBLIC_DIR} .git-ip 2>/dev/null || true
	@echo -e "${GREEN} Clean complete${NC}"

list:
	@echo -e "${BLUE}=== Local Docker Images ===${NC}"
	@docker images | grep -E "(REPOSITORY|${BASE_IMAGE_NAME}|${JENKINS_IMAGE_NAME}\vert{}${FINAL_IMAGE_NAME})" || echo "No images found"