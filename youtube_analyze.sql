--создаём таблицы и импортируем в них csv с данными по статистике и комментариям к видео на Youtube. Нам нужно проанализировать их.
create table public.youtube_video_stats (
                                            title text,
                                            video_id text,
                                            published_at text,
                                            keyword text,
                                            likes numeric,
                                            comments numeric,
                                            views numeric
);

create table public.youtube_video_comments (
                                               video_id text,
                                               comment text,
                                               likes numeric,
                                               sentiment float
);

--1) Какие видео самые комментируемые или самые просматриваемые?
--Возьмём топ-10
select *
from public.youtube_video_stats yvs
where yvs.comments is not null
order by yvs.comments desc
limit 10;

select *
from public.youtube_video_stats yvs
where yvs.views is not null
order by yvs.views desc
limit 10;

--Теперь проверим, какие из них совпадают. Получим 5.
select a.*
from (select *
      from public.youtube_video_stats yvs
      where yvs.comments is not null
      order by yvs.comments desc
      limit 10) a
         join (select *
               from public.youtube_video_stats yvs
               where yvs.views is not null
               order by yvs.views desc
               limit 10) b
              using (video_id);

--2) Сколько всего просмотров имеет каждая категория? Сколько лайков имеет каждая категория?
--примем keyword за категорию
select keyword, sum(views)
from public.youtube_video_stats yvs
group by 1
order by 2 desc; -- самые просматриваемые видео - с тэгами google, animals, mrbeast, music

select keyword, sum(likes)
from public.youtube_video_stats yvs
group by 1
order by 2 desc; --видим совпадение по категориям google, animals, mrbeast

--3) комменты, у которых больше всего лайков
select comment, sum(likes)
from public.youtube_video_comments
group by 1
order by 2 desc; --делаем вывод, что больше всего лайков получает тот коммент, где происходит какое-то мотивирующее обращение к читателям.
--например, им обещают выигрыш за подписку.

--пора усложнить задачи :)
--4) Рассчитаем рейтинг просмотр-лайк для каждого видео, а также для каждой категории
--сделать это можно, например, вот так
with a as (
    select yvs.*, round((likes / views)*100, 2) as like_view_ranking
    from public.youtube_video_stats yvs)
select a.*, round(avg(like_view_ranking) over (partition by a.keyword), 2) as like_view_by_kwd_ranking
from public.youtube_video_stats yvs1
         join a
              using (video_id);
--можно исследовать закономерности и, например, выяснить, что криптовалюта - лидер по данному рейтингу.
--5) Кто более упоминаемый в комментах - Apple или Samsung. Какова временная динамика?
select count(*) filter ( where lower(comment) ilike '%apple%') as apple_cnt,
       count(*) filter ( where lower(comment) ilike '%samsung%' ) as samsung_cnt
from public.youtube_video_comments; --получили 213 упомнаний apple и 20 упоминаний samsung

--чтобы ответить на вопрос временной динамики, нужна вторая таблица, так как таблица с комментами лишена дат

select *
from (
select distinct yvs.published_at,
       count(*) filter ( where lower(yvc.comment) ilike '%apple%') as apple_cnt,
       count(*) filter ( where lower(yvc.comment) ilike '%samsung%' ) as samsung_cnt
from public.youtube_video_comments yvc
join public.youtube_video_stats yvs on yvc.video_id = yvs.video_id
group by 1) a
where greatest(a.apple_cnt, a.samsung_cnt) > 0;
--можно определить, когда Apple и Samsung обсуждались активнее всего, коррелируют ли они друг с другом
--а затем посмотреть конкретные комменты за конкретные даты и понять, с чем связана активизация упоминаний

--расширим функционал решения по заданию №4, добавив также расчёт рейтинга обсуждаемости (кол-во комментариев / кол-во просмотров)
--сделаем отчёт с датами, категориями и метриками по видео
with a as (
        select yvs.*, round((likes / views)*100, 2) as like_view_ranking,
               round((comments / views)*100, 2) as comment_view_ranking
        from public.youtube_video_stats yvs),
    b as (
        select a.published_at, a.video_id, a.keyword,
               round(avg(like_view_ranking) over (partition by a.keyword), 2) as like_view_by_kwd_ranking,
               round(avg(comment_view_ranking) over (partition by a.keyword), 2) as comment_view_by_kwd_ranking
        from public.youtube_video_stats yvs1
        join a
        using (video_id))
select a.published_at, a.video_id, a.keyword,b.comment_view_by_kwd_ranking, b.like_view_by_kwd_ranking,
       (b.comment_view_by_kwd_ranking - a.comment_view_ranking) as cv_difference,
       (b.like_view_by_kwd_ranking - a.like_view_ranking) as lv_difference
from a
join b using (video_id)
order by 1;
--здесь мы не только получим усредненные рейтинги по категориям, но также и разиницу с рейтингом по каждому видео
--из этого можно вывести разные наблюдения и закономерности - например, имеет ли эта разница выраженную сезонность
--или же насколько велика дельта по тем или иным категориям
--на основании этих данных можно с исчерпывающей точностью говорить о том, какие видео являются более популярными
--можно даже делать предсказания, будет ли видео по той или иной теме, выложенное в то или иное время, популярно или нет--пора усложнить задачи :)
--4) Рассчитаем рейтинг просмотр-лайк для каждого видео, а также для каждой категории
--сделать это можно, например, вот так
with a as (
    select yvs.*, round((likes / views)*100, 2) as like_view_ranking
    from public.youtube_video_stats yvs)
select a.*, round(avg(like_view_ranking) over (partition by a.keyword), 2) as like_view_by_kwd_ranking
from public.youtube_video_stats yvs1
         join a
              using (video_id);
--можно исследовать закономерности и, например, выяснить, что криптовалюта - лидер по данному рейтингу.
--5) Кто более упоминаемый в комментах - Apple или Samsung. Какова временная динамика?
select count(*) filter ( where lower(comment) ilike '%apple%') as apple_cnt,
       count(*) filter ( where lower(comment) ilike '%samsung%' ) as samsung_cnt
from public.youtube_video_comments; --получили 213 упомнаний apple и 20 упоминаний samsung

--чтобы ответить на вопрос временной динамики, нужна вторая таблица, так как таблица с комментами лишена дат

select *
from (
select distinct yvs.published_at,
       count(*) filter ( where lower(yvc.comment) ilike '%apple%') as apple_cnt,
       count(*) filter ( where lower(yvc.comment) ilike '%samsung%' ) as samsung_cnt
from public.youtube_video_comments yvc
join public.youtube_video_stats yvs on yvc.video_id = yvs.video_id
group by 1) a
where greatest(a.apple_cnt, a.samsung_cnt) > 0;
--можно определить, когда Apple и Samsung обсуждались активнее всего, коррелируют ли они друг с другом
--а затем посмотреть конкретные комменты за конкретные даты и понять, с чем связана активизация упоминаний

--расширим функционал решения по заданию №4, добавив также расчёт рейтинга обсуждаемости (кол-во комментариев / кол-во просмотров)
--сделаем отчёт с датами, категориями и метриками по видео
with a as (
        select yvs.*, round((likes / views)*100, 2) as like_view_ranking,
               round((comments / views)*100, 2) as comment_view_ranking
        from public.youtube_video_stats yvs),
    b as (
        select a.published_at, a.video_id, a.keyword,
               round(avg(like_view_ranking) over (partition by a.keyword), 2) as like_view_by_kwd_ranking,
               round(avg(comment_view_ranking) over (partition by a.keyword), 2) as comment_view_by_kwd_ranking
        from public.youtube_video_stats yvs1
        join a
        using (video_id))
select a.published_at, a.video_id, a.keyword,b.comment_view_by_kwd_ranking, b.like_view_by_kwd_ranking,
       (b.comment_view_by_kwd_ranking - a.comment_view_ranking) as cv_difference,
       (b.like_view_by_kwd_ranking - a.like_view_ranking) as lv_difference
from a
join b using (video_id)
order by 1;
--здесь мы не только получим усредненные рейтинги по категориям, но также и разиницу с рейтингом по каждому видео
--из этого можно вывести разные наблюдения и закономерности - например, имеет ли эта разница выраженную сезонность
--или же насколько велика дельта по тем или иным категориям
--на основании этих данных можно с исчерпывающей точностью говорить о том, какие видео являются более популярными
--можно даже делать предсказания, будет ли видео по той или иной теме, выложенное в то или иное время, популярно или нет
