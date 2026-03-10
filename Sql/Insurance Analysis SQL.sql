use insurance_analysis;
show tables;
alter table `account executive` rename to account_executive;
desc account_executive;
desc brokerage;
select * from brokerage;
select * from fees;
alter table fees change `account exe id` account_exe_id tinyint unsigned;
alter table fees change `account executive` account_executive varchar(50);
select * from account_executive;
drop table account_executive;

select *from invoice_processed;

select * from meeting_list;
select * from opportunity;
select * from target;

-- Total Opportunities 
select count(distinct opportunity_id) as Total_Opportunitites from opportunity;

-- Open Opportunities
select count(distinct opportunity_id) as Open_Opportunities from opportunity where stage in ('qualify opportunity','propose solution');

-- Cross Sell,New,Renewal wise Target,Achieved,Invoice

select
	t.income_class,
    t.target,
    coalesce(a.achieved, 0) as achieved,
    coalesce(i.invoice_total, 0) as invoice
from 
(	
	select 'cross sell' as income_class,
		sum(cross_sell_bugdet) as target
	from target
        
	union all
        
	select 'new' as income_class,
		sum(new_budget) as target
	from target
        
	union all
    
	select 'renewal' as income_class,
		sum(renewal_budget) as target
	from target
) t

left join 

( 
	select income_class,
		   sum(fees_amount + brokerage_amount) as achieved
	from(
		   select income_class,
				sum(fees.amount) as fees_amount,
                0 as brokerage_amount
			from fees
            group by income_class
            
            union all 
            
            select income_class,
				0,
				sum(brokerage.amount) 
			from brokerage
            group by income_class
		) x 
	group by income_class
) a
on t.income_class = a.income_class

left join 
( 
	select income_class,
		sum(invoice_processed.amount) as invoice_total
	from invoice_processed
    group by income_class
) i 
on t.income_class = i.income_class;
    
    
-- No of Meetings by Account Executive 

select account_executive,
	   count(meeting_date) as meeting_count
from meeting_list
group by account_executive
order by meeting_count desc;


-- Yearly Meeting Count

select 
	   year(meeting_date) as meeting_year,
	   count(meeting_date) as meeting_count
from meeting_list
group by meeting_year
order by meeting_count;

select count(*) from meeting_list where meeting_date is null;
desc meeting_list;

alter table meeting_list add column meeting_date_new date;

update meeting_list set meeting_date_new = str_to_date(meeting_date, '%d-%m-%Y');

alter table meeting_list drop meeting_date;
alter table meeting_list change meeting_date_new meeting_date date;


-- Stage funnel by Revenue 

select stage,
	sum(revenue_amount) as total_revenue
from opportunity
group by stage
order by total_revenue desc;


-- No of Invoice by Account Executive

select account_executive,
	count(invoice_number) as invoice_count
from invoice_processed
group by account_executive
order by invoice_count desc;


-- Top 4 Opportunity by Revenue 


select opportunity_name,
	   sum(revenue_amount) as total_revenue
from opportunity
group by opportunity_name
order by total_revenue desc
limit 4;


-- Top 4 Open Opportunities 

select opportunity_name,
		sum(revenue_amount) as total_revenue
from opportunity
where stage in ('qualify opportunity','propose solution')
group by opportunity_name
order by total_revenue desc
limit 4;


-- Placed and Invoice Achievement %

-- (1) Cross sell Placed Achievement %

select concat(Round(((coalesce((select sum(amount) from brokerage where income_class = "Cross Sell"),0))
+(coalesce((select sum(amount)from fees 
where income_class = "Cross Sell"),0))) / Nullif((select sum(`Cross_sell_bugdet`) from target),0) * 100, 2),"%") as Cross_sell_plcd_achvmnt;
    
-- (2) Cross sell Invoice Achievement %
  
  select concat(round((coalesce((select sum(amount) from invoice_processed 
  where income_class = 'Cross Sell'), 0)/nullif((select sum(`Cross_sell_bugdet`) from target), 0)) * 100, 2),'%') as Cross_sell_Invoice_Achvmnt;
    
-- (3) New Placed Achievement %

select concat(Round(((coalesce((select sum(amount) from brokerage where income_class = "New"),0))
+ (coalesce((select sum(amount)from fees where income_class = "New"),0))) / Nullif((select sum(`New_budget`) from target),0) * 100, 2),"%") as New_plcd_achvmnt;

-- (4) New Invoice Achievement % 

select concat(Round((coalesce((select sum(amount) from invoice_processed where income_class = "New"),0)
 / nullif((select sum(`New_Budget`) from target),0)) * 100, 2),'%')as New_Invoice_Achvmnt;
 
 -- (5) Renewal Placed Achievement %
 
 select concat(Round(((coalesce((select sum(amount) from brokerage where income_class = "Renewal"),0))
+ (coalesce((select sum(amount)from fees where income_class = "Renewal"),0))) / Nullif((select sum(`renewal_budget`) from target),0) * 100, 2),"%") as Renewal_plcd_achvmnt;

-- (6) Renewal Invocie Achievement % 

select concat(Round((coalesce((select sum(amount) from invoice_processed where income_class = "Renewal"),0)
 / nullif((select sum(`Renewal_Budget`) from target),0)) * 100, 2),'%')as Renewal_Invoice_Achvmnt;




 




