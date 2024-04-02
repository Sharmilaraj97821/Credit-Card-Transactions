select * from credit_card_transcations

--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
with cte as(
select top 5 city,sum(amount) as spends from credit_card_transcations
group by city
order by spends desc)
,cte1 as(select city,sum(amount)over() as total from credit_card_transcations)
select distinct c1.city,c.spends,c1.total,round((c.spends/c1.total)*100,2) as percentage_contribution_of_total_creditspends from cte  c 
inner join cte1 c1 on c.city=c1.city
order by c.spends desc

--2- write a query to print highest spend month and amount spent in that month for each card type
with cte as(select datepart(year,transaction_date) as year, datename(month,transaction_date) as month,sum(amount)as total,card_type from credit_card_transcations
group by datepart(year,transaction_date),datename(month,transaction_date),card_type
)
select *from(select *,rank()over (partition by card_type order by total desc) as rn from cte)a
where rn=1;

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with cte as(select *,sum(amount)over(partition by card_type order by transaction_date,transaction_id) as cum from credit_card_transcations),
cte1 as(select *,row_number()over(partition by card_type order by cum)as rn from cte where cum>=1000000)
select * from cte1
where rn=1;

--4- write a query to find city which had lowest percentage spend for gold card type

select city,sum(amount) as total_spent,sum(case when card_type='Gold' then amount else 0 end) as gold_spent,
(sum(case when card_type='Gold' then amount else 0 end)*1.0/sum(amount))*100 as percentage_spent from credit_card_transcations
group by city
having sum(case when card_type='Gold' then amount else 0 end)>0
order by percentage_spent

--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte as(select city,exp_type,sum(amount) as spent
,case when sum(amount)=max(sum(amount))over(partition by city) then exp_type end as highest_expense_type,
case when sum(amount)=min(sum(amount))over(partition by city) then exp_type end as lowest_expense_type from credit_card_transcations
group by city,exp_type
),cte1 as(select city,highest_expense_type from cte
where highest_expense_type is not null),cte2 as(
select city,lowest_expense_type from cte
where lowest_expense_type is not null)
select c.city,c.highest_expense_type,c1.lowest_expense_type from cte1 c
inner join cte2 c1 on c.city=c1.city

--6- write a query to find percentage contribution of spends by females for each expense type
with cte as(select exp_type,sum(amount)as spends from credit_card_transcations
where gender='F'
group by exp_type),cte1 as(
select exp_type,sum(amount) as total from credit_card_transcations
group by exp_type)
select c.exp_type,c1.total as total_spends,c.spends as female_spends,round((c.spends/c1.total)*100,2) as percentage_contribution  from cte c inner join cte1 c1 on c.exp_type=c1.exp_type
order by percentage_contribution

--7- which card and expense type combination saw highest month over month growth in Jan-2014
with cte as (
select card_type,exp_type,datepart(year,transaction_date) yt
,datepart(month,transaction_date) mt,sum(amount) as total_spend
from credit_card_transcations
group by card_type,exp_type,datepart(year,transaction_date),datepart(month,transaction_date)
)
select  top 1 *, (total_spend-prev_mont_spend) as mom_growth
from (
select *
,lag(total_spend,1) over(partition by card_type,exp_type order by yt,mt) as prev_mont_spend
from cte) A
where prev_mont_spend is not null and yt=2014 and mt=1
order by mom_growth desc;

--8- during weekends which city has highest total spend to total no of transcations ratio 

select top 1 city,count(1) as no_of_transactions,sum(amount) as spent,round((sum(amount)/count(1)),2) as ratio from credit_card_transcations
where datename(weekday,transaction_date) in('saturday','sunday')
group by city
order by ratio desc

--9- which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as(select city,min(transaction_date) as first_transaction from credit_card_transcations
group by city),cte1 as(
select * from(select *,row_number()over(partition by city order by transaction_date) as rank from credit_card_transcations
)l
where rank=500)
select  c1.city,c.first_transaction,c1.transaction_date,datediff(day,c.first_transaction,c1.transaction_date) as num_of_days from cte c
inner join cte1 c1 on c.city=c1.city
order by num_of_days
