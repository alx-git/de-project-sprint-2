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

