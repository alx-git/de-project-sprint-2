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
  vat numeric(14,5),
  profit numeric(14,5)
);
insert into public.shipping_datamart (shippingid, vendorid, transfer_type,
full_day_at_shipping, is_delay, is_shipping_finish, delay_day_at_shipping, payment_amount, vat, profit)
select 
shipping_info.shippingid,
vendorid,
transfer_type,
extract (day from (shipping_end_fact_datetime - shipping_start_fact_datetime)) as full_day_at_shipping,
cast((case when shipping_end_fact_datetime > shipping_plan_datetime
then 1 else 0 end) as boolean) as is_delay,
cast((case when status = 'finished' then 1 else 0 end) as boolean) as is_shipping_finish,
(case when shipping_end_fact_datetime > shipping_plan_datetime
then extract (day from (shipping_end_fact_datetime - shipping_plan_datetime)) else 0 end)
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