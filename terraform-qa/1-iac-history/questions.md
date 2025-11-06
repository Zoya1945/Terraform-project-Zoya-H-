# Infrastructure as Code (IaC) History - Q&A

## Basic Questions

### Q1: What is Infrastructure as Code (IaC)?
**Answer:** Infrastructure as Code (IaC) is the practice of managing and provisioning computing infrastructure through machine-readable definition files, rather than physical hardware configuration or interactive configuration tools.

### Q2: What are the benefits of IaC?
**Answer:**
- **Version Control**: Infrastructure changes can be tracked and versioned
- **Consistency**: Eliminates configuration drift
- **Repeatability**: Same infrastructure can be deployed multiple times
- **Automation**: Reduces manual errors
- **Documentation**: Code serves as documentation
- **Cost Management**: Better resource tracking and optimization

### Q3: What are the different types of IaC tools?
**Answer:**
- **Declarative**: Terraform, CloudFormation, ARM Templates
- **Imperative**: Ansible, Chef, Puppet
- **Hybrid**: Pulumi

## Intermediate Questions

### Q4: How does Terraform differ from other IaC tools like Ansible or Chef?
**Answer:**
- **Terraform**: Declarative, immutable infrastructure, state management
- **Ansible**: Imperative/declarative, configuration management, agentless
- **Chef**: Imperative, configuration management, agent-based
- **Puppet**: Declarative, configuration management, agent-based

### Q5: What is the difference between mutable and immutable infrastructure?
**Answer:**
- **Mutable**: Infrastructure is updated in-place (traditional approach)
- **Immutable**: Infrastructure is replaced entirely when changes are needed (Terraform approach)

### Q6: Explain the evolution of infrastructure management.
**Answer:**
1. **Physical Servers** (1990s-2000s): Manual hardware setup
2. **Virtualization** (2000s-2010s): VMs, hypervisors
3. **Cloud Computing** (2010s): AWS, Azure, GCP
4. **Infrastructure as Code** (2010s-present): Automated provisioning
5. **GitOps** (present): Git-based infrastructure management

## Advanced Questions

### Q7: What are the challenges in implementing IaC in large organizations?
**Answer:**
- **Cultural Resistance**: Teams used to manual processes
- **Skill Gap**: Learning curve for new tools
- **Legacy Systems**: Integration with existing infrastructure
- **Security Concerns**: Code-based security policies
- **Governance**: Standardization across teams
- **State Management**: Handling large, complex state files

### Q8: How do you handle infrastructure drift in IaC?
**Answer:**
- **Regular State Refresh**: `terraform refresh`
- **Drift Detection**: `terraform plan` to identify changes
- **Automated Remediation**: CI/CD pipelines to fix drift
- **Monitoring**: Tools like Terraform Cloud drift detection
- **Policy Enforcement**: OPA, Sentinel for compliance

### Q9: What is the role of GitOps in modern IaC?
**Answer:**
GitOps extends IaC by using Git as the single source of truth for infrastructure:
- **Git-based Workflows**: Pull requests for infrastructure changes
- **Automated Deployment**: CI/CD triggers on Git commits
- **Rollback Capability**: Git history for infrastructure rollbacks
- **Audit Trail**: Complete change history in Git
- **Collaboration**: Code review process for infrastructure