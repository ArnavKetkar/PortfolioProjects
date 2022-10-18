
 -- Inspecting Data--
select * from [dbo].[sales_data_sample]

 -- Checking unique values--
 select distinct status from dbo.sales_data_sample -- Nice to plot
 select distinct YEAR_ID from dbo.sales_data_sample
 select distinct PRODUCTLINE from dbo.sales_data_sample -- Nice to plot
 select distinct COUNTRY from dbo.sales_data_sample -- Nice to plot
 select distinct DEALSIZE from dbo.sales_data_sample -- Nice to plot
 select distinct TERRITORY from dbo.sales_data_sample -- Nice to plot

  -- Analysis --
  -- grouping by product line
 select PRODUCTLINE, sum(SALES) as Revenue
  from dbo.sales_data_sample
  group by PRODUCTLINE
  order by Revenue desc

  select YEAR_ID, sum(SALES) as Revenue
  from dbo.sales_data_sample
  group by YEAR_ID
  order by Revenue desc
   -- the sale in 2005 is very less. 

  select distinct MONTH_ID
  from dbo.sales_data_sample
  where YEAR_ID = 2003 -- operated all 12 months

  select distinct MONTH_ID
  from dbo.sales_data_sample
  where YEAR_ID = 2004 -- operated all 12 months

  select distinct MONTH_ID
  from dbo.sales_data_sample
  where YEAR_ID = 2005 -- operated only 5 months

  select DEALSIZE, sum(SALES) as Revenue
  from dbo.sales_data_sample
  group by DEALSIZE
  order by Revenue desc
  -- medium generates highest revenue by big margin!

   -- Sales in each month
   -- For 2003
  select MONTH_ID, sum(SALES) as Revenue, COUNT(ordernumber) as Frequency
  from dbo.sales_data_sample
  where YEAR_ID = 2003
  group by MONTH_ID
  order by Frequency desc --November has most number of orders

     -- For 2004
  select MONTH_ID, sum(SALES) as Revenue, COUNT(ordernumber) as Frequency
  from dbo.sales_data_sample
  where YEAR_ID = 2004
  group by MONTH_ID
  order by Frequency desc --November has most number of orders

  -- For 2005 only 5 months so not accurate description.

  -- What product sells most in November? Should be Classic
  select MONTH_ID, PRODUCTLINE, sum(SALES) as Revenue, COUNT(ordernumber) as Frequency
  from dbo.sales_data_sample
  where YEAR_ID = 2003 and MONTH_ID = 11
  group by MONTH_ID, PRODUCTLINE
  order by Revenue desc 
  
  select MONTH_ID, PRODUCTLINE, sum(SALES) as Revenue, COUNT(ordernumber) as Frequency
  from dbo.sales_data_sample
  where YEAR_ID = 2004 and MONTH_ID = 11
  group by MONTH_ID, PRODUCTLINE
  order by Revenue desc 

   -- Who is the best customer? (Using RFM Analysis)
   DROP TABLE IF EXISTS #rfm
;with rfm as 
   (select CUSTOMERNAME,
		  sum(SALES) as MonetaryValue,
		  avg(SALES) as AvgMonetaryValue,
		  count(ordernumber) as Frequency,
		  max(ORDERDATE) as last_order_date,
		  (select max(ORDERDATE) from dbo.sales_data_sample) as max_order_date,
		  DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from dbo.sales_data_sample)) as Recency
   from dbo.sales_data_sample
   group by CUSTOMERNAME
   ),
rfm_calc as 
 (
	select r.*, 
		   NTILE(4) over (order by Recency desc) as rfm_recency,
		   NTILE(4) over (order by Frequency) as rfm_frequency,
		   NTILE(4) over (order by MonetaryValue) as rfm_monetary
	from rfm as r
)
select c.*, rfm_recency+rfm_frequency+rfm_monetary as rfm_cell,
	   CAST(rfm_recency as varchar) + CAST(rfm_frequency as varchar) + CAST(rfm_monetary as varchar) as rfm_cell_string
	   into #rfm
from rfm_calc as c

select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331, 421) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment
from #rfm

 -- What products are most often sold together?

select distinct ORDERNUMBER, STUFF(
	(select ',' + PRODUCTCODE
	from [dbo].[sales_data_sample] as p
	where ORDERNUMBER in 
	(
		select ORDERNUMBER
		from(
		 select ORDERNUMBER, count (*) as rn
		 from [dbo].[sales_data_sample]
		 where STATUS = 'Shipped'
		 group by ORDERNUMBER
		 ) m
		 where rn = 2 --2 because only looking for orders with only 2 items
	)
	and p.ORDERNUMBER = s.ORDERNUMBER
	for xml path(''))
	, 1, 1, '') as ProductCodes
from [dbo].[sales_data_sample] as s
order by ProductCodes desc

--City with highest sales in a country
select CITY, sum(SALES) as Revenue
from dbo.sales_data_sample
where COUNTRY = 'USA' -- can be any country
group by CITY
order by Revenue desc

--Best product in United States?
select COUNTRY, YEAR_ID, PRODUCTLINE, sum(SALES) as Revenue
from [dbo].[sales_data_sample]
where COUNTRY = 'USA'
group by COUNTRY, YEAR_ID, PRODUCTLINE
order by Revenue desc