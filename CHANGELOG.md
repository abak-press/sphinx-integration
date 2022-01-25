# v7.16.0

* 2022-01-25 [be55e7f](../../commit/be55e7f) - __(git2-railsc)__ Release 7.16.0 
* 2022-01-13 [35b90c1](../../commit/35b90c1) - __(Gelani Geliskhanov)__ feat(index): added email notification after index 
https://jira.railsc.ru/browse/PC4-27616

# v7.15.0

* 2021-10-14 [9831ccc](../../commit/9831ccc) - __(Andrew N. Shalaev)__ fix: set busy status properly 
* 2021-09-23 [b2a93ca](../../commit/b2a93ca) - __(Andrew N. Shalaev)__ feature: add busy status for server, search consider busyness 
https://jira.railsc.ru/browse/BPC-19494

* 2021-09-20 [9ef8107](../../commit/9ef8107) - __(Andrew N. Shalaev)__ fix: use nonblock version of Socket connect 
https://jira.railsc.ru/browse/BPC-19478

# v7.14.2

* 2021-07-16 [87af0f9](../../commit/87af0f9) - __(Andrew N. Shalaev)__ fix: wait before the previous node has rotated 
https://jira.railsc.ru/browse/BPC-19000

* 2021-07-19 [852a516](../../commit/852a516) - __(Andrew N. Shalaev)__ feature: add ruby 2.4 support 

# v7.14.1

* 2021-07-05 [94fae41](../../commit/94fae41) - __(Andrew N. Shalaev)__ fix: add mysql_vip port only if present in cfg 

# v7.14.0

* 2021-07-05 [7f294eb](../../commit/7f294eb) - __(Andrew N. Shalaev)__ feature: remove disable/enable host before rotation 
https://jira.railsc.ru/browse/BPC-19000

# v7.13.0

* 2021-06-25 [e519592](../../commit/e519592) - __(Andrew N. Shalaev)__ fix: partial nonblock reading + test coverage 
* 2021-06-24 [8af7fde](../../commit/8af7fde) - __(Andrew N. Shalaev)__ feature: allow to use old fationed method for read from sock 
* 2021-06-24 [4b1191c](../../commit/4b1191c) - __(Andrew N. Shalaev)__ feature: refactoring logging 
* Throw bactrace in debug mode only
* Log previous server name

https://jira.railsc.ru/browse/BPC-18844

* 2021-06-22 [65f0f30](../../commit/65f0f30) - __(Andrew N. Shalaev)__ fix: wrong types of args 
* 2021-06-21 [50c02ce](../../commit/50c02ce) - __(Andrew N. Shalaev)__ fix: configure read_timeout 
* 2021-06-18 [4b0f420](../../commit/4b0f420) - __(Andrew N. Shalaev)__ fix: decrease timeout, freeze strings and fix some misspells 
https://jira.railsc.ru/browse/BPC-18936

* 2021-06-16 [4f9a737](../../commit/4f9a737) - __(Andrew N. Shalaev)__ fix: add timeout for reading from socket 
https://jira.railsc.ru/browse/BPC-18936

* 2021-06-14 [31c85c7](../../commit/31c85c7) - __(Andrew N. Shalaev)__ fix: query to another server if sphinx responded with retry error 
https://jira.railsc.ru/browse/BPC-18802

* 2021-06-12 [71873e2](../../commit/71873e2) - __(Andrew N. Shalaev)__ feature: add more configuration options 
https://jira.railsc.ru/browse/BPC-18802

* 2021-06-12 [6dfe983](../../commit/6dfe983) - __(Andrew N. Shalaev)__ feature: allow to configure _vip connections 
https://jira.railsc.ru/browse/BPC-18802

* 2021-06-03 [f5a2342](../../commit/f5a2342) - __(Andrew N. Shalaev)__ fix: do not pull docker images 
* 2021-06-03 [a9a0697](../../commit/a9a0697) - __(Andrew N. Shalaev)__ feature: add ionice for rsync command 
https://jira.railsc.ru/browse/BPC-18868

# v7.12.1

* 2021-05-18 [fbf729e](../../commit/fbf729e) - __(Andrew N. Shalaev)__ feature: add INT_INFINITY_VAL default constant 

# v7.12.0

* 2021-02-25 [c23a527](../../commit/c23a527) - __(TamarinEA)__ chore: decrease buffer size 
* 2021-01-26 [6cd4bec](../../commit/6cd4bec) - __(TamarinEA)__ feature: ability to rename cte 
https://jira.railsc.ru/browse/GOODS-2607

# v7.11.0

* 2020-12-30 [7a32189](../../commit/7a32189) - __(Andrew N. Shalaev)__ feature: gracefull rotation 

# v7.10.2

* 2020-07-22 [083278d](../../commit/083278d) - __(Ilya Zhidkov)__ feature: decrease compress level for indexes copying https://jira.railsc.ru/browse/PC4-25477 

# v7.10.1

* 2020-08-20 [ce0f1af](../../commit/ce0f1af) - __(TamarinEA)__ chore: use custom batch size when replace all 
* 2020-08-19 [70fc928](../../commit/70fc928) - __(TamarinEA)__ fix: do not use find in batches when id present 
https://jira.railsc.ru/browse/GOODS-2512

# v7.10.0

* 2020-08-16 [40006f2](../../commit/40006f2) - __(TamarinEA)__ chore: add homepage 
* 2020-08-12 [6711e33](../../commit/6711e33) - __(TamarinEA)__ feature: use retransmit instead of update 
https://jira.railsc.ru/browse/GOODS-2445

# v7.9.0

* 2020-07-09 [07ad2c9](../../commit/07ad2c9) - __(TamarinEA)__ feature: wait index rotation 
https://jira.railsc.ru/browse/GOODS-2439

# v7.8.1

* 2020-04-08 [1055404](../../commit/1055404) - __(Mikhail Nelaev)__ fix: do not modify transmitted records 

# v7.8.0

* 2020-03-02 [8c32696](../../commit/8c32696) - __(TamarinEA)__ chore: use next drone 
* 2020-03-02 [e1a333d](../../commit/e1a333d) - __(TamarinEA)__ chore: lock simplecov-html 
* 2020-02-27 [e469419](../../commit/e469419) - __(TamarinEA)__ feature: delete prev rt rows when indexing 
https://jira.railsc.ru/browse/GOODS-2250

* 2020-02-26 [63ebe98](../../commit/63ebe98) - __(TamarinEA)__ feature: replay transmitter update from rt index 
https://jira.railsc.ru/browse/GOODS-2250

# v7.7.0

* 2020-01-15 [36b6b6c](../../commit/36b6b6c) - __(TamarinEA)__ fix: split replayer by index name 
https://jira.railsc.ru/browse/GOODS-2176

* 2020-01-15 [8d20570](../../commit/8d20570) - __(TamarinEA)__ chore: lock public_suffix 
* 2020-01-13 [f9a93f7](../../commit/f9a93f7) - __(TamarinEA)__ chore: lock redis-namespace 

# v7.6.7

* 2019-10-18 [c645654](../../commit/c645654) - __(TamarinEA)__ fix: do not use value to boolean from rails 

# v7.6.6

* 2019-07-23 [e0b660b](../../commit/e0b660b) - __(Andrew N. Shalaev)__ feature: rails4.1-4.2 support 

# v7.6.5

* 2019-07-03 [0990772](../../commit/0990772) - __(Andrew N. Shalaev)__ fix: constraint version of gems for ruby < v2.3 
* 2019-07-03 [e8ca015](../../commit/e8ca015) - __(Andrew N. Shalaev)__ fix: set default values in #fast_facet_ts_args 

# v7.6.4

* 2019-06-28 [2447bb1](../../commit/2447bb1) - __(Andrew N. Shalaev)__ fix: dont override ts_args in fast_facet 

# v7.6.3

* 2019-05-07 [7c4b90f](../../commit/7c4b90f) - __(Andrew N. Shalaev)__ fix: wrong log initialization 

# v7.6.2

* 2019-04-10 [eb8a9a2](../../commit/eb8a9a2) - __(Andrew N. Shalaev)__ fix: move logger method into class 

# v7.6.1

* 2019-04-10 [35b4b3b](../../commit/35b4b3b) - __(Andrew N. Shalaev)__ fix: undefined method to_sym 

# v7.6.0

* 2019-04-09 [d00e4fc](../../commit/d00e4fc) - __(Andrew N. Shalaev)__ feature: add ruby2.3 support and drop rails3.2 
* 2019-04-09 [89bec6b](../../commit/89bec6b) - __(Andrew N. Shalaev)__ feature: remove dry-* trash 

# v7.5.1

* 2018-12-10 [4e98d15](../../commit/4e98d15) - __(Andrew N. Shalaev)__ fix: do not calculate sphinx_offset in cycle 

# v7.5.0

* 2018-12-07 [972e313](../../commit/972e313) - __(Andrew N. Shalaev)__ feature: increase timeout for replayer 

# v7.4.1

* 2018-12-03 [01026b3](../../commit/01026b3) - __(Andrew N. Shalaev)__ feature: configure log for sphinx:rebuild 
https://jira.railsc.ru/browse/BPC-13333

# v7.4.0

* 2018-11-19 [c0f3929](../../commit/c0f3929) - __(Andrew N. Shalaev)__ feature: delayed replay log 
* 2018-11-30 [84bc7b7](../../commit/84bc7b7) - __(Andrew N. Shalaev)__ fix: dry-auto_inject < 0.6.0 
* 2018-11-30 [004b44b](../../commit/004b44b) - __(Andrew N. Shalaev)__ feature: configure log device 
https://jira.railsc.ru/browse/BPC-13333

# v7.3.2

* 2018-11-19 [926495c](../../commit/926495c) - __(Andrew N. Shalaev)__ Release  v7.3.2 
* 2018-11-19 [5df2568](../../commit/5df2568) - __(Andrew N. Shalaev)__ fix: do not merge ids into huge list of soft delete log 
https://jira.railsc.ru/browse/BPC-13524

# v7.3.1

* 2018-11-16 [d153f52](../../commit/d153f52) - __(Andrew N. Shalaev)__ fix: timeouts of replay of soft delete log 

# v7.3.0

* 2018-10-24 [def6e56](../../commit/def6e56) - __(Korotaev Danil)__ feat: add buffered_transmitter 
https://jira.railsc.ru/browse/GOODS-1524

# v7.2.0

* 2018-10-29 [15db080](../../commit/15db080) - __(Andrew N. Shalaev)__ fix: not transmit if empty array from select query 
* 2018-10-24 [c0dba2f](../../commit/c0dba2f) - __(Andrew N. Shalaev)__ fix: dont reuse connection 
* 2018-10-18 [9d440a8](../../commit/9d440a8) - __(Andrew N. Shalaev)__ feature: transmitter job 
* 2018-10-16 [07dfd99](../../commit/07dfd99) - __(Andrew N. Shalaev)__ fix: use single sql query for single record in transmit 
* 2018-10-16 [d2d7694](../../commit/d2d7694) - __(Andrew N. Shalaev)__ feature: batched delete 
* 2018-10-16 [0662a69](../../commit/0662a69) - __(Andrew N. Shalaev)__ feature: replace AR instances in arguments to primitive Integer 
* 2018-09-28 [d4e1926](../../commit/d4e1926) - __(Andrew N. Shalaev)__ feature: conditional transmitter_update and transmitter_destroy 
* 2018-09-24 [69a3a95](../../commit/69a3a95) - __(Andrew N. Shalaev)__ feature: allow to replace by batches 
* 2018-08-08 [bc8f312](../../commit/bc8f312) - __(Andrew N. Shalaev)__ feature: allow to replace method send batches 

# v7.1.2

* 2018-10-11 [2ae2a3f](../../commit/2ae2a3f) - __(Andrew N. Shalaev)__ fix: not raise any errors in when trying to stop sphinx 

# v7.1.1

* 2018-10-03 [bdff220](../../commit/bdff220) - __(Andrew N. Shalaev)__ Release v7.0.1 
* 2018-10-03 [216e5f6](../../commit/216e5f6) - __(Andrew N. Shalaev)__ fix: disable notification about failed stop in stage 

# v7.1.0

* 2018-09-11 [affa47b](../../commit/affa47b) - __(TamarinEA)__ feature: log error message when error on server 
https://jira.railsc.ru/browse/BPC-11892


f

# v7.0.0

* 2018-01-30 [25f981c](../../commit/25f981c) - __(Michail Merkushin)__ fix: Ignore field groups when preparing matching 
https://jira.railsc.ru/browse/PC4-21238

* 2017-12-28 [0d91973](../../commit/0d91973) - __(Michail Merkushin)__ feat: Distinct sphinx indexing 
https://jira.railsc.ru/browse/PC4-21238

# v6.1.0

* 2017-12-20 [c6b8fd4](../../commit/c6b8fd4) - __(Dmitry Bochkarev)__ fix: не оборачиваем условия композитного индекса в скобочки 
https://jira.railsc.ru/browse/PC4-21220

* 2017-12-19 [a105fa7](../../commit/a105fa7) - __(Dmitry Bochkarev)__ fix: не добавляем в композитный матчинг пустые условия 
https://jira.railsc.ru/browse/PC4-21220

https://github.com/abak-press/pulscen/pull/16040

* 2017-11-28 [96b579c](../../commit/96b579c) - __(Dmitry Bochkarev)__ feature: композитные индексы 
https://jira.railsc.ru/browse/PC4-21024
https://jira.railsc.ru/browse/PC4-20969 - проектирование

Пришлось переопределять метод query, т.к. есть места где товарный лоадер
копируется и в нем проиходит изменение conditions - принял решение
conditions не модифицировать, а подменять.

# v6.0.0

* 2017-11-02 [e43b182](../../commit/e43b182) - __(Michail Merkushin)__ feat: Log when replaying was finished 
https://jira.railsc.ru/browse/PC4-20727

* 2017-11-01 [1aac632](../../commit/1aac632) - __(Michail Merkushin)__ tests: Fix rspec deprecations 
* 2017-10-31 [a409121](../../commit/a409121) - __(Michail Merkushin)__ feat: Add replayer and independent log for soft deletes 
https://jira.railsc.ru/browse/PC4-20727

* 2017-10-30 [6bcfe8e](../../commit/6bcfe8e) - __(Michail Merkushin)__ feat: Replay query_log with batches 
https://jira.railsc.ru/browse/PC4-20727

* 2017-10-25 [66b11ee](../../commit/66b11ee) - __(Michail Merkushin)__ fix: Check local_options for existence 
https://jira.railsc.ru/browse/PC4-20727

* 2017-10-20 [80df413](../../commit/80df413) - __(Michail Merkushin)__ feat: Add later updates from update_sphinx_fields 
https://jira.railsc.ru/browse/PC4-20727

# v5.7.0

* 2017-09-15 [f7531ec](../../commit/f7531ec) - __(Mikhail Nelaev)__ fix: respect :as key in options 
https://jira.railsc.ru/browse/GOODS-696

* 2017-09-15 [27632e1](../../commit/27632e1) - __(Mikhail Nelaev)__ fix: :table_name key may be missing 
https://jira.railsc.ru/browse/GOODS-696

* 2017-09-08 [18aa4d7](../../commit/18aa4d7) - __(Mikhail Nelaev)__ feature: allow to join the same table more than once 
https://jira.railsc.ru/browse/GOODS-696

# v5.6.1

* 2017-08-10 [e953df6](../../commit/e953df6) - __(Andrew N. Shalaev)__ fix: parse database.yml config as erb 
https://jira.railsc.ru/browse/BPC-10871

# v5.6.0

* 2017-06-30 [5c34320](../../commit/5c34320) - __(Andrew N. Shalaev)__ feature: add hostname to notification message 
* 2017-06-07 [49430f3](../../commit/49430f3) - __(Artem Napolskih)__ chore: update drone config 
* 2017-06-06 [f09ff40](../../commit/f09ff40) - __(Artem Napolskih)__ chore: specs on rails 4.0 

# v5.5.0

* 2017-05-10 [59c4a6b](../../commit/59c4a6b) - __(Michail Merkushin)__ feat: Set riddle-2-1-0 as default version of protocol 
* 2017-05-10 [46ce6c8](../../commit/46ce6c8) - __(Michail Merkushin)__ feat: Add start args for searchd 
https://jira.railsc.ru/browse/PC4-19637

* 2017-05-04 [d1e0f26](../../commit/d1e0f26) - __(Nikolay Kondratyev)__ refactor(insert): удалён дублирующий riddle код 
https://github.com/pat/riddle/blob/0275b28949fdc56d7c1abc488bac28e4b8e322f9/lib/riddle/query/insert.rb#L51-L52

# v5.4.4

* 2017-05-03 [1f1065b](../../commit/1f1065b) - __(Michail Merkushin)__ fix: Mistype when log error 

# v5.4.3

* 2017-04-26 [fed8962](../../commit/fed8962) - __(TamarinEA)__ fix: update fields by ids when full reindex and ids present 
https://jira.railsc.ru/browse/BPC-10249

* 2017-04-19 [0a53cd6](../../commit/0a53cd6) - __(TamarinEA)__ fix: add max matches option to riddle query select 
https://jira.railsc.ru/browse/BPC-10212

# v5.4.2


# v5.4.1

* 2017-04-03 [62a3b69](../../commit/62a3b69) - __(Mikhail Nelaev)__ feature: autorelease 
* 2017-04-03 [349f715](../../commit/349f715) - __(Mikhail Nelaev)__ chore: drop ruby 1.9 and rails 3.1 support 
* 2017-03-15 [b3a3b20](../../commit/b3a3b20) - __(Mikhail Nelaev)__ fix: set indexing_mode for sphinx:rebuild 

# v5.4.0

* 2017-02-27 [62894f4](../../commit/62894f4) - __(Michail Merkushin)__ feature: Refactor logging. Notifications to Twinkle 
https://jira.railsc.ru/browse/PC4-19125

* 2017-03-06 [8cec7a6](../../commit/8cec7a6) - __(Michail Merkushin)__ chore: Update docker images 

# v5.3.2

* 2017-02-16 [6dca1c4](../../commit/6dca1c4) - __(Michail Merkushin)__ chore: Update drone testing 
* 2017-02-16 [06c8d89](../../commit/06c8d89) - __(Michail Merkushin)__ chore: Relax dependencies 

# v5.3.1

* 2016-10-29 [0ac278e](../../commit/0ac278e) - __(Artem Napolskih)__ feature: added matching to update query 
* 2016-10-28 [9a8e78f](../../commit/9a8e78f) - __(Artem Napolskih)__ feature: dip and dron added 

# v5.2.1

* 2016-07-22 [2ff5f9c](../../commit/2ff5f9c) - __(Semyon Pupkov)__ fix: allow to use stanalone rspec-rails 
Проблема: Если подлючен только rspec-rails то тут падает с ошибкой
```
bundler: failed to load command: rspec (/usr/local/gems/bin/rspec)
LoadError: cannot load such file -- rspec/version
```

Как работало раньше:
Обычно подключают 2 гема rspec и rspec-rails
Но это не совсем правильно так как достаточно одного rspec-rails

# v5.2.0

* 2016-07-06 [112a4b3](../../commit/112a4b3) - __(Michail Merkushin)__ feature: Use ssh_password in remote helper 

# v5.1.0

* 2016-06-14 [258622c](../../commit/258622c) - __(Michail Merkushin)__ feat: Copy config file in Local adapter 

# v5.0.1

* 2016-06-14 [a8a773a](../../commit/a8a773a) - __(Michail Merkushin)__ fix: Init helper with true hash 
Проблема в том, что в рейке `Rake::TaskArguments`, который не
поддерживает `#slice`

# v5.0.0

* 2016-05-31 [033761a](../../commit/033761a) - __(Michail Merkushin)__ feat: Run indexer with list of index names 
https://jira.railsc.ru/browse/PC4-17285

* 2016-05-31 [4381d3f](../../commit/4381d3f) - __(Michail Merkushin)__ chore: Drop support for original tasks 

# v4.3.0

* 2016-02-25 [0fd29f9](../../commit/0fd29f9) - __(Michail Merkushin)__ Find in batches with `where_not` 

# v4.2.1

* 2015-12-14 [874a01e](../../commit/874a01e) - __(Michail Merkushin)__ fix: change min request_store version to 1.2.1 

# v4.2.0

* 2015-12-10 [b5dbbb6](../../commit/b5dbbb6) - __(Michail Merkushin)__ feature: suspend and resume working nodes 
https://jira.railsc.ru/browse/PC4-16187

# v4.1.0

* 2015-11-30 [22b2e80](../../commit/22b2e80) - __(Michail Merkushin)__ feature: render common section. add sphinx.sql file 
https://jira.railsc.ru/browse/PC4-16134

# v4.0.3

* 2015-11-16 [d29ae4b](../../commit/d29ae4b) - __(Artem Napolskih)__ chore: relaxation of dependencies 

# v4.0.2

* 2015-10-27 [c3d68d5](../../commit/c3d68d5) - __(Michail Merkushin)__ fix: truncate right rt-partitions when indexing online 

# v4.0.1

* 2015-10-26 [46cfbc0](../../commit/46cfbc0) - __(Michail Merkushin)__ fix: autodetect sphinx 2.2.x 
* 2015-10-26 [8afb13b](../../commit/8afb13b) - __(Michail Merkushin)__ fix: favor mv instead of perl rename 
* 2015-10-26 [eab870f](../../commit/eab870f) - __(Michail Merkushin)__ fix: no care to stop sphinx when rebuilding 

# v4.0.0

* 2015-10-09 [8400c44](../../commit/8400c44) - __(Michail Merkushin)__ feature: rejection of master node. searchd connection pooling 

# v3.2.0

* 2015-09-29 [eae6141](../../commit/eae6141) - __(Michail Merkushin)__ feature: by default don't search in alternate indexes 
Now you can mark index as `alternate`

```ruby
define_index("name") do
  set_property alternate: true
end
```

And it will not available for search by default.
Without this feature all indexes available for search.

* 2015-09-29 [3ec988b](../../commit/3ec988b) - __(Michail Merkushin)__ fix: don't eager load models from all engines 

# v3.1.1

* 2015-09-28 [9fde84c](../../commit/9fde84c) - __(Simeon Movchan)__ fix: зависимость от net-ssh < 3.0 
net-ssh 3.0 тянется rye и требует ruby 2.0

# v3.1.0

* 2015-09-22 [ec3baef](../../commit/ec3baef) - __(Michail Merkushin)__ feature: configurable mysql connection timeouts 
* 2015-09-22 [07d726c](../../commit/07d726c) - __(Michail Merkushin)__ feature: configurable log level for log/sphinx.log 

# v3.0.1

* 2015-09-20 [22b34c3](../../commit/22b34c3) - __(Michail Merkushin)__ fix: misstypes in connection pool 

# v3.0.0

* 2015-09-16 [8ed6c38](../../commit/8ed6c38) - __(Michail Merkushin)__ feature: change connection pool log messages from error to info 
* 2015-09-07 [686b4a8](../../commit/686b4a8) - __(Michail Merkushin)__ feature: add persistent connections on master 
* 2015-08-16 [7642c75](../../commit/7642c75) - __(Michail Merkushin)__ feature: thread safe persistent connections (both) 

# v2.4.1

* 2015-08-26 [06aca71](../../commit/06aca71) - __(Semyon Pupkov)__ fix: remove extra read query 
https://jira.railsc.ru/browse/PC4-15436

# v2.4.0

* 2015-08-13 [a29751f](../../commit/a29751f) - __(Michail Merkushin)__ feature: better errors handling 

# v2.3.3

* 2015-08-26 [5dead51](../../commit/5dead51) - __(Semyon Pupkov)__ fix: remove extra read query 
https://jira.railsc.ru/browse/PC4-15436

# v2.3.2

* 2015-08-10 [b1e877f](../../commit/b1e877f) - __(bibendi)__ fix: dont sleep unless production 
* 2015-08-10 [f770236](../../commit/f770236) - __(bibendi)__ fix: use matching option only when reindex 
https://jira.railsc.ru/browse/PC4-15389

# v2.3.1

* 2015-08-10 [cd1e7bd](../../commit/cd1e7bd) - __(bibendi)__ fix: find in batches on steroids 
https://jira.railsc.ru/browse/PC4-15389

# v2.3.0

* 2015-07-29 [46eea6a](../../commit/46eea6a) - __(bibendi)__ feat: delete records from core after full index 
https://jira.railsc.ru/browse/PC4-15232

# v2.2.0

* 2015-07-15 [5ffd81c](../../commit/5ffd81c) - __(bibendi)__ fix: Transmitter.update_fields when full indexing 
By default Sphinx selects only 20 rows.
Therefor Transmitter updates not all rows when full reindex running.
This commit will fix this.
And adds new method ThinkingSphinx.find_in_batches.

https://jira.railsc.ru/browse/PC4-15139

# v2.1.2

* 2015-07-14 [9464676](../../commit/9464676) - __(Semyon Pupkov)__ fix: sphinx should load all indexes in index process 
Fix sphinx index process:

1. If models is located in subdirs (app/models/apress/demands/tender.rb)
thinking sphinx not load that models. See
https://github.com/pat/thinking-sphinx/blob/v2/lib/thinking_sphinx/context.rb#L54

2. Model not include index if model define indexes without extensions which call
define_indexes

Example:

``` ruby

class Tender
  define_index('tender') { ... }
end

Tender.sphinx_indexes #=> []

module TenderSphinxExtension
   included do
     define_indexes

     index = sphinx_indexes.find { |i| i.name == 'blog_post' }
     #...
   end
end

Tender.send(:include, TenderSphinxExtension)
Tender.sphinx_indexes #=> [ThinkingSphinx::Index]
```

And with this bugs helper can`t find rt_indexes for tender

# v2.1.1

* 2015-06-26 [8f8e003](../../commit/8f8e003) - __(Korotaev Danil)__ fix(initializer): always using postgresql database adapter 

# v2.1.0

* 2015-05-06 [0c49ff0](../../commit/0c49ff0) - __(Semyon Pupkov)__ Allow to skip indexes 

# v2.0.3

* 2015-04-08 [82c12ca](../../commit/82c12ca) - __(bibendi)__ Eager load application when generate config 

# v2.0.2

* 2015-03-12 [f59a5fb](../../commit/f59a5fb) - __(Semyon Pupkov)__ Add update_sphinx_fields for any activerecord model 

# v2.0.1

* 2015-02-27 [b16940b](../../commit/b16940b) - __(bibendi)__ remove apress-gems dep 
* 2015-02-27 [caa899c](../../commit/caa899c) - __(bibendi)__ fix rspec integration from version 3.0.0 

# v2.0.0

* 2015-02-09 [888dcd8](../../commit/888dcd8) - __(bibendi)__ feature(rt): remove delta_rt index 
PC4-14525

# v1.8.1

* 2014-12-29 [e16396b](../../commit/e16396b) - __(Michael Sogomonyan)__ chore(gem): rails 4.0 compatibility 
* 2014-12-29 [25f5e11](../../commit/25f5e11) - __(Michael Sogomonyan)__ chore(tasks): use apress-gems 

# v1.8.0

* 2014-10-01 [34199d8](../../commit/34199d8) - __(Artem Napolskih)__ feature(index/builder): add delete_fields and delete_withs features 

# v1.7.1

* 2014-09-22 [60db7c9](../../commit/60db7c9) - __(Artem Napolskih)__ feature(indexing): отказался от наследования от classy 

# v1.7.0

* 2014-09-18 [2893f08](../../commit/2893f08) - __(Artem Napolskih)__ feature(indexing): храним время завершения последней успешной индексации 

# v1.6.0

* 2014-09-16 [c425436](../../commit/c425436) - __(Artem Napolskih)__ feature(index/builder): add delete_attributes and delete_joins features 
* 2014-09-16 [cd478f0](../../commit/cd478f0) - __(Artem Napolskih)__ feature(all): added attribute ThinkingSphinx.indexing? 
True on rake task sphinx:conf. Can be used to separate requests for bulk indexing and normal operation with models.

# v1.5.0

* 2014-06-17 [39b9595](../../commit/39b9595) - __(Semyon Pupkov)__ Bump version to 1.5.0 
* 2014-06-17 [6b32310](../../commit/6b32310) - __(Semyon Pupkov)__ Add json attribute type 
PC4-13419

* 2014-06-17 [b9631f6](../../commit/b9631f6) - __(Semyon Pupkov)__ Fixed running tests 
* 2014-04-29 [f12e4e7](../../commit/f12e4e7) - __(Merkushin)__ fix rake release project name 

# v1.4.1

* 2014-04-29 [f17c606](../../commit/f17c606) - __(Merkushin)__ add gem release tasks 
* 2014-04-22 [d090662](../../commit/d090662) - __(Merkushin)__ bump version to 1.4.0 
* 2014-04-22 [bf0a7ea](../../commit/bf0a7ea) - __(Merkushin)__ better rspec integration 
* 2014-04-09 [cc223c9](../../commit/cc223c9) - __(Merkushin)__ bump version to 1.3.1 
* 2014-04-09 [f962cd9](../../commit/f962cd9) - __(Merkushin)__ fix(transmitter): boolean typecast 
* 2014-01-31 [3822bcf](../../commit/3822bcf) - __(Merkushin)__ version bump to 1.3.0 
* 2014-01-31 [8d55357](../../commit/8d55357) - __(Merkushin)__ feature(index): index_sp option 

# v1.2.3

* 2013-12-05 [ca277ef](../../commit/ca277ef) - __(Merkushin)__ version bump to 1.2.3 
* 2013-12-05 [fec95f5](../../commit/fec95f5) - __(Merkushin)__ fix(index) add all config options to rt indexes 
* 2013-10-24 [83c6a0b](../../commit/83c6a0b) - __(Merkushin)__ version bump to 1.2.2 
* 2013-10-24 [2243da5](../../commit/2243da5) - __(Merkushin)__ fix(mysql): обрежем время ответа для слейвов для отказоустойчивости 
* 2013-10-15 [ff9a0f9](../../commit/ff9a0f9) - __(Merkushin)__ version bump to 1.2.1 
* 2013-10-15 [28eb3c7](../../commit/28eb3c7) - __(Merkushin)__ fix(spec): helper now instance 
* 2013-10-11 [7325183](../../commit/7325183) - __(Merkushin)__ version bump to 1.2.0 
* 2013-10-11 [e0198f5](../../commit/e0198f5) - __(Merkushin)__ feature(chore) better bundled query logging 
* 2013-10-10 [5b35980](../../commit/5b35980) - __(Merkushin)__ version bump to 1.1.6 
* 2013-10-10 [5125049](../../commit/5125049) - __(Merkushin)__ fix full reindex, return to rsync 
* 2013-10-09 [7003698](../../commit/7003698) - __(Merkushin)__ version bump to 1.1.5 
* 2013-10-09 [4e05e20](../../commit/4e05e20) - __(Merkushin)__ fix full reindex 
* 2013-10-03 [6169833](../../commit/6169833) - __(Merkushin)__ version bump to 1.1.4 
* 2013-10-03 [3135082](../../commit/3135082) - __(Merkushin)__ remove threads 
* 2013-10-02 [1b91b5b](../../commit/1b91b5b) - __(Merkushin)__ ersion bump to 1.1.3 
* 2013-10-02 [bd21a92](../../commit/bd21a92) - __(Merkushin)__ fix(connection) synchronize agents pool 
* 2013-10-02 [21502f1](../../commit/21502f1) - __(Merkushin)__ connect to code climate 
* 2013-10-02 [dc5d625](../../commit/dc5d625) - __(Merkushin)__ version bump to 1.1.2 
* 2013-10-02 [3ab3e75](../../commit/3ab3e75) - __(Merkushin)__ fix broken tests in helper and transmitter 
* 2013-10-01 [2665ef9](../../commit/2665ef9) - __(Merkushin)__ update readme config 
* 2013-10-01 [50cdc4b](../../commit/50cdc4b) - __(Merkushin)__ chore(transmitter): refactor connection executes 
* 2013-09-30 [900c454](../../commit/900c454) - __(Merkushin)__ version bump to 1.1.0 
* 2013-09-30 [19c6abe](../../commit/19c6abe) - __(Merkushin)__ feature(transmitter): replase command direct on slaves 
* 2013-09-30 [584e5d3](../../commit/584e5d3) - __(Merkushin)__ version bump to 1.0.2 
* 2013-09-30 [f39c877](../../commit/f39c877) - __(Merkushin)__ fix(transmitter): many bugs when write to index 
* 2013-09-30 [66fc121](../../commit/66fc121) - __(Merkushin)__ version bump to 1.0.1 
* 2013-09-30 [fc4edde](../../commit/fc4edde) - __(Merkushin)__ feature(index): agent_query_timeout for master distributed 
* 2013-09-27 [007268c](../../commit/007268c) - __(Merkushin)__ version bump to 1.0.0 
* 2013-09-02 [e715b80](../../commit/e715b80) - __(Merkushin)__ feature shpinx replication 
* 2013-09-09 [0dad002](../../commit/0dad002) - __(Nikolay Kondratyev)__ Bump to 0.0.18 
* 2013-09-09 [6f81afe](../../commit/6f81afe) - __(Nikolay Kondratyev)__ fix(gemspec) Изменён спецификатор версии для гема mysql2 
* 2013-08-23 [aea2284](../../commit/aea2284) - __(Merkushin)__ version bump to 0.0.17 
* 2013-08-23 [ce54223](../../commit/ce54223) - __(Merkushin)__ fix(transmitter) type cast to multi 
* 2013-07-15 [ca52020](../../commit/ca52020) - __(Merkushin)__ version bump to 0.0.16 
* 2013-07-15 [b90887d](../../commit/b90887d) - __(Merkushin)__ updated to riddle min version 1.5.7 
* 2013-07-15 [a66b773](../../commit/a66b773) - __(Merkushin)__ version bump to 0.0.15 
* 2013-07-15 [a19506c](../../commit/a19506c) - __(Merkushin)__ index all name returns only distributed index 
* 2013-07-01 [d46d2e6](../../commit/d46d2e6) - __(Merkushin)__ version bump to 0.0.14 
* 2013-07-01 [46b7cfa](../../commit/46b7cfa) - __(Merkushin)__ fix(helper): учитывать при переносе из дельты, что объекта может не быть. Оптимизация удаления из дельты 
* 2013-06-20 [1ee5b4a](../../commit/1ee5b4a) - __(Merkushin)__ version bump to 0.0.13 
* 2013-06-20 [8af9ee2](../../commit/8af9ee2) - __(Sergey Fedorov)__ fix(helper) Fixed Errno::ENOENT in rake sphinx:rebuild 
* 2013-06-14 [76aab24](../../commit/76aab24) - __(Merkushin)__ bump version to 0.0.12 
* 2013-06-14 [2717041](../../commit/2717041) - __(Merkushin)__ fix Transmitter.update_all_fields when full reindex 
* 2013-06-11 [6049414](../../commit/6049414) - __(Merkushin)__ bump version to 0.0.11 
* 2013-06-11 [8b06b28](../../commit/8b06b28) - __(Merkushin)__ fix readme for with_sql on select 
* 2013-06-11 [e9732c6](../../commit/e9732c6) - __(Merkushin)__ refactor transmitted_sql to with_sql 
* 2013-06-11 [f1b5679](../../commit/f1b5679) - __(Merkushin)__ Index Bulder transmitted_sql 
* 2013-06-11 [0f0203b](../../commit/0f0203b) - __(Merkushin)__ bump version to 0.0.10 
* 2013-06-11 [98d1d66](../../commit/98d1d66) - __(Merkushin)__ fix helper prepare_rt 
* 2013-06-10 [3b77e65](../../commit/3b77e65) - __(Merkushin)__ bump version to 0.0.9 
* 2013-06-10 [200d146](../../commit/200d146) - __(Merkushin)__ add default charset type on rt index 
* 2013-06-10 [6085a05](../../commit/6085a05) - __(Merkushin)__ bump version to 0.0.8 
* 2013-06-10 [11fc571](../../commit/11fc571) - __(Merkushin)__ refactor Helper#rebuild 
* 2013-06-06 [a308113](../../commit/a308113) - __(Merkushin)__ bump version to 0.0.7 
* 2013-06-06 [0e6ea51](../../commit/0e6ea51) - __(Merkushin)__ fix misspell in helper#prepare_rt 
* 2013-06-06 [ea46f2a](../../commit/ea46f2a) - __(Merkushin)__ bump version to 0.0.6 
* 2013-06-06 [7f37bfb](../../commit/7f37bfb) - __(Merkushin)__ fix Railtie initializers order 
* 2013-04-28 [6c28b5c](../../commit/6c28b5c) - __(Merkushin)__ version bump to 0.0.5 
* 2013-04-28 [09c84c6](../../commit/09c84c6) - __(Merkushin)__ fix transmitter replace if no data 
* 2013-04-25 [93984ee](../../commit/93984ee) - __(Merkushin)__ version bump to 0.0.4 
* 2013-04-24 [c1659d9](../../commit/c1659d9) - __(Merkushin)__ update custom fields support 
* 2013-04-24 [ed80c89](../../commit/ed80c89) - __(Merkushin)__ rt_mem_limit index option 
* 2013-04-23 [5a3640f](../../commit/5a3640f) - __(Merkushin)__ version bump to 0.0.3 
* 2013-04-23 [2b3b63b](../../commit/2b3b63b) - __(Merkushin)__ refactor transmitter sends query 
* 2013-04-23 [843bf43](../../commit/843bf43) - __(Merkushin)__ fix after_commit callbacks 
* 2013-04-22 [f19524c](../../commit/f19524c) - __(Merkushin)__ version bump 0.0.2 
* 2013-04-22 [5c3646a](../../commit/5c3646a) - __(Merkushin)__ fix mutex attributes_types_map 
* 2013-04-22 [41276f9](../../commit/41276f9) - __(Merkushin)__ thread safe in TS:Index#attributes_types_map 
* 2013-04-22 [fb5feee](../../commit/fb5feee) - __(Merkushin)__ rt updates with typecasting 
* 2013-04-19 [8231d18](../../commit/8231d18) - __(Merkushin)__ index builder dsl 
* 2013-04-18 [3a38070](../../commit/3a38070) - __(Merkushin)__ readme and fixes 
* 2013-04-12 [91806b2](../../commit/91806b2) - __(Merkushin)__ indexation with truncate 
* 2013-04-12 [57ba0d0](../../commit/57ba0d0) - __(Merkushin)__ rt index multi support 
* 2013-04-12 [66b580a](../../commit/66b580a) - __(Merkushin)__ refactor namespaces 
* 2013-04-11 [92a9749](../../commit/92a9749) - __(Merkushin)__ fix rake tasks 
* 2013-04-10 [a640d46](../../commit/a640d46) - __(Merkushin)__ refactor transmitter callbacks 
* 2013-04-10 [4c9de04](../../commit/4c9de04) - __(Merkushin)__ index with rt attach 
* 2013-04-06 [f332430](../../commit/f332430) - __(Merkushin)__ transmitter specs 
* 2013-04-06 [fd0705e](../../commit/fd0705e) - __(bibendi)__ refactor names and paths 
* 2013-03-21 [51fba5e](../../commit/51fba5e) - __(Merkushin)__ ranged query fixes fixes 
* 2013-03-12 [aa43f84](../../commit/aa43f84) - __(Merkushin)__ add sphinx yml sample 
* 2013-03-12 [5a501a6](../../commit/5a501a6) - __(Merkushin)__ source specs 
* 2013-03-12 [3c6f899](../../commit/3c6f899) - __(Merkushin)__ refactor spec, finish specs for active_record 
* 2013-03-12 [8ae6cd9](../../commit/8ae6cd9) - __(Merkushin)__ activerecord specs 
* 2013-03-12 [b58f411](../../commit/b58f411) - __(Merkushin)__ remove delta support 
* 2013-03-12 [e71b007](../../commit/e71b007) - __(Merkushin)__ fix database.yml.sample 
* 2013-03-12 [76110c4](../../commit/76110c4) - __(Merkushin)__ gemspec fixes 
* 2013-03-10 [c8e9fd3](../../commit/c8e9fd3) - __(bibendi)__ index specs 
* 2013-03-10 [186a093](../../commit/186a093) - __(bibendi)__ attribute specs 
* 2013-03-10 [41b3178](../../commit/41b3178) - __(bibendi)__ source sql specs 
* 2013-03-09 [63d0340](../../commit/63d0340) - __(bibendi)__ initial 
* 2013-03-09 [299218c](../../commit/299218c) - __(bibendi)__ first commit 
