# MongoDB

## Цель: В результате выполнения ДЗ вы научитесь разворачивать MongoDB, заполнять данными и делать запросы.
Необходимо:
- установить MongoDB одним из способов: ВМ, докер;
- заполнить данными;
- написать несколько запросов на выборку и обновление данных

Сдача ДЗ осуществляется в виде миниотчета.

* создать индексы и сравнить производительность.
Критерии оценки: Критерии оценки:
- задание выполнено - 5 баллов
- предложено красивое решение - плюс 1 балл
- предложено рабочее решение, но не устранены недостатки, указанные преподавателем - минус 1 балл
- плюс 3 балла за задание со *

---

## Решение

### 1. Установка MongoDb
Написан  [playbook](../mongo/install/playbooks/mongo_inst.yaml) Ansible для установки и конфигурирования доступа по сети

~~~ sh
cd otus_NoSQL/mongo/install/playbooks &&  ansible-playbook mongo_inst.yaml
~~~

### 2. Импорт существующих данных для Mongo

Написан  [playbook](../mongo/install/playbooks/data_load.yaml) Ansible для загрузки и заливки данных из  ozlerhakan /
mongodb-json-files 

~~~ sh
cd otus_NoSQL/mongo/install/playbooks &&  ansible-playbook data_load.yaml
~~~

### 3.  написать несколько запросов на выборку и обновление данных

~~~ sh
// Найти все книги  по isbn 
db.book.find({ isbn: "1932394524f-e"})
~~~

| \_id | authors | categories | isbn | pageCount | publishedDate | status | thumbnailUrl | title |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 125 | \["Vikram Goyal"\] | \["Java"\] | 1932394524f-e | 0 | 2005-03-01T08:00:00.000Z | PUBLISH | https://s3.amazonaws.com/AKIAJC5RLADLUMVRPFDQ.book-thumb-images/goyal6.jpg | Validating Data with Validator |

~~~ sh
# Количество книг в разных статусах

db.book.aggregate( [
  {
    $group: {
       _id : "$status",
       count: { $sum: 1 }
    }
  }

  ,
{
    $project: {
        "state": "$_id",
        count: 2,
"_id": 0
    }
}

] )
~~~

| count | state |
| :--- | :--- |
| 68 | MEAP |
| 363 | PUBLISH |

~~~ sh
# удалим чего-нибудь
db.book.deleteMany({isbn: "1932394524f-e"})
~~~
| acknowledged | deletedCount |
| :--- | :--- |
| true | 1 |


~~~ sh
# найдем лонгриды
db.book.find({pageCount:  {$gt:1000}}
,
{pageCount:11 , title:10,  _id:0}

)
~~~
| pageCount | title |
| :--- | :--- |
| 1101 | Essential Guide to Peoplesoft Development and Customization |
| 1088 | Java Foundation Classes |
| 1096 | Ten Years of UserFriendly.Org |
