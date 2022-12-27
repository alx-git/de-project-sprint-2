drop table if exists public.shipping_status;
create table public.shipping_status (
  shippingid bigint primary key,
  status text,
  state text,
  shipping_start_fact_datetime timestamp,
  shipping_end_fact_datetime timestamp
);
insert into public.shipping_status (
    shippingid, status, state, shipping_start_fact_datetime, shipping_end_fact_datetime)
with shipping_temp as (
select shippingid, max(state_datetime) as state_datetime
from public.shipping
group by shippingid)
select shipping_temp.shippingid, status, state, shipping_start_fact_datetime, shipping_end_fact_datetime
from shipping_temp
left join public.shipping
on shipping_temp.shippingid = shipping.shippingid
and shipping_temp.state_datetime = shipping.state_datetime
left join 
(select shippingid, max(state_datetime) as shipping_start_fact_datetime
 from public.shipping
 where state = 'booked'
 group by shippingid) as shipping_booked
on shipping_temp.shippingid = shipping_booked.shippingid
left join 
(select shippingid, max(state_datetime) as shipping_end_fact_datetime
 from public.shipping
 where state = 'recieved'
 group by shippingid) as shipping_recieved
on shipping_temp.shippingid = shipping_recieved.shippingid
order by shipping_temp.shippingid;