cluster_name = "tarantool-test"
map_users = [
    {
        userarn  = "arn:aws:iam::430572752916:user/jaromil"
        username = "jaromil"
        groups   = ["system:masters"]
    },
    {
        userarn  = "arn:aws:iam::430572752916:user/alv"
        username = "alv"
        groups   = ["system:masters"]
    }
]