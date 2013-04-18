# Sphinx::Integration

Надор надстроек над ThinkingSphinx и Riddle

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

Если у модели существую MVA атрибуты, которые наполняются отдельными запросами (ranged-query), то необходимо определить методы,
которые будут возвращать их значения при сохранении модели. Существую определённые правила именования таких методов.
Метод должен начинаться с mva_sphinx_attributes_for_NAME, например:
```ruby
def mva_sphinx_attributes_for_rubrics
  {:rubrics => rubrics.map(&:rubric_id)}
end
```

## Дополнительные возможности конфигурировани индекса

Предполагается, что весь код в примерах будет выполнятся в блоке `define_index('model') do ... end`

### Наполнение определённого индекса из другой базы, например со слэйва

Реквизиты базы из ключа {production}_slave
```ruby
set_property :use_slave_db => true
```

Реквизиты базы из ключа {production}_my-sphinx-slave
```ruby
set_property :use_slave_db => 'my-sphinx-slave'
```

### Common Table Expressions or CTEs
```ruby
set_property :source_cte => {
  :_rubrics => <<-SQL,
    select companies.id as company_id, array_agg(company_rubrics.rubric_id) as rubrics_array
    from companies
    inner join company_rubrics on company_rubrics.company_id = companies.id
    where {{where}}
    group by companies.id
  SQL
}
```

Условие {{where}} будет заменено на нужное из основного запроса

### Дополнительные joins, например с заданым CTE
```ruby
set_property :source_joins => {
  :_rubrics => {
    :as => :_rubrics,
    :type => :left,
    :on => '_rubrics.company_id = companies.id'
}
```

### Отключение группировки GROUP BY, которая делается по-умолчанию
```ruby
set_property :source_no_grouping => true
```

### Указание LIMIT
```ruby
set_property :sql_query_limit => 1000
```

### Отключение индексации пачками
```ruby
set_property :disable_range => true
```

### Указание своих минимального и максимального предела индексации
```ruby
set_property :sql_query_range => "SELECT 1::int, COALESCE(MAX(id), 1::int) FROM rubrics"
```

### Указание набора условий для выборки из базы
```ruby
set_property :use_own_sql_query_range => true
where %[faq_posts.id in (select faq_post_id from faq_post_deltas where ("faq_post_deltas"."id" >= $start AND "faq_post_deltas"."id" <= $end))]
```

### Указание полей при группировке
```ruby
set_property :force_group_by => true
group_by 'search_hints.forms.id', 'search_hints.forms.value',
```

### Указание произвольного названия таблицы, например вьюшки
```ruby
set_property :source_table => 'prepared_table_view'
```

### Наполнение MVA атрибутов из произволного запроса
```ruby
has :regions, :type => :multi, :source => :ranged_query, :query => "SELECT {{product_id}} AS id, region_id AS regions FROM product_regions WHERE id>=$start AND id<=$end; SELECT MIN(id), MAX(id) FROM product_regions"
```
В данно случае `{{product_id}}` заменится на нечто подобное `product_id * 8::INT8 + 5 AS id`, т.е. заменится на вычисление правильного внутреннего сквозного id

