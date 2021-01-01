resource "helm_release" "tarantool-operator" {
count= 0
  name             = "tarantool-operator"
  chart            = "tarantool-operator"
  namespace        = "tarantool"
  timeout          = 600
  repository       = "https://tarantool.github.io/tarantool-operator"
  create_namespace = true
}


resource "helm_release" "kv-storage" {
count = 0
  name             = "kv-storage"
  chart            = "../kv-storage"
  namespace        = "tarantool"
  timeout          = 600
  create_namespace = true
  depends_on = [helm_release.tarantool-operator]
}

resource "helm_release" "crud" {
count = 1
  name             = "crud"
  chart            = "../crud"
  namespace        = "tarantool"
  timeout          = 600
    repository       = "https://tarantool.github.io/tarantool-operator"
  create_namespace = true

}


resource "null_resource" "helm_update" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "cd ../crud && helm repo add tarantool https://tarantool.github.io/tarantool-operator && helm dep build"
  }
}