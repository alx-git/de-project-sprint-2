drop table if exists public.shipping_country_rates;
create table public.shipping_country_rates (
  shipping_country_id serial primary key,
  shipping_country text,
  shipping_country_base_rate numeric(14,3)  
);
insert into public.shipping_country_rates (shipping_country, shipping_country_base_rate)
select distinct shipping_country, shipping_country_base_rate from public.shipping;


drop table if exists public.shipping_agreement;
create table public.shipping_agreement (
  agreementid bigint primary key,
  agreement_number text,
  agreement_rate numeric(14,2),
  agreement_commission numeric(14,2)
);
insert into public.shipping_agreement (
    agreementid, agreement_number, agreement_rate, agreement_commission
)
select 
cast(vendor_attributes[1] as bigint) as agreementid,
vendor_attributes[2],
cast(vendor_attributes[3] as numeric(14,2)),
cast(vendor_attributes[4] as numeric(14,2)) from
(select distinct regexp_split_to_array(vendor_agreement_description, ':+') as vendor_attributes
from public.shipping) as foo
order by agreementid;


drop table if exists public.shipping_transfer;
create table public.shipping_transfer (
  transfer_type_id serial primary key,
  transfer_type text,
  transfer_model text,
  shipping_transfer_rate numeric(14,3)
);
insert into public.shipping_transfer (transfer_type, transfer_model, shipping_transfer_rate)
select distinct 
shipping_transfer_attributes[1],
shipping_transfer_attributes[2],
shipping_transfer_rate
from 
(select 
regexp_split_to_array(shipping_transfer_description, ':+') as shipping_transfer_attributes,
shipping_transfer_rate
from
public.shipping) as foo;


drop table if exists public.shipping_info;
create table public.shipping_info (
  shippingid bigint primary key,
  vendorid bigint,
  payment_amount numeric(14,2),
  shipping_plan_datetime timestamp,
  transfer_type_id bigint,
  shipping_country_id bigint,
  agreementid bigint,
  foreign key (transfer_type_id) references shipping_transfer(transfer_type_id) ON UPDATE cascade,
  foreign key (shipping_country_id) references shipping_country_rates(shipping_country_id) ON UPDATE cascade,
  foreign key (agreementid) references shipping_agreement(agreementid) ON UPDATE cascade
);
insert into public.shipping_info (
    shippingid, vendorid, payment_amount, shipping_plan_datetime,
    transfer_type_id, shipping_country_id, agreementid
)
select distinct shippingid, vendorid, payment_amount, shipping_plan_datetime,
transfer_type_id, shipping_country_id, agreementid
from public.shipping
left join public.shipping_transfer
on shipping_transfer_description = transfer_type || ':' || transfer_model
left join public.shipping_country_rates
on shipping.shipping_country = shipping_country_rates.shipping_country
left join public.shipping_agreement on
vendor_agreement_description = agreementid || ':' || agreement_number || ':' || agreement_rate || ':' || agreement_commission;


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


drop table if exists public.shipping_datamart;
create table public.shipping_datamart (
  shippingid bigint primary key,
  vendorid bigint,
  transfer_type text,
  full_day_at_shipping numeric(14,0),
  is_delay boolean,
  is_shipping_finish boolean,
  delay_day_at_shipping numeric(14,0),
  payment_amount numeric(14,2),
  vat numeric(14,3),
  profit numeric(14,2)
);
insert into public.shipping_datamart (shippingid, vendorid, transfer_type,
full_day_at_shipping, is_delay, is_shipping_finish, delay_day_at_shipping, payment_amount, vat, profit)
select 
shipping_info.shippingid,
vendorid,
transfer_type,
date_part('day', age(shipping_end_fact_datetime, shipping_start_fact_datetime)) as full_day_at_shipping,
cast((case when shipping_end_fact_datetime > shipping_plan_datetime
then 1 else 0 end) as boolean) as is_delay,
cast((case when status = 'finished' then 1 else 0 end) as boolean) as is_shipping_finish,
(case when shipping_end_fact_datetime > shipping_plan_datetime
then date_part('day',age(shipping_end_fact_datetime, shipping_plan_datetime)) else 0 end)
as delay_day_at_shipping,
payment_amount,
(payment_amount*(shipping_country_base_rate + agreement_rate + shipping_transfer_rate)) as vat,
payment_amount*agreement_commission as profit
from shipping_info
left join shipping_transfer
on shipping_info.transfer_type_id = shipping_transfer.transfer_type_id
left join shipping_country_rates
on shipping_info.shipping_country_id = shipping_country_rates.shipping_country_id
left join shipping_agreement
on shipping_info.agreementid = shipping_agreement.agreementid
left join shipping_status
on shipping_info.shippingid = shipping_status.shippingid;