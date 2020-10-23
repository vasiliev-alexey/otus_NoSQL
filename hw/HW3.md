# MongoDB 2

## Цель: В результате выполнения ДЗ вы настроите реплицирование и шардирование, аутентификацию в кластере и проверите отказоустойчивость.

Необходимо:

* построить шардированный кластер из 3 кластерных нод( по 3 инстанса с репликацией) и с кластером конфига(3 инстанса);
* добавить балансировку, нагрузить данными, выбрать хороший ключ шардирования, посмотреть как данные перебалансируются между шардами;
* настроить аутентификацию и многоролевой доступ;
* поронять разные инстансы, посмотреть, что будет происходить, поднять обратно. Описать что произошло.

Формат сдачи - readme с описанием алгоритма действий, результатами и проблемами. 

--- 
## Решение

0. Расматриваем варианты реализации
   * [DockerCompose](https://github.com/minhhungit/mongodb-cluster-docker-compose)
   * [Ansible](https://medium.com/setup-a-production-ready-mongodb-4-2-replica-set/setup-a-production-ready-mongodb-4-2-replica-set-with-ansible-2ba26b7bcf73) и  [ansible 2](https://severalnines.com/database-blog/deploying-configuring-mongodb-shards-ansible)
   * [Kubernetes](https://github.com/bitnami/charts/tree/master/bitnami/mongodb-sharded)


1. Развернем по молодежному в k8s
2. Создаем кластер с 3 нодами

``` bash
cd shard && kind create cluster --config kind-config.yaml
```

Чтоб не скачивать с интернета - подложим локальные образы с хостовой машины

``` sh
kind load docker-image docker.io/bitnami/mongodb-sharded:4.4.1-debian-10-r39 --name mongo
kind load docker-image docker.io/bitnami/mongodb-exporter:0.11.2-debian-10-r18 --name mongo
```


3.  Деплоим  через Terraform-Helm чарт mongo на созданный кластер + Prometheus + Grafana

``` sh
terraform  apply -auto-approve   
```

``` yaml
 # Реплицируем управляющий контроллер на все 3 ноды
  set {
    name  = "mongos.replicas"
    value = 3
  }
# Реплицируем конфигурационный сервер на все 3 ноды
  set {
    name  = "configsvr.replicas"
    value = 3
  }
# Шардируем по 3
  set {
    name  = "shards"
    value = 3
  }
  
#  паролб для рута
  set {
    name  = "mongodbRootPassword"
    value = "mongopass"
  }
# включаем сбор метрик для prometheus  
  set {
    name  = "metrics.enabled"
    value = true
  }

    set {
    name  = "metrics.serviceMonitor.enable"
    value = true
  }
      set {
    name  = "metrics.kafka.enabled"
    value = true
  }
  

```

Получаем требуемую инфраструктуру

``` sh
NAME                                              READY   STATUS    RESTARTS   AGE
mongodb-mongodb-sharded-configsvr-0               2/2     Running   0          6m48s
mongodb-mongodb-sharded-configsvr-1               2/2     Running   0          5m40s
mongodb-mongodb-sharded-configsvr-2               2/2     Running   0          4m33s
mongodb-mongodb-sharded-mongos-64878bb7db-4ftdv   2/2     Running   1          6m48s
mongodb-mongodb-sharded-mongos-64878bb7db-58lvn   2/2     Running   1          6m48s
mongodb-mongodb-sharded-mongos-64878bb7db-b7hj6   2/2     Running   1          6m48s
mongodb-mongodb-sharded-shard0-data-0             2/2     Running   1          6m48s
mongodb-mongodb-sharded-shard1-data-0             2/2     Running   1          6m48s
mongodb-mongodb-sharded-shard2-data-0             2/2     Running   0          86s
```


--- 
Материалы
* https://github.com/minhhungit/mongodb-cluster-docker-compose
* [Официальная документация](https://docs.mongodb.com/manual/sharding/)
* [k8s - MongoDB Sharded](https://github.com/bitnami/charts/tree/master/bitnami/mongodb-sharded)
* [Настройка MongoDB ShardedCluster с X.509 аутентификацией](https://habr.com/ru/post/308740/)
* [Руководство по выживанию с MongoDB](https://habr.com/ru/company/oleg-bunin/blog/454748/)
* http://highload.guide/blog/sharding-patterns-and-antipatterns.html
* [MongoDB Prometheus Exporter Dashboard](https://grafana.com/grafana/dashboards/2583)
### Видео 

[![MongoDB](https://img.youtube.com/vi/j6TVaEk4x2U/0.jpg)](https://www.youtube.com/watch?v=j6TVaEk4x2U)

*Sharding: patterns and antipatterns / К.Осипов (Mail ru, Tarantool), А.Рыбак (Badoo)*  


[![MongoDB](https://img.youtube.com/vi/URHoFbn4rt8/0.jpg)](https://www.youtube.com/watch?v=URHoFbn4rt8)


