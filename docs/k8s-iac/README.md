# How to
## Spin infra
```
$ git clone https://github.com/dyne/zenswarm.git
$ cd zenswarm/docs/k8s-iac
zenswarm/docs/k8s-iac $ terraform init
zenswarm/docs/k8s-iac $ terraform plan -out plan.out
zenswarm/docs/k8s-iac $ terraform apply plan.out
```

## Add users
Edit the file `terraform.tfvars` by adding a new dictionary in the `map_users` variables, following the same format.
After saved the file, run:
```
zenswarm/docs/k8s-iac $ terraform plan -out plan.out
zenswarm/docs/k8s-iac $ terraform apply plan.out
```

## Destroy infra
```
zenswarm/docs/k8s-iac $ terraform destroy
```