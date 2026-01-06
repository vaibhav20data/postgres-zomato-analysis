CREATE TABLE customers(
customer_id INT PRIMARY KEY,
customer_name VARCHAR(30),
registration_date DATE
);


CREATE TABLE restaurants(
restaurant_id INT PRIMARY KEY,
restaurant_name VARCHAR(50),
city VARCHAR(50),
opening_hours VARCHAR (20)
);

CREATE TABLE riders(
rider_id INT PRIMARY KEY,
rider_name VARCHAR(50),
signup_date DATE
);

CREATE TABLE orders(
order_id INT PRIMARY KEY,
customer_id INT REFERENCES customers(customer_id),
restaurant_id INT REFERENCES restaurants (restaurant_id),
order_item VARCHAR (100),
order_date DATE,
order_time TIME,
order_status VARCHAR (50),
total_amount FLOAT
);

CREATE TABLE deliveries(
delivery_id	INT PRIMARY KEY,
order_id INT REFERENCES orders(order_id),	
delivery_status	VARCHAR(50),
delivery_time TIME,	
rider_id INT REFERENCES riders(rider_id)
);