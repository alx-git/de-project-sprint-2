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