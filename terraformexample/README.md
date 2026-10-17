# Terraform + AWS example (Docker Compose on EC2)

This example intentionally follows the repository's current deployment logic
closely. Terraform creates one Ubuntu EC2 instance; cloud-init installs Docker
Compose, clones this repository, builds the existing images, and runs the
existing `docker-compose.yaml`. It does not convert the services to ECS or move
PostgreSQL to RDS.

## Resources created

- A VPC, one public subnet, an internet gateway, and a default internet route.
- One EC2 instance with an encrypted 16 GiB root disk.
- Security group ingress on TCP 8080 and 3000, matching the Compose port
  mappings. Both ports are open to the internet in this example.
- An EC2 role for AWS Systems Manager Session Manager. No SSH port or key pair
  is needed.
- On the instance: Docker, the Compose plugin, the cloned repository, and all
  four Compose containers (web, proxy, notes API, and PostgreSQL).

The proxy is reached on port 8080, not the usual HTTP port 80, because that is
the port published by the current Compose file. The notes API remains directly
available on port 3000, also matching Compose. The current nginx configuration
does not proxy `/api` to the API; this example does not change that application
behavior.

The current API healthcheck in Compose invokes Python and requests `/health`,
but the API image is Node-based and `server.js` does not define that route. The
API can still start, but Docker may report it as unhealthy. Fix that check and
add a health route before relying on container health status.

## Prerequisites

- Terraform 1.5 or newer.
- AWS CLI credentials configured for an account allowed to create VPC, EC2,
  IAM instance-profile, and security-group resources. Terraform uses the normal
  AWS provider credential chain.
- A publicly cloneable Git repository. The example host clones source over
  HTTPS without Git credentials.

## Deploy

Run these commands from this directory:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set repository_url to this repository's HTTPS URL.
terraform init
terraform validate
terraform plan
terraform apply
```

Confirm the plan before `apply`. When it completes, Terraform prints `web_url`,
`api_url`, and `instance_id`. Open `web_url` in a browser.

Cloud-init runs only when the instance is first created. To inspect startup
output after connecting with Session Manager, run:

```bash
sudo tail -n 100 /var/log/user-data.log
cd /opt/docker-projekti
sudo docker compose ps
sudo docker compose logs
```

In the AWS Console, open **EC2 → Instances**, select the instance, and choose
**Connect → Session Manager**. The instance may take a few minutes after
creation before the containers are ready.

## Remove the example resources

When finished, run:

```powershell
terraform destroy
```

The PostgreSQL data is stored in the instance's local Docker volume. It survives
container restarts and a normal instance reboot, but it is not a managed backup
and will be lost when the EC2 instance and its disk are destroyed.

## Important limitations

- The Compose file contains the demo database username and password in plain
  text. Do not use these credentials or this setup for real or sensitive data.
- Port 3000 is public to preserve the current Compose port mapping. For a
  safer deployment, remove its ingress rule from `main.tf` and the `ports`
  mapping from the Compose API service so only the proxy is reachable.
- The single public VM is a learning example, not a highly available or
  production architecture. Production deployments should consider private
  subnets, restricted ingress, managed database backups, secrets management,
  monitoring, TLS, and multiple availability zones.
- The first boot builds images on the VM and requires outbound internet access.
  The EC2 instance and public IPv4 address incur AWS charges while provisioned.
