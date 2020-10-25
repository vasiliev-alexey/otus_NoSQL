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
kind load docker-image docker.io/bitnami/mongodb-sharded:4.4.1-debian-10-r39 --name mongo &&
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


4. Аутентификация - настроена из коробки - встроена в контейнер

``` sh
 cat /opt/bitnami/mongodb/conf/mongodb.conf
```

``` sh
# set parameter options
setParameter:
   enableLocalhostAuthBypass: false
# security options
security:
  authorization: enabled
  keyFile: /opt/bitnami/mongodb/conf/keyfile
```

Создаем пользователя - дадим ему права
``` json
mongos> db.createUser(
    {
      user: "accountUser",
      pwd: passwordPrompt(), 
      roles: [ "readWrite", "dbAdmin" ]
    }
 )
```

Проверим что пользователь создался
``` sh
db.getUsers()
[
        {
                "_id" : "test.accountUser",
                "userId" : UUID("9201a3d4-c060-4c7e-a634-7c28c90e0a2b"),
                "user" : "accountUser",
                "db" : "test",
                "roles" : [
                        {
                                "role" : "readWrite",
                                "db" : "test"
                        },
                        {
                                "role" : "dbAdmin",
                                "db" : "test"
                        }
                ],
                "mechanisms" : [
                        "SCRAM-SHA-1",
                        "SCRAM-SHA-256"
                ]
        }
]
```

4. Загрузим коллекцию ISBN 

``` bash
curl https://raw.githubusercontent.com/ozlerhakan/mongodb-json-files/master/datasets/books.json -o /tmp/1.json

mongoimport -u accountUser -p qwerty --db test --collection book --file /tmp/1.json
```

5. Шардируем данные

``` sh
sh.enableSharding("test")
use test
var shardKey =
db.book.createIndex( { "isbn": "hashed" })
sh.shardCollection( "test.book", { "isbn" : "hashed" } )
sh.enableBalancing("test.book")

db.getSiblingDB("config").collections.findOne({_id : "test.book"}).noBalance;

db.settings.save( { _id:"chunksize", value: 10 } )

```

``` sh
 db.adminCommand( { listShards: 1 } )
```
| $clusterTime | ok | operationTime | shards |
| :--- | :--- | :--- | :--- |
| {"clusterTime": {}, "signature": {"hash": {}, "keyId": 6887180921871532054}} | 1 | {} | \[{"\_id": "mongodb-mongodb-sharded-shard-2", "host": "mongodb-mongodb-sharded-shard-2/mongodb-mongodb-sharded-shard2-data-0.mongodb-mongodb-sharded-headless.default.svc.cluster.local:27017", "state": 1}, {"\_id": "mongodb-mongodb-sharded-shard-1", "host": "mongodb-mongodb-sharded-shard-1/mongodb-mongodb-sharded-shard1-data-0.mongodb-mongodb-sharded-headless.default.svc.cluster.local:27017", "state": 1}, {"\_id": "mongodb-mongodb-sharded-shard-0", "host": "mongodb-mongodb-sharded-shard-0/mongodb-mongodb-sharded-shard0-data-0.mongodb-mongodb-sharded-headless.default.svc.cluster.local:27017", "state": 1}\] |


``` sh
mongos>  db.getSiblingDB("test").book.getShardDistribution();

Shard mongodb-mongodb-sharded-shard-2 at mongodb-mongodb-sharded-shard-2/mongodb-mongodb-sharded-shard2-data-0.mongodb-mongodb-sharded-headless.default.svc.cluster.local:27017
 data : 505KiB docs : 431 chunks : 1
 estimated data per chunk : 505KiB
 estimated docs per chunk : 431

Totals
 data : 505KiB docs : 431 chunks : 1
 Shard mongodb-mongodb-sharded-shard-2 contains 100% data, 100% docs in cluster, avg obj size on shard : 1KiB
```

Нагенерим данных

``` sh
for (var i = 1; i <= 100000; ++i) {
  db.book.insert({
      isbn: randomName(),
      author: randomName(),
      title: randomName
  });
}
```

Запустивщийся ребалансировщик размазал наши данные

```
mongos> db.getSiblingDB("test").book.getShardDistribution();

Shard mongodb-mongodb-sharded-shard-2 at mongodb-mongodb-sharded-shard-2/mongodb-mongodb-sharded-shard2-data-0.mongodb-mongodb-sharded-headless.default.svc.cluster.local:27017
 data : 20.19MiB docs : 231702 chunks : 1
 estimated data per chunk : 20.19MiB
 estimated docs per chunk : 231702

Totals
 data : 20.19MiB docs : 231702 chunks : 1
 Shard mongodb-mongodb-sharded-shard-2 contains 100% data, 100% docs in cluster, avg obj size on shard : 91B

mongos> db.settings.save( { _id:"chunksize", value: 10 } )
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 0 })
mongos> db.settings.save( { _id:"chunksize", value: 10 } )
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 0 })
mongos> 



Shard mongodb-mongodb-sharded-shard-2 at mongodb-mongodb-sharded-shard-2/mongodb-mongodb-sharded-shard2-data-0.mongodb-mongodb-sharded-headless.default.svc.cluster.local:27017
 data : 21.43MiB docs : 246239 chunks : 2
 estimated data per chunk : 10.71MiB
 estimated docs per chunk : 123119

Shard mongodb-mongodb-sharded-shard-0 at mongodb-mongodb-sharded-shard-0/mongodb-mongodb-sharded-shard0-data-0.mongodb-mongodb-sharded-headless.default.svc.cluster.local:27017
 data : 10.92MiB docs : 125671 chunks : 2
 estimated data per chunk : 5.46MiB
 estimated docs per chunk : 62835

Shard mongodb-mongodb-sharded-shard-1 at mongodb-mongodb-sharded-shard-1/mongodb-mongodb-sharded-shard1-data-0.mongodb-mongodb-sharded-headless.default.svc.cluster.local:27017
 data : 11.55MiB docs : 133224 chunks : 3
 estimated data per chunk : 3.85MiB
 estimated docs per chunk : 44408

Totals
 data : 43.92MiB docs : 505134 chunks : 7
 Shard mongodb-mongodb-sharded-shard-2 contains 48.79% data, 48.74% docs in cluster, avg obj size on shard : 91B
 Shard mongodb-mongodb-sharded-shard-0 contains 24.88% data, 24.87% docs in cluster, avg obj size on shard : 91B
 Shard mongodb-mongodb-sharded-shard-1 contains 26.31% data, 26.37% docs in cluster, avg obj size on shard : 90B
```





6. Проверим что запросы работают 

``` sh
db.book.find({ categories: "Microsoft .NET"}).skip(5).limit(1);
```
| \_id | authors | categories | isbn | longDescription | pageCount | publishedDate | shortDescription | status | thumbnailUrl | title |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 137 | \["Yvonne M. Harryman"\] | \["Microsoft .NET"\] | 1933988754 | For every SharePoint 2010 developer who spends the day buried in Visual Studio cranking out code, there are dozens of other SharePoint site owners who want to share information, create content portals, and add features to existing SharePoint sites. If you're one of these SharePoint administrators, this is the book for you. Chock-full of great ideas and scenarios you'll relate to immediately, this book will teach you the amazing things you can do with SharePoint 2010 without writing any code   or calling in the developers.    SharePoint 2010 Site Owner's Manual starts by assuming you already have SharePoint installed on your system and are looking for ways to solve the problems you face every day in your organization. You'll learn to determine what type of SharePoint installation you have   Microsoft Office SharePoint Server \(MOSS\), Windows SharePoint Services \(WSS\), the "Fabulous 40" templates   and what features are at your disposal. Once you know the lay of the land, you'll discover what you can do yourself, when you need to call in some help, and when you should leave it to the developers.    This book teaches you by putting your hands on working SharePoint examples. You'll see seven common SharePoint-driven sites that lay out the features and approaches you'll need for most typical applications. The examples range from a simple document-sharing portal, to a SharePoint-hosted blog, to a project management site complete with a calendar, discussion forums, and an interactive task list. | 300 | 2012-02-13T08:00:00.000Z | SharePoint 2010 Site Owner's Manual starts by assuming you already have SharePoint installed on your system and are looking for ways to solve the problems you face every day in your organization. You'll learn to determine what type of SharePoint installation you have   Microsoft Office SharePoint Server \(MOSS\), Windows SharePoint Services \(WSS\), the "Fabulous 40" templates   and what features are at your disposal. Once you know the lay of the land, you'll discover what you can do yourself, when you need to call in some help, and when you should leave it to the developers. | PUBLISH | https://s3.amazonaws.com/AKIAJC5RLADLUMVRPFDQ.book-thumb-images/harryman.jpg | SharePoint 2010 Site Owner's Manual |



уроним ноду - остановим контейнер который хостит ноду кластера

 
Видим ошибку
```
mongos> db.book.find({ categories: "Microsoft .NET"}).skip(5).limit(1);

Error: error: {
        "ok" : 0,
        "errmsg" : "Encountered non-retryable error during query :: caused by :: Could not find host matching read preference { mode: \"primary\" } for set mongodb-mongodb-sharded-shard-2",
        "code" : 133,
        "codeName" : "FailedToSatisfyReadPreference",
        "operationTime" : Timestamp(1603558249, 2),
        "$clusterTime" : {
                "clusterTime" : Timestamp(1603558278, 1),
                "signature" : {
                        "hash" : BinData(0,"EtwXxI+Gn8qu4fP1y8iNOi+moWM="),
                        "keyId" : NumberLong("6887180921871532054")
                }
        }
}
```

Поднимаем контейнер  - работоспособность восстановлена

``` sh
mongos> db.book.find({ categories: "Microsoft .NET"}).skip(5).limit(1);
{ "_id" : 239,
```

6. [По инструкции поудаляем шард](https://docs.mongodb.com/manual/tutorial/remove-shards-from-cluster/)


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


