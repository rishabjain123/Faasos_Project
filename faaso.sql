-- table driver
drop table if exists driver;
create table driver(driver_id int, reg_date date);
insert into faaso.driver(driver_id,reg_date)
values(1,'2021-01-01'),(2,'2021-01-03'),(3,'2021-01-08'),(4,'2021-01-15');
select * from driver;

-- table ingredients
drop table if exists ingredients;
create table ingredients(ingredients_id int, ingredients_name varchar(60));
insert into ingredients(ingredients_id,ingredients_name)
values(1,'BBQ Chicken'),(2,'Chilli Sauce'),(3,'Chicken'),
(4,'Cheese'),(5,'Kebab'),(6,'Mushrooms'),(7,'Onions'),
(8,'Eggs'),(9,'Shewwan Sauce'),(10,'Tomato'),(11,'Tomato Sauce');
select *from ingredients;

-- table rolls
drop table if exists rolls;
create table rolls(roll_id int, roll_name varchar(60));
insert into rolls(roll_id, roll_name)
values(1,'non veg roll'),(2,'veg roll');
select * from rolls;

-- table rolls reciepes
drop table if exists rolls_reciepes;
create table rolls_recipes(roll_id int, ingredients varchar(24));
insert into rolls_recipes(roll_id, ingredients)
values(1,'1,2,3,4,5,6,8,10'),(2,'4,6,7,9,11,12');
select *from rolls_recipes;

-- table driver orders
drop table if exists driver_order;
create table driver_order(order_id int, driver_id int, pickup_time datetime, 
distance varchar(7), duration varchar(10), cancellation varchar(24));
insert into driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation)
values(1,1,'2021-01-01 18:15:34','20km','32 minutes',''),
(2,1,'2021-01-01 19:10:54','20km','27 minutes',''),
(3,1,'2021-01-03 00:12:37','13.4km','20 mins','NaN'),
(4,2,'2021-01-04 13:53:03','23.4','40','NaN'),
(5,3,'2021-01-08 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'2020-01-08 21:30:45','25km','25mins',null),
(8,2,'2020-01-10 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'2020-01-11 18:50:20','10km','10minutes',null);
select *from driver_order;

-- table customer orders
drop table if exists customer_orders;
create table customer_order(order_id int, customer_id int, roll_id int, not_include_items varchar(4),
extra_items_include varchar(4), order_date datetime);
insert into customer_order(order_id, customer_id, roll_id, not_include_items,
extra_items_include, order_date)
values (1,101,1,'','','2021-01-01  18:05:02'),
(2,101,1,'','','2021-01-01 19:00:52'),
(3,102,1,'','','2021-01-02 23:51:23'),
(3,102,2,'','NaN','2021-01-02 23:51:23'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,2,'4','','2021-01-04 13:23:46'),
(5,104,1,null,'1','2021-01-08 21:00:29'),
(6,101,2,null,null,'2021-01-08 21:03:13'),
(7,105,2,null,'1','2021-01-08 21:20:29'),
(8,102,1,null,null,'2021-01-09 23:54:33'),
(9,103,1,'4','1,5','2021-01-10 11:22:59'),
(10,104,1,null,null,'2021-01-10 18:34:49'),
(10,104,1,'2,6','1,4','2021-01-11 18:34:49');
select * from customer_order;

-- how many rolls were ordered?
select round(count(roll_id)/2,0) as total_rolls_ordered from customer_order;

-- how many unique customer orders were made?
select  count(distinct(customer_id)) as total_customers_ordered from customer_order;

-- how many successful orders delivered
select driver_id, count(distinct (order_id)) as total_orders_delivered from driver_order 
where cancellation != 'cancellation' 
and cancellation != 'customer cancellation' group by driver_id;

-- data cleaned by deleting null value & no. of each roll successfuly delivered
select roll_id, count(roll_id)/2 from customer_order where order_id in
(select order_id from
(select *, case when cancellation = 'cancellation' or cancellation = 'customer cancellation'
then 'c' else 'nc' end as order_cancel_details from driver_order) a
where order_cancel_details = 'nc')  group by roll_id;

-- how many veg and nonveg rolls were ordered by each customer?
select customer_id, count(roll_type)/2 as nonveg from 
(select customer_id, case when roll_id = 1 then 'nonveg' else 'veg' end as roll_type from customer_order) a
where roll_type = 'nonveg' group by customer_id;
-- OR
select a.*,b.roll_name from 
(select customer_id, roll_id, count(roll_id)/2 as cnt from customer_order 
group by customer_id,roll_id) a inner join rolls b on a.roll_id = b.roll_id;

-- what was the maximum no. of rolls delivered in a single order?
select *, rank() over(order by cnt desc) rnk from(
select order_id, count(roll_id)/2 cnt from(
select * from customer_order where order_id in(
select order_id from
(select *, case when cancellation = 'cancellation' or cancellation = 'customer cancellation'
then 'c' else 'nc' end as order_cancel_details from driver_order) a
where order_cancel_details = 'nc')) b group by order_id
) c; 

-- for each customer, how many delivered rolls had at least 1 change and how many had no change?
with temp_customer_order (order_id, customer_id, roll_id, new_not_include_items,
new_extra_items_include, order_date) as 
(
select order_id,customer_id,roll_id, 
case when not_include_items is null or not_include_items = ''
then '0' else not_include_items end as new_not_include_item,
case when extra_items_include is null or extra_items_include  = 'Nan' or extra_items_include =''
then '0' else extra_items_include end as new_extra_items_include,
order_date from customer_order)
, 
temp_driver_order(order_id,driver_id,pickup_time,distance,duration,new_cancellation) as
(
select order_id,driver_id,pickup_time,distance,duration,
case when cancellation is null or cancellation = 'NaN' then '0' else '1' end as new_cancellation
from driver_order)
select *, case when new_not_include_items = '0' and new_extra_items_include = '0'
then 'no change' else 'change' end as change_nochange
from temp_customer_order where order_id in(
select order_id from temp_driver_order where new_cancellation = 0);

--  what was the total number of rolls ordered for each hour of the day?
select hours_between, count(hours_between) from
(select *, concat(convert(hour(order_date),char) , '-',
convert(hour(order_date)+1,char)) as hours_between from customer_order) a
group by hours_between;

-- what was the number of orders for each day of the week?
select day, count(distinct order_id) from
(select *, dayname(order_date) as day from customer_order) a
group by day;

-- what was the average time in minutes it took for each driver to arrive at the fasoos hq to pickup order?
select avg(timestampdiff(minute,a.order_date,a.pickup_time)) as diff from
(select d.order_id, c.order_date, d.pickup_time
from driver_order d 
left join customer_order c on d.order_id = c.order_id where d.pickup_time is not null limit 5) as a;





