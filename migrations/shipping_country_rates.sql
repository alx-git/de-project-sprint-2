drop table if exists public.shipping_country_rates;
create table public.shipping_country_rates (
  shipping_country_id serial primary key,
  shipping_country text,
  shipping_country_base_rate numeric(14,3)  
);
insert into public.shipping_country_rates (shipping_country, shipping_country_base_rate)
select distinct shipping_country, shipping_country_base_rate from public.shipping;