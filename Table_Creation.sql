-- Creation Databse 
Create Database Apple_Retail_Sales
Go

Use Apple_Retail_Sales
Go

--Stores Table
Create Table stores(
Store_ID varchar(10) primary key,
Store_Name varchar(30),
City varchar(30),
Country varchar(30)
);

select * from stores

--Categories Table
Create Table category(
category_id	varchar(10) primary key,
category_name varchar(30)
);

select * from category

--Products Table
Create Table products(
Product_ID varchar(50) primary key,
Product_Name varchar(50),
Category_ID	varchar(10),
Launch_Date	date,
Price float,
constraint fk_category foreign key (category_id) references category(category_id)
);

select * from products
--drop table products

--Sales Table
Create table sales(
sale_id varchar(50) primary key,
sale_date date,
store_id varchar(10),
product_id varchar(50),
quantity int,
constraint fk_store foreign key (store_id) references stores(store_id),
constraint fk_products foreign key (Product_ID) references products(Product_ID)
);

select * from sales
--drop table sales

---Warranty Table
Create Table warranty(
claim_id varchar(10) primary key,
claim_date date,	
sale_id	varchar(50),
repair_status varchar(20),
constraint fk_sales foreign key (sale_id) references sales(sale_id)
);

select * from warranty




