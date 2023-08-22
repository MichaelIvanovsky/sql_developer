
SELECT ('[
  {
    "name": "batman"
  },
  {
    "name": "superman"
  }
]'::jsonb)[0] -> 'name';
-- -> и ->> - основные инструменты работы с json, первая возвращает объект, а вторая - текст.
SELECT ('[
  {
    "name": "batman"
  },
  {
    "name": "superman"
  }
]'::jsonb)[0] -> 'name';
-- вернёт "batman", а ->> - просто batman
-- Но помимо них есть и ещё операторы.
-- @> проверяет, есть ли один объект в другом
select '{
  "name": "Alice",
  "agent": {
    "bot": true
  }
}'::jsonb @> '{"agent": {"bot": false}}'; -- получим false
select '{
  "name": "Alice",
  "agent": {
    "bot": true
  }
}'::jsonb @> '{"agent": {"bot": true}}';
-- получим true
--обратим внимание, что @> означает, что объект json начинается с того объекта, который мы задаём правее. А можно сделать <@ - и тогда, наоборот, проверяться будет совпадение с конца.
--? - проверяет, существует ли строка
select '{
  "name": "Alice",
  "agent": {
    "bot": true
  }
}'::jsonb -> 'agent' ? 'bot';

--существуют функции для работы с json. jsonb_each - записывает строку ключ-значение
select jsonb_each('{
  "name": "Alice",
  "agent": {
    "bot": true
  }
}'::jsonb);
--jsonb_object_keys - выводит все ключи
select jsonb_object_keys('{
  "name": "Alice",
  "agent": {
    "bot": true
  }
}'::jsonb);

SELECT ('[
  {
    "name": "batman"
  },
  {
    "name": "superman"
  }
]'::jsonb) ->> 'name';

--операторы сравнения. SELECT * FROM json_test WHERE data ?| array['a', 'b'] - здесь ?| говорит: найди нам объекты, имеющие любой ключ - a или b
-- SELECT * FROM json_test WHERE data ?& array['a', 'b']; - а если вот так, то тогда мы получим только объекты, имеющие и ключ a, и ключ b
