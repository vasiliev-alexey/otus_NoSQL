# Масштабирование и отказоустойчивость Cassandra. Часть 1

## Цель: Подготовить среду и развернуть Cassandra кластер для дальнейшего изучения возможностей масштабирования и восстановления Cassandra кластеров.

## Необходимо:
* развернуть Kubernetes кластер в облаке или локально (используя "ПРЕРЕКВИЗИТЫ.docx" из материралов);
* поднять 3 узловый Cassandra кластер на Kubernetes (используя "How to Run Cassandra on Azure Kubernetes Service (AKS), part1.pdf" из материралов);
* нагрузить кластер при помощи Cassandra Stress Tool (используя "How to use Apache Cassandra Stress Tool.pdf" из материалов).

### Решение

 1. Создаем [манифест](../cassandra/infra/main.tf)  для развертывания кластера с 3 нодами

```
kubectl get  no -n cassandra

NAME                                                  STATUS   ROLES    AGE     VERSION
gke-av-cassandra-k8s-av-k8s-node-pool-965d6753-cqbt   Ready    <none>   8m40s   v1.16.15-gke.4300
gke-av-cassandra-k8s-av-k8s-node-pool-965d6753-lr03   Ready    <none>   8m37s   v1.16.15-gke.4300
gke-av-cassandra-k8s-av-k8s-node-pool-965d6753-q1c1   Ready    <none>   8m38s   v1.16.15-gke.4300
gke-av-cassandra-k8s-av-k8s-node-pool-965d6753-ql0j   Ready    <none>   8m39s   v1.16.15-gke.4300

```

 ### 2. Создаем манифест для развертывания Cassandra кластера с помощью  [Helm чарта](https://github.com/bitnami/charts/tree/master/bitnami/cassandra)

``` sh
kubectl get po -n cassandra                                                                

NAME              READY   STATUS    RESTARTS   AGE
cassandra-lab-0   1/1     Running   0          5m20s
cassandra-lab-1   1/1     Running   0          3m42s
cassandra-lab-2   1/1     Running   0          114s
```

```
nodetool status

Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address   Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.0.4.4  70.68 KiB  256          69.0%             f47a84c6-494f-468b-a0e8-f043d064b7d7  rack1
UN  10.0.2.8  70.71 KiB  256          66.6%             c35ca664-8b3c-4d4e-8827-7dc8763f488f  rack1
UN  10.0.3.9  70.73 KiB  256          64.4%             4b964b37-eabf-4cd0-bb03-50b0f7db26f1  rack1

```

### 3. Даем нагрузку

* подключаемся к поду cassandra-lab-0
* даем нагрузку на запись

```
cassandra-lab-0:/opt/bitnami/cassandra/tools/bin$ ./cassandra-stress write n=1000000 -mode thrift  user=admin password=password  

```
Результаты
```

Results:
Op rate                   :    6,070 op/s  [WRITE: 6,070 op/s]
Partition rate            :    6,070 pk/s  [WRITE: 6,070 pk/s]
Row rate                  :    6,070 row/s [WRITE: 6,070 row/s]
Latency mean              :   32.8 ms [WRITE: 32.8 ms]
Latency median            :   32.1 ms [WRITE: 32.1 ms]
Latency 95th percentile   :   75.7 ms [WRITE: 75.7 ms]
Latency 99th percentile   :  171.3 ms [WRITE: 171.3 ms]
Latency 99.9th percentile :  361.5 ms [WRITE: 361.5 ms]
Latency max               :  754.5 ms [WRITE: 754.5 ms]
Total partitions          :  1,000,000 [WRITE: 1,000,000]
Total errors              :          0 [WRITE: 0]
Total GC count            : 83
Total GC memory           : 12.678 GiB
Total GC time             :    9.2 seconds
Avg GC time               :  110.4 ms
StdDev GC time            :   62.6 ms
Total operation time      : 00:02:44

END
```

* даем нагрузку на чтение

```
cassandra-lab-0:/opt/bitnami/cassandra/tools/bin$ ./cassandra-stress read  n=1000000 -mode thrift  user=admin password=password  
```

Результаты
```
Results:
Op rate                   :    5,797 op/s  [READ: 5,797 op/s]
Partition rate            :    5,797 pk/s  [READ: 5,797 pk/s]
Row rate                  :    5,797 row/s [READ: 5,797 row/s]
Latency mean              :    2.7 ms [READ: 2.7 ms]
Latency median            :    2.1 ms [READ: 2.1 ms]
Latency 95th percentile   :    6.3 ms [READ: 6.3 ms]
Latency 99th percentile   :   13.4 ms [READ: 13.4 ms]
Latency 99.9th percentile :   76.8 ms [READ: 76.8 ms]
Latency max               :  257.8 ms [READ: 257.8 ms]
Total partitions          :  1,000,000 [READ: 1,000,000]
Total errors              :          0 [READ: 0]
Total GC count            : 103
Total GC memory           : 16.087 GiB
Total GC time             :    5.4 seconds
Avg GC time               :   52.5 ms
StdDev GC time            :   23.4 ms
Total operation time      : 00:02:52

Improvement over 8 threadCount: 10%

```

--- 
### Материалы

* [The cassandra-stress tool](https://docs.datastax.com/en/dse/5.1/dse-dev/datastax_enterprise/tools/toolsCStress.html#toolsCStress)
* [Документация Cassandra Stress](https://cassandra.apache.org/doc/latest/tools/cassandra_stress.html)
* [Чарт для k8s bitnami/cassandra](https://github.com/bitnami/charts/tree/master/bitnami/cassandra)
* [Как устроена apache cassandra](https://habr.com/ru/post/155115/)