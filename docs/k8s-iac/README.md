# How to
## Spin infra
```
$ git clone https://github.com/dyne/zenswarm.git
$ cd zenswarm
zenswarm $ terraform init
zenswarm $ terraform plan -out plan.out
zenswarm $ terraform apply plan.out
```

## Add users
Edit the file `terraform.tfvars` by adding a new dictionary in the `map_users` variables, following the same format.
After saved the file, run:
```
zenswarm $ terraform plan -out plan.out
zenswarm $ terraform apply plan.out
```

## Destroy infra
```
zenswarm $ terraform destroy
```