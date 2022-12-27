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