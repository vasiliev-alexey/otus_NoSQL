# Redis
## Необходимо:

- сохранить большой json (~20МБ) в виде разных структур - строка, hset, zset, list;
- протестировать скорость сохранения и чтения;
- предоставить отчет.
- настроить Redis кластер на 3х нодах с отказоусточивостью, оптимизировать параметры timeout

---

## Решение

### Поднимаем  Redis кластер на 3х нодах с отказоусточивостью

1. Создаем кластер
 
```
minikube start --cpus=4 --memory=4000 --nodes=4  --kubernetes-version v1.20.0  
```
PS. Пришлось отказаться - в Beta версии парметр node  не обеспечивает  сетевую связанность между узлами, и все инсталяции Redis перешли в Master.

При создании кластера в GCP  - все узлы кластера, согласовали кворум.



2. Конфигурируем [Helm  чарт от Bitnami](https://github.com/bitnami/charts/tree/master/bitnami/redis)  
   ps. [Поскольку](https://www.programmersought.com/article/82053198688/) крутим на minikube  запустить от root

Получаем  отказоустойчивый кластер

```
 kubectl get po -n redis                                            

NAME           READY   STATUS    RESTARTS   AGE
redis-node-0   3/3     Running   0          52s
redis-node-1   3/3     Running   0          35s
redis-node-2   3/3     Running   0          24s
```

export PATH=$PATH:/opt/bitnami/redis/bin

http://api.worldbank.org/v2/countries/CHN/indicators/SP.POP.TOTL?per_page=5000&format=json


curl https://raw.githubusercontent.com/json-iterator/test-data/master/large-file.json -o large.json

redis-cli -a redis -x set my-microservice-config < large.json

#### Тестируем запись

##### Строка

``` cat
curl https://raw.githubusercontent.com/json-iterator/test-data/master/large-file.json -o large.json
START_TIME=$(date +%s) &&	redis-cli -a redis -x    -r 750   set my-microservice-config < large.json  >>/dev/null  &&  echo .\ Elapsed time: $(( $(date +%s)-START_TIME ))
```

. Elapsed time:  134

##### HSET

``` cat
curl https://raw.githubusercontent.com/json-iterator/test-data/master/large-file.json -o large.json
START_TIME=$(date +%s) &&	redis-cli -a redis  -r 750   -x  hset   tttt  my-microservice-config < large.json  >>/dev/null  &&  echo .\ Elapsed time: $(( $(date +%s)-START_TIME ))

```

. Elapsed time: 153

##### ZSET


``` cat
curl https://raw.githubusercontent.com/json-iterator/test-data/master/large-file.json -o large.json
START_TIME=$(date +%s) &&	redis-cli -a redis  -r 750   -x  hset   tttt  my-microservice-config < large.json  >>/dev/null  &&  echo .\ Elapsed time: $(( $(date +%s)-START_TIME ))

```

. Elapsed time: 137

При числе попыток 1000 - нода, просто падает  - приходит OOM  killer и ее убивает. Но, благодаря этому, протестировал отказоустойчивость 😄 


##### LIST

``` cat
curl https://raw.githubusercontent.com/json-iterator/test-data/master/large-file.json -o large.json
START_TIME=$(date +%s) &&	 redis-cli -a redis -x -r 750  LSET  my-microservice-config 0  <large.json  >>/dev/null   &&  echo .\ Elapsed time: $(( $(date +%s)-START_TIME ))

```

. Elapsed time: 179


---
Итоговое распределение по  записи

| Тип        | Время           | Место
| ------------- |:-------------:| :-------------:
| string    | 134 | 1️⃣
| hset    | 153 | 3️⃣
| zset    | 137 | 2️⃣
| lset    | 179 | 4️⃣

По чтению  - стало не интересно - не думаю что результаты будут сильно разниться.