# Sphinx::Integration [![Code Climate](https://codeclimate.com/repos/51fb821789af7e473903447a/badges/ce24bf62ba430b5cc871/gpa.png)](https://codeclimate.com/repos/51fb821789af7e473903447a/feed)

Набор надстроек и манкипатчинга над ThinkingSphinx и Riddle
Код гема не претендует на красоту, т.к. манки от слова обезьяна =)

Возможности:
+ real time индексы
+ продвинутые sql запросы при описании индекса
+ репликация

# Возможности:

## Rake tasks
Если в параметрах не передавать node, то по умолчанию комманда будет выполнена на всех нодах

rake sphinx:start[node]
rake sphinx:stop[node]
rake sphinx:restart[node]
rake sphinx:index[node,offline]
rake sphinx:rebuild[node]
rake sphinx:conf
rake sphinx:copy_conf[node]
rake sphinx:rm_indexes[node]
rake sphinx:rm_binlog[node]

*Внимание* при офлайн индексации rt индексы не очищаются. Рекоммендуется в этом случае использовать rebuild

## config/sphinx.yml

### development

```yml
development:
  remote: false

  address: localhost
  port: 10300
  mysql41: 9300
  listen_all_interfaces: true

  max_matches: 5000
  version: 2.0.3
  mem_limit: 512M
  write_buffer: 4M
  attr_flush_period: 900
  mva_updates_pool: 768M
  rt_mem_limit: 2048M
  read_buffer: 1M
  workers: threads
  dist_threads: 2
  binlog_max_log_size: 1024M
  rt_flush_period: 86400
```

### production

```yml
production:
  remote: true

  address: index
  port: 10300
  mysql41: 9300
  listen_all_interfaces: true

  max_matches: 5000
  version: 2.0.3
  mem_limit: 512M
  write_buffer: 4M
  attr_flush_period: 900
  mva_updates_pool: 768M
  rt_mem_limit: 2048M
  read_buffer: 1M
  workers: threads
  dist_threads: 2
  binlog_max_log_size: 1024M
  rt_flush_period: 86400

  user: sphinx
  remote_path: /home/index
  query_log_file: /dev/null
  searchd_log_file: logs/searchd.log
  pid_file: pid/searchd.pid
  searchd_file_path: data
  binlog_path: binlog
```

### production with replication

```yml
production:
  remote: true
  replication: true

  address: index
  port: 10300
  mysql41: 9300
  listen_all_interfaces: false

  max_matches: 5000
  version: 2.0.3
  mem_limit: 512M
  write_buffer: 4M
  attr_flush_period: 900
  mva_updates_pool: 768M
  rt_mem_limit: 2048M
  read_buffer: 1M
  workers: threads
  dist_threads: 2
  binlog_max_log_size: 1024M
  rt_flush_period: 86400
  agent_connect_timeout: 50
  ha_strategy: nodeads

  user: sphinx
  remote_path: /home/index/master
  query_log_file: /dev/null
  searchd_log_file: logs/searchd.log
  pid_file: pid/searchd.pid
  searchd_file_path: data
  binlog_path: binlog

  agents:
    slave1:
      address: index
      port: 10301
      mysql41: 9301
      listen_all_interfaces: true
      remote_path: /home/index/slave
    slave2:
      address: index2
      port: 10302
      mysql41: 9302
      listen_all_interfaces: true
      remote_path: /home/index/slave
```


## Поддержка RT индексов
```ruby
define_index('model') do
  set_property :rt => true
end
```

RT индексы используются как дельта. Таким образом мы избежим существенного замедления поисковых запросов из-за фрагментации памяти
т.к. основная часть запросов будет как и раньше обслуживаться дисковым индексом

Workflow:
+ первоначальная индексация, все данные попадают в дисковый core индекс
+ далее при обновлении записи, она попадает в rt индекс
+ и помечается в core как удалённая

Когда запускается очередная полная индексация:
+ начинает наполнятся core индекс сфинксовым индексатором
+ но в этот момент данные могут обновляться, записываться в rt индекс они будут, но потом всё равно удаляться после завершения полной индексации
+ для того, чтобы не потерять обновления данные начинают попадать в дополнительный delta_rt индекс
+ после завершения полной индексации, очищается основной rt индекс
+ и в него перетекают данные из delta rt индекса

## Дополнительные возможности конфигурировани индекса

Предполагается, что весь код в примерах будет выполнятся в блоке `define_index('model') do ... end`

### Значения для MVA атрибутов при записи
Если у модели существую MVA атрибуты, которые наполняются отдельными запросами (ranged-query), то необходимо определить блоки,
которые будут возвращать их значения при сохранении модели.
```ruby
mva_attribute :rubrics do |product|
  product.rubrics.map(&:rubric_id)
end
```

### Изменение sql запроса, получающего атрибуты из базы
При массовой индексации и обновлении записи
```ruby
with_sql :on => :select do |sql|
  sql.sub(" AND products.state != 'deleted'", '')
end

При обновлении записи
```ruby
with_sql :on => :update do |sql|
  sql.sub(" AND products.state != 'deleted'", '')
end
```

### Наполнение определённого индекса из другой базы, например со слэйва

Реквизиты базы из ключа {production}_slave
```ruby
slave(true)
```

Реквизиты базы из ключа {production}_my-sphinx-slave
```ruby
slave('my-sphinx-slave')
```

### Common Table Expressions or CTEs
```ruby
with(:_rubrics) do
  <<-SQL,
    select companies.id as company_id, array_agg(company_rubrics.rubric_id) as rubrics_array
    from companies
    inner join company_rubrics on company_rubrics.company_id = companies.id
    where {{where}}
    group by companies.id
  SQL
end
```

Условие {{where}} будет заменено на нужное из основного запроса

### Дополнительные joins, например с заданым CTE
```ruby
left_join(:_rubrics).on('_rubrics.company_id = companies.id')

left_join(:long_table_name => :alias).on('alias.company_id = companies.id')

inner_join(:long_table_name).as(:alias).on(...)
```

### Отключение группировки GROUP BY, которая делается по-умолчанию
```ruby
no_grouping
```

### Указание LIMIT
```ruby
limit(1000)
```

### Отключение индексации пачками
```ruby
disable_range
```

### Указание своих минимального и максимального предела индексации
```ruby
query_range("SELECT 1::int, COALESCE(MAX(id), 1::int) FROM rubrics")
```

### Отключение подстановок в WHERE $start >= ? and $end <= ?
```ruby
use_own_sql_query_range
```

### Отменяет группировку по-умолчанию
```ruby
force_group_by
```

### Указание произвольного названия таблицы, например вьюшки
```ruby
from('prepared_table_view')
```

### Наполнение MVA атрибутов из произволного запроса
```ruby
has :regions, :type => :multi, :source => :ranged_query, :query => "SELECT {{product_id}} AS id, region_id AS regions FROM product_regions WHERE id>=$start AND id<=$end; SELECT MIN(id), MAX(id) FROM product_regions"
```
В данно случае `{{product_id}}` заменится на нечто подобное `product_id * 8::INT8 + 5 AS id`, т.е. заменится на вычисление правильного внутреннего сквозного id

### Разделение запросов для массовой индексации и обычной работы с моделями
```ruby
module IndexExtension
  def self.included(model)
    return unless ThinkingSphinx.indexing?

    model.class_eval do
      define_indexes

      index = sphinx_indexes.select { |i| i.name == 'product' }.first
      return unless index

      ThinkingSphinx::Index::Builder.new(index) do
        # change bulk indexing query this

        delete_joins(:product_images)
        delete_attributes(:has_image)
        has 'CASE WHEN product_denormalizations.images_count > 0 THEN 0 ELSE 1 END',
            :as => :has_image,
            :type => :integer
      end
    end
  end
end
```