# Containerized Infrastructure & Dynamic ECS Jenkins Agents

An enterprise infrastructure automation project provisioning containerized Jenkins dynamic agent fleets running on EC2-backed AWS ECS clusters with Jenkins Configuration as Code (JCasC).

##  Architecture Overview


  +-------------------------------------------------------------+
  |  AWS Private VPC                                            |
  |                                                             |
  |  +-----------------------+      +------------------------+  |
  |  |  Jenkins Controller   | ---> | AWS ECS Cluster        |  |
  |  |  (JCasC Configured)   |      | (EC2 Fleet Instances)  |  |
  |  +-----------------------+      +-----------+------------+  |
  |                                             |               |
  |                                             v               |
  |                             +-------------------------------+
  |                             | Dynamic Agent Container       |
  |                             |  - Runtime: Java, Node, Perl  |
  |                             |  - Automated Solr Discovery   |
  |                             |  - S3 Dependency Syncing      |
  |                             +-------------------------------+
  +-------------------------------------------------------------+

🛠 Key Capabilities
Multi-Stage Container Runtime: Tiered Dockerfile builds (base-tools -> jenkins-agent-base -> final-jenkins-agent) baking in multi-language execution tools (Java 17, Node 22, Python 3, Perl 5.26, Ruby, Terraform, Packer).

Smart Layer Caching: ECR-backed incremental build system pulling base layers dynamically to optimize build times.

Dynamic ECS Task Discovery: Container entrypoint scripts query local AWS ECS metadata via CLI to route service dependencies (e.g. Solr) dynamically at runtime.

Declarative Configuration as Code: Complete Jenkins controller state managed via jenkins/casc.yaml defining security matrices, SSH agent key integrations, and EC2 Fleet plugin declarations.

🚀 Local Build Quickstart

# Display help and build target workflows
make help

# Smart rebuild of final application layer using pulled ECR base caches
make smart-rebuild-final

# Complete build and push of all layers
make push-all-layers