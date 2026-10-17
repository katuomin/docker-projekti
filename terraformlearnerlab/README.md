# Terraform on AWS Academy Learner Lab

A reduced version of [../terraformexample](../terraformexample) for the
restricted Learner Lab account. It creates just a security group and one EC2
instance that runs the existing `docker-compose.yaml`.

## What differs from `terraformexample`

| Learner Lab limit | Handling here |
|---|---|
| Cannot create IAM roles/instance profiles | Attaches the pre-made `LabInstanceProfile` (optional) |
| VPC/subnet/gateway creation often denied | Uses the default VPC; AWS picks a subnet in an AZ that supports the instance type |
| Only `us-east-1` / `us-west-2` | Default region `us-east-1` |
| Small instance types only | `t3.small` default |
| Credentials expire with the session | Uses the temporary keys from the lab |
| Session Manager may not work | SSH on port 22 with the lab's `vockey` key |

## Steps

1. Start the lab and open **AWS Details → Show**. Copy the three values.
2. Set them in the terminal where you run Terraform:

   ```powershell
   $env:AWS_ACCESS_KEY_ID     = "ASIA..."
   $env:AWS_SECRET_ACCESS_KEY = "..."
   $env:AWS_SESSION_TOKEN     = "..."
   $env:AWS_REGION            = "us-east-1"
   ```

   (WSL/bash: `export AWS_ACCESS_KEY_ID=...` and so on.) Alternatively paste
   them into `~/.aws/credentials` under `[default]`.
3. Check them: `aws sts get-caller-identity`.
4. Deploy:

   ```
   terraform init
   terraform apply
   ```

5. Open the `web_url` output after a few minutes (first boot installs Docker and
   builds images).

No variables are required. The repository URL defaults to this repository, so
it must be public and the branch must exist (`main` by default). To use another
branch: `terraform apply -var repository_branch=terraformtesti`.

## Troubleshooting

- **Credential errors / `ExpiredToken`:** the lab session ended or keys changed.
  Copy fresh values and re-export them. Don't leave the `~/.aws/credentials`
  entry stale.
- **Instance profile or key pair not found:** set `-var instance_profile_name=""`
  or `-var key_name=""`.
- **Check boot progress** over SSH: `sudo tail -f /var/log/user-data.log` and
  `cd /opt/docker-projekti && sudo docker compose ps`.
- **Restrict access:** `-var allowed_cidr="<your-ip>/32"`.

## Cleanup

Run `terraform destroy` before ending the lab. If the lab resets, the state
file may point at resources that no longer exist; delete the local
`terraform.tfstate*` files and start again.
