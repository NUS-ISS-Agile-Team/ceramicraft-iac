# OCD - One Click Deploy

本目录提供一个最小的 Terraform 配置，用于在 AWS 上创建一台 EC2 实例，并在实例启动时自动 clone 指定 Git 仓库并用 docker-compose 启动服务。

重要说明 / 假设
- 需要在运行 Terraform 的环境中配置好 AWS 凭证（环境变量或 shared credentials）。
- 假设存在默认 VPC。配置会在默认 VPC 中创建安全组并分配公网 IP。
- 用户需提供 `repo_url`（Git 仓库 URL）。可选：提供 `public_key_path` 将会把本地公钥上传为 key pair（同时 key_name 将使用默认或你指定的名字）。

文件
- `main.tf` - Terraform 主配置
- `variables.tf` - 可配置变量
- `outputs.tf` - 输出实例 ID / 公网 IP / DNS
- `user_data.sh.tpl` - EC2 启动脚本模板：安装 docker/git，clone repo，并执行 `docker-compose up -d`

快速使用示例
1. 在此目录创建一个 `terraform.tfvars` 或在命令行传入变量。例如新建 `ocd/terraform.tfvars`：

   repo_url = "https://github.com/your/repo.git"
   可选：
   public_key_path = "/Users/you/.ssh/id_rsa.pub"
   key_name = "ocd-deployer"

2. 初始化并应用：

```bash
cd ocd
terraform init
terraform apply
```

3. 应用完成后，输出会包含 `public_ip`，SSH 到实例或用浏览器访问应用（取决于 docker-compose 的服务配置）。

故障排查
- 如果实例未能成功运行容器：SSH 到实例(`/home/ec2-user`) 查看 `/var/log/cloud-init-output.log` 或用户脚本生成的输出；也可检查 `docker ps` / `docker-compose logs`。
- 如果使用私有仓库，需要在 user-data 中扩展认证方式（比如把私钥放到 SSM/Secrets 管理，或提前 bake AMI）。

安全提醒
- 不要在仓库中硬编码密钥或凭证。对于生产，请使用更安全的启动/配置流程（例如使用 SSM、CI/CD secrets、或预先构建的 AMI）。
