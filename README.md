# Terraform — Commands, Workflow & Best Practices

## 1. What is Terraform?

Terraform is an **Infrastructure as Code (IaC)** tool. You define infrastructure declaratively in `.tf` files, and Terraform compares that desired configuration with its state and the real infrastructure to determine what needs to change.

Common use cases include:

- Creating cloud resources such as virtual machines, networks, storage, and managed databases.
- Managing Kubernetes resources and other services through supported providers.
- Reusing infrastructure definitions through modules.
- Reviewing infrastructure changes before making them.
- Reproducing environments consistently across development, staging, and production.

Terraform does not create infrastructure by itself. It uses **providers** (for example, AWS, Azure, Google Cloud, Kubernetes, or local providers) to communicate with APIs.

---

## 2. Prerequisites

### Check the installation

```powershell
terraform -version
```

Prints the installed Terraform CLI version. 

## 3. Typical Project Structure

A small project may start with:

```text
terraform/
├── README.md
├── .gitignore
├── versions.tf          # Terraform and provider version constraints
├── providers.tf         # Provider configuration
├── main.tf              # Main resource definitions
├── variables.tf         # Input variable declarations
├── terraform.tfvars     # Local variable values; usually do not commit secrets
├── outputs.tf           # Values to display after apply
└── modules/             # Optional reusable modules
```

These filenames are conventions, not requirements. Terraform loads configuration from all relevant `.tf` files in the same directory as one module; it does not execute `main.tf` before `variables.tf`.

Do not place unrelated environments in the same directory unless you deliberately design for that. Separate directories or a deliberate workspace/backend strategy can help isolate environments.

---

## 4. The Standard Terraform Workflow

The usual lifecycle is:

```text
Write / update .tf files
        ↓
terraform fmt
        ↓
terraform init
        ↓
terraform validate
        ↓
terraform plan
        ↓
Review the proposed changes
        ↓
terraform apply
        ↓
Inspect outputs and actual resources
        ↓
Update configuration → plan → apply
        ↓
terraform destroy (only when intended)
```

### First-time setup

Run these commands from the directory containing your Terraform configuration:

```powershell
terraform fmt -recursive
terraform init
terraform validate
terraform plan
terraform apply
```

**Important:** `terraform plan` and `terraform apply` require a usable configuration. For real infrastructure, configure a provider, credentials, variables, and required resources first. For a learning exercise, you can begin with a simple local/provider example.

---

## 5. Core Commands

### 5.1 `terraform init` — initialize the working directory

```powershell
terraform init
```

**What it does**
- Initializes the Terraform working directory.
- Downloads the providers required by the configuration.
- Initializes the configured backend for state storage.
- Prepares a directory for Terraform to run.

**Use it when**
- Starting a project for the first time.
- Adding or changing a provider or module.
- Changing backend configuration.
- Switching to a fresh clone of a repository.

Useful options:

```powershell
terraform init -upgrade
terraform init -reconfigure
terraform init -backend=false
```

- `-upgrade`: allows provider and module dependencies to be upgraded within the constraints in the configuration and lock file rules.
- `-reconfigure`: discards the local backend configuration association and configures the backend again; use when intentionally changing backend settings.
- `-backend=false`: skips backend initialization, useful only for workflows that intentionally do not initialize a backend.

**Notes**
- Commit `.terraform.lock.hcl` so teammates and CI can use consistent provider selections.
- The `.terraform/` directory is generated locally and should generally not be committed.
- Do not casually change or migrate a production backend. Read the prompts and back up state according to your team's procedure.

### 5.2 `terraform fmt` — format configuration

```powershell
terraform fmt
terraform fmt -recursive
terraform fmt -check -recursive
```

**What it does:** Formats `.tf` files using Terraform's standard style.

**Use it when:** Before reviewing changes, committing code, or running CI checks.

- `-recursive`: also formats Terraform files in subdirectories.
- `-check`: reports whether files need formatting without changing them; useful in CI.

### 5.3 `terraform validate` — validate configuration

```powershell
terraform validate
```

**What it does:** Checks configuration syntax and internal consistency.

**Use it when:** After editing `.tf` files and before planning.

**Important:** Run `terraform init` first. Validation does not prove that cloud credentials work, that permissions are sufficient, or that a real deployment will succeed.

### 5.4 `terraform plan` — preview changes

```powershell
terraform plan
terraform plan -out=tfplan
terraform plan -var="region=ap-south-1"
terraform plan -var-file="dev.tfvars"
terraform plan -destroy
```

**What it does:** Compares the configuration, Terraform state, and refreshed information from providers to propose changes without applying them.

**Use it when:** Reviewing what Terraform intends to create, update, replace, or destroy.

- `-out=tfplan`: saves the plan for later application.
- `-var`: supplies an input variable on the command line.
- `-var-file`: loads variable values from a file.
- `-destroy`: previews a destroy operation instead of normal desired-state changes.

**Review the plan carefully.** A replacement may destroy and recreate a resource. The plan can also expose sensitive values in output or saved plan files, so protect those files.

### 5.5 `terraform apply` — apply changes

```powershell
terraform apply
terraform apply tfplan
terraform apply -var-file="dev.tfvars"
terraform apply -auto-approve
```

**What it does:** Executes the proposed operations to bring managed infrastructure toward the configuration.

**Recommended interactive workflow:**

```powershell
terraform plan -out=tfplan
terraform apply tfplan
```

Review the saved plan before applying it. Terraform will use the saved plan as the proposed actions rather than creating a new interactive plan.

- `-var-file`: supplies variable values.
- `-auto-approve`: skips the interactive approval prompt. Use only in controlled automation or when you have an explicit review/approval process.

**Use it when:** You have reviewed the changes and are ready to create or update resources.

### 5.6 `terraform output` — display outputs

```powershell
terraform output
terraform output instance_ip
terraform output -json
terraform output -raw instance_ip
```

**What it does:** Displays root-module outputs stored in state.

**Use it when:** Retrieving a public IP, hostname, resource identifier, or another value explicitly declared as an output.

- `-json`: outputs values in JSON format.
- `-raw`: prints a string, number, or boolean without JSON formatting where supported.

Only values declared with `output` blocks are available. Marking an output `sensitive = true` redacts it in ordinary CLI display, but the value can still be present in state.

### 5.7 `terraform show` — inspect state or a saved plan

```powershell
terraform show
terraform show -no-color
terraform show tfplan
```

**What it does:** Displays a human-readable representation of the current state or a saved plan.

**Use it when:** Inspecting managed resource attributes or reviewing a saved plan.

State and plans can contain secrets. Do not paste their contents into public issues or commit them to Git.

### 5.8 `terraform destroy` — remove managed infrastructure

```powershell
terraform plan -destroy
terraform destroy
terraform destroy -var-file="dev.tfvars"
terraform destroy -auto-approve
```

**What it does:** Plans and executes deletion of resources managed by the current Terraform configuration/state.

**Use it when:** Tearing down a disposable lab or an environment you intentionally want to remove.

**Before destroying**
1. Confirm the account, subscription, project, workspace, and backend.
2. Review `terraform plan -destroy` or the destroy plan shown by `terraform destroy`.
3. Check for data retention, backups, dependencies, and resources that must remain.
4. Make sure you have authority to delete the resources.

Avoid `-auto-approve` for manual work. Destroying Terraform-managed resources does not necessarily delete every resource created outside Terraform, and deletion may be irreversible.

### 5.9 `terraform refresh` — refresh state (legacy command)

The standalone `terraform refresh` command is deprecated in modern Terraform workflows. Prefer:

```powershell
terraform plan -refresh-only
terraform apply -refresh-only
```

A refresh-only plan previews updates to Terraform state based on the real infrastructure without proposing normal configuration changes. Apply it only after reviewing the results.

### 5.10 `terraform get` — download modules

```powershell
terraform get
terraform get -update
```

Downloads modules referenced by the configuration. `terraform init` normally handles module installation, so `terraform get` is less commonly needed in a standard workflow.

### 5.11 `terraform providers` — inspect provider requirements

```powershell
terraform providers
```

Shows provider requirements in the configuration and state. Useful for diagnosing provider-related dependency issues.

### 5.12 `terraform graph` — view dependency graph

```powershell
terraform graph
```

Prints a dependency graph in DOT format. It can be piped to a graph-rendering utility if you have one installed. Useful for understanding dependencies between resources.

### 5.13 `terraform console` — evaluate expressions

```powershell
terraform console
```

Opens an interactive console for evaluating Terraform expressions, such as `length(var.names)` or `local.some_value`. Exit with `exit` or `Ctrl+Z`, then Enter, in PowerShell.

### 5.14 `terraform force-unlock` — unlock state carefully

```powershell
terraform force-unlock LOCK_ID
```

Removes a state lock for the current configuration when Terraform cannot unlock it automatically.

**Danger:** Use only when you have verified that the lock belongs to an operation that is no longer running. Never force-unlock a state another person or CI job is actively using. Get the exact lock ID from the error message.

### 5.15 `terraform login` and `terraform logout`

```powershell
terraform login
terraform logout
```

Manage Terraform Cloud/Enterprise credentials for workflows that use those services. These are not general commands for logging in to AWS, Azure, or Google Cloud; use the cloud provider's supported authentication method.

---

## 6. Variables, Outputs, and Configuration

### Declare variables — `variables.tf`

```hcl
variable "region" {
  description = "Region in which resources should be created"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
```

### Supply values

```powershell
terraform plan -var="environment=dev"
terraform plan -var-file="dev.tfvars"
```

Example `dev.tfvars`:

```hcl
region      = "ap-south-1"
environment = "dev"
```

Terraform can also load `terraform.tfvars` and `*.auto.tfvars` automatically. Explicit `-var` and `-var-file` values are useful for choosing a specific environment. Avoid putting credentials or other secrets in committed `.tfvars` files.

### Define outputs — `outputs.tf`

```hcl
output "environment" {
  description = "Environment selected for this deployment"
  value       = var.environment
}
```

Then run:

```powershell
terraform apply
terraform output
terraform output environment
```

Outputs make selected values available after operations. Do not output secrets unless necessary.

### Use locals

```hcl
locals {
  resource_name = "example-${var.environment}"
}
```

Locals let you define reusable expressions inside a module. They are not set from the CLI like input variables.

---

## 7. State Management

Terraform state records the relationship between configuration and resources Terraform manages. By default, local state is stored in `terraform.tfstate`; a backup may also be created.

### Inspect state

```powershell
terraform state list
terraform state show ADDRESS
terraform state pull
```

- `state list`: lists resource addresses recorded in state.
- `state show ADDRESS`: shows attributes for one state resource, for example `terraform state show aws_instance.example`.
- `state pull`: reads the current state from the configured backend and prints it.

**Treat all state output as sensitive.** It may contain passwords, tokens, private addresses, and other sensitive attributes.

### Move or remove a state entry

```powershell
terraform state mv SOURCE DESTINATION
terraform state rm ADDRESS
```

- `state mv`: changes a resource address in state, commonly when refactoring resource names or module paths.
- `state rm`: removes the binding from state without deleting the real infrastructure resource.

These are advanced operations. Back up state first, coordinate with other users, and understand the consequences. Removing a state entry does **not** destroy the real resource; Terraform may attempt to create another resource on a future apply if the configuration still declares it.

### Import an existing resource

```powershell
terraform import ADDRESS RESOURCE_ID
```

Associates an existing supported resource with a Terraform address in state. You generally need a matching resource block in configuration and should run `terraform plan` afterward. Import does not automatically generate a complete configuration for every resource.

### Back up local state

If using local state, stop active Terraform operations and make a secure backup before advanced state operations. Do not commit state or state backups to Git. With remote state, follow the backend's backup and recovery procedures.

### Remote state and locking

For team or production usage, consider a supported remote backend that provides access controls, encryption, recovery/versioning, and state locking where supported. Configure the backend deliberately and follow the provider/backend documentation. Do not casually copy state files between local and remote environments.

---

## 8. Providers, Modules, and Workspaces

### Providers

Providers are plugins that allow Terraform to manage a particular platform or API. Declare required providers and constraints in configuration, then run:

```powershell
terraform init
terraform providers
```

Pin sensible version constraints and commit `.terraform.lock.hcl`. Upgrade intentionally, review the resulting changes, and test them.

### Modules

A module is a reusable collection of Terraform configuration. A root module can call child modules.

```powershell
terraform init
terraform validate
terraform plan
```

Run these after adding or changing a module. Prefer clear module inputs and outputs, and avoid making modules so generic that they become hard to understand.

### Workspaces

```powershell
terraform workspace list
terraform workspace show
terraform workspace new dev
terraform workspace select dev
terraform workspace show
terraform workspace delete dev
```

Workspaces provide separate state instances for the same configuration in a given backend. They can be useful for lightweight isolated instances, but **they are not a complete security or environment-isolation boundary**. Use separate configurations and/or backends when environments require strong separation, different access controls, or distinct lifecycle management.

Do not delete a workspace that still contains managed resources unless you have a deliberate migration or cleanup plan. The default workspace cannot be deleted.

---

## 9. Formatting, Validation, and Troubleshooting

### Check configuration and execution

```powershell
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

This is a useful local pre-commit sequence.

### Enable detailed logs

In PowerShell:

```powershell
$env:TF_LOG = "INFO"
terraform plan
Remove-Item Env:TF_LOG
```

Use `DEBUG` instead of `INFO` only when more detail is needed. Logs may contain sensitive data; review them before sharing. Remove the environment variable when done.

To save logs to a file:

```powershell
$env:TF_LOG = "DEBUG"
$env:TF_LOG_PATH = ".\terraform-debug.log"
terraform plan
Remove-Item Env:TF_LOG
Remove-Item Env:TF_LOG_PATH
```

Keep the generated log out of Git and delete it after troubleshooting.

### Common problems

| Problem | What to check |
|---|---|
| `terraform` is not recognized | Verify installation and `PATH`; open a new PowerShell session. |
| Provider initialization fails | Check internet access, provider source/version constraints, and `.terraform.lock.hcl`; rerun `terraform init` after a deliberate configuration change. |
| Authentication/permission error | Verify the correct cloud account, credentials, role, and required permissions. |
| Variable has no value | Check variable declarations, defaults, `terraform.tfvars`, `-var-file`, and environment variables. |
| Resource already exists | Determine whether it should be imported, managed elsewhere, or renamed; do not blindly create duplicates. |
| State lock error | Confirm no active Terraform operation owns the lock before considering recovery. |
| Unexpected resource replacement | Read the plan details and resource/provider documentation before approving. |
| State and real infrastructure differ | Review a normal plan or a `-refresh-only` plan; do not manually edit state files. |
| Provider version changed unexpectedly | Review provider constraints and `.terraform.lock.hcl`; upgrade deliberately. |

### About `terraform init -upgrade`

Use it intentionally when you want Terraform to consider newer allowed provider/module versions. It is not a routine fix for every error. Review the lock-file diff and run `terraform plan` after upgrading.

---

## 10. Useful Command Options

| Option | Purpose | Important note |
|---|---|---|
| `-var="key=value"` | Supply one input variable | Avoid putting secrets in shell history. |
| `-var-file="file.tfvars"` | Load variable values | Keep secret-bearing files out of Git. |
| `-out=tfplan` | Save a plan | Protect it like sensitive data. |
| `-auto-approve` | Skip apply/destroy confirmation | Use only with a deliberate review/approval process. |
| `-target=ADDRESS` | Focus an operation on a specific resource/address | Exceptional troubleshooting tool, not a normal deployment strategy; can leave changes incomplete. |
| `-replace=ADDRESS` | Request replacement of a resource | Review the plan; replacement can cause downtime or data loss. |
| `-refresh-only` | Reconcile state with observed infrastructure | Review before applying state updates. |
| `-lock=false` | Disable state locking for supported backends | Avoid in normal/team workflows; concurrent operations can corrupt state. |
| `-parallelism=N` | Limit concurrent operations | Use when an API or environment requires lower concurrency. |
| `-chdir=PATH` | Run Terraform as if from another directory | Useful for scripts or multi-directory repositories. |
| `-no-color` | Disable ANSI color output | Useful for logs and CI. |

Example:

```powershell
terraform plan -var-file="dev.tfvars" -out=tfplan
terraform apply tfplan
```

Use `-target` only for exceptional recovery or narrowly scoped tasks when you understand the dependencies. For normal changes, update the configuration and use a full plan.

---

## 11. Security and Git Best Practices

### Suggested `.gitignore`

```gitignore
# Terraform working directory
.terraform/

# State files and backups
*.tfstate
*.tfstate.*
crash.log
crash.*.log

# Variable files may contain environment-specific values or secrets
*.tfvars
*.tfvars.json

# Saved plans and local debug logs
*.tfplan
tfplan
terraform-debug.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Local CLI configuration
.terraformrc
terraform.rc
```

**Review this list for your repository.** If you want to commit a non-sensitive example variable file, name it something explicit such as `dev.example.tfvars` and adjust the ignore rules for that file. Never commit real credentials.

### Rules to follow

1. Commit `.tf` configuration and `.terraform.lock.hcl`.
2. Do not commit `terraform.tfstate`, state backups, secret-bearing variable files, saved plans, credentials, or debug logs.
3. Use least-privilege credentials and short-lived authentication where supported.
4. Review plans before applying changes, especially for production.
5. Use remote state with suitable access control, encryption, recovery, and locking for collaborative environments.
6. Pin provider versions and review upgrades.
7. Keep separate environments isolated according to their risk and access requirements.
8. Do not assume `sensitive = true` encrypts or removes a value from state.
9. Before destroying infrastructure, verify the account, region, workspace, backend, and exact resources.
10. Treat Terraform state and saved plan files as potentially sensitive artifacts.

---

## 12. Quick Reference

| Goal | Command |
|---|---|
| Show version | `terraform -version` |
| Show help | `terraform -help` |
| Format files | `terraform fmt -recursive` |
| Check formatting | `terraform fmt -check -recursive` |
| Initialize project | `terraform init` |
| Validate configuration | `terraform validate` |
| Preview changes | `terraform plan` |
| Save a plan | `terraform plan -out=tfplan` |
| Apply saved plan | `terraform apply tfplan` |
| Apply interactively | `terraform apply` |
| Show outputs | `terraform output` |
| Inspect state resources | `terraform state list` |
| Inspect one resource in state | `terraform state show ADDRESS` |
| Preview state refresh | `terraform plan -refresh-only` |
| Preview deletion | `terraform plan -destroy` |
| Destroy managed resources | `terraform destroy` |
| List workspaces | `terraform workspace list` |
| Show provider requirements | `terraform providers` |
| Evaluate expressions | `terraform console` |
| Get command help | `terraform -help COMMAND` |

Replace placeholders such as `ADDRESS`, `RESOURCE_ID`, `dev.tfvars`, and `tfplan` with the values appropriate for your project.

---

## 13. Recommended Learning Sequence

For a practical learning project, work through these topics in order:

1. **CLI basics:** `version`, `help`, `fmt`, `init`, `validate`.
2. **Lifecycle:** `plan`, review changes, `apply`, update configuration, and `destroy` in a disposable lab.
3. **Configuration:** resources, providers, variables, locals, and outputs.
4. **State:** `state list`, `state show`, state safety, and why remote state matters.
5. **Reuse:** modules, provider version constraints, and `.terraform.lock.hcl`.
6. **Environment separation:** workspaces versus separate configurations/backends.
7. **Collaboration and automation:** remote backend, CI checks, plan review, and controlled apply permissions.
8. **Cloud-specific infrastructure:** learn the chosen provider's identity, networking, permissions, and resource lifecycle before provisioning real resources.

### The essential workflow to remember

```powershell
terraform fmt -recursive
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

After changing configuration, run the validation and planning steps again. When the lab is finished and you have confirmed that its resources should be deleted:

```powershell
terraform plan -destroy
terraform destroy
```

**Always review before applying or destroying.** Terraform is a powerful infrastructure tool; the correct workflow includes knowing which account and environment you are changing, not just knowing the commands.
