# Sphinx::Integration

Набор надстроек над ThinkingSphinx и Riddle

Гем служит для использования real time индексов, а также для более хитрого написания sql запросов при описании индекса.

# Возможности:

## Запуск сфинкса и индексатора

Всё стандартно, как и в thinking sphinx, т.к. все его rake таски перекрыты

+ rake ts:conf
+ rake ts:start
+ rake ts:stop
+ rake ts:in
+ rake ts:rebuild

*Внимание* при офлайн индексации rt индексы не очищаются. Рекоммендуется в этом случае использовать ts:rebuild

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

