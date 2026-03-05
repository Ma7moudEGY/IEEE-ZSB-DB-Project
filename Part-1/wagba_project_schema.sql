BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "Address" (
	"Address_id"	INTEGER UNIQUE,
	"customer_id"	INTEGER NOT NULL,
	"street"	INTEGER NOT NULL,
	"floor"	INTEGER NOT NULL,
	"gps_lat"	REAL,
	"gps_ln"	REAL,
	"building"	INTEGER NOT NULL,
	"is_charity"	TEXT CHECK("is_charity" IN ('YES', 'NO')),
	PRIMARY KEY("Address_id"),
	FOREIGN KEY("customer_id") REFERENCES "Customer"("customer_id")
);
CREATE TABLE IF NOT EXISTS "Branch" (
	"branch_id"	INTEGER UNIQUE,
	"location"	TEXT NOT NULL,
	"open_at"	TEXT NOT NULL,
	"close_at"	TEXT NOT NULL,
	"restaurant_id"	INTEGER NOT NULL,
	PRIMARY KEY("branch_id"),
	FOREIGN KEY("restaurant_id") REFERENCES "Restaurant"("restaurant_id")
);
CREATE TABLE IF NOT EXISTS "Captain_Phone_Number" (
	"phone_id"	INTEGER UNIQUE,
	"captain_id"	INTEGER,
	"phone_number"	TEXT,
	"is_primary"	TEXT NOT NULL CHECK("is_primary" IN ('YES', 'NO')),
	PRIMARY KEY("phone_id"),
	FOREIGN KEY("captain_id") REFERENCES "Delivery_Captain"("captain_id")
);
CREATE TABLE IF NOT EXISTS "Category" (
	"category_id"	INTEGER UNIQUE,
	"name"	TEXT NOT NULL,
	"menu_id"	INTEGER NOT NULL,
	PRIMARY KEY("category_id"),
	FOREIGN KEY("menu_id") REFERENCES "Menu"("menu_id")
);
CREATE TABLE IF NOT EXISTS "Customer" (
	"customer_id"	INTEGER UNIQUE,
	"name"	TEXT NOT NULL,
	"email"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("customer_id")
);
CREATE TABLE IF NOT EXISTS "Customer_Phone_Number" (
	"phone_id"	INTEGER UNIQUE,
	"customer_id"	INTEGER NOT NULL,
	"phone_number"	TEXT NOT NULL,
	"is_primary"	TEXT NOT NULL CHECK("is_primary" IN ('YES', 'NO')),
	PRIMARY KEY("phone_id"),
	FOREIGN KEY("customer_id") REFERENCES "Customer"("customer_id")
);
CREATE TABLE IF NOT EXISTS "Delivery_Captain" (
	"captain_id"	INTEGER NOT NULL UNIQUE,
	"name"	TEXT NOT NULL,
	"email"	TEXT NOT NULL UNIQUE,
	"vehicle_type"	TEXT NOT NULL,
	"vehicle_plate"	TEXT NOT NULL,
	"current_status"	TEXT NOT NULL CHECK("current_status" IN ('offline', 'avaiable', 'on_delivery')),
	PRIMARY KEY("captain_id")
);
CREATE TABLE IF NOT EXISTS "Delivery_Captain_Ledger" (
	"earning_id"	INTEGER UNIQUE,
	"amount"	INTEGER NOT NULL,
	"order_id"	INTEGER NOT NULL,
	"captain_id"	INTEGER NOT NULL,
	"earning_type"	TEXT NOT NULL CHECK("earning_type" IN ('base', 'bonus', 'tip')),
	"created_at"	TEXT NOT NULL,
	PRIMARY KEY("earning_id"),
	FOREIGN KEY("captain_id") REFERENCES "Delivery_Captain"("captain_id"),
	FOREIGN KEY("order_id") REFERENCES "Order"("order_id")
);
CREATE TABLE IF NOT EXISTS "Delivery_Zone" (
	"zone_id"	INTEGER NOT NULL UNIQUE,
	"branch_id"	INTEGER NOT NULL,
	"location"	TEXT NOT NULL,
	PRIMARY KEY("zone_id"),
	FOREIGN KEY("branch_id") REFERENCES "Branch"("branch_id")
);
CREATE TABLE IF NOT EXISTS "Dynamic_Pricing_Rule" (
	"rule_id"	INTEGER NOT NULL UNIQUE,
	"name"	TEXT NOT NULL,
	"start_time"	TEXT NOT NULL,
	"end_time"	TEXT NOT NULL,
	"delivery_fee_multiplier"	REAL NOT NULL,
	PRIMARY KEY("rule_id")
);
CREATE TABLE IF NOT EXISTS "Item" (
	"item_id"	INTEGER UNIQUE,
	"category_id"	INTEGER,
	"name"	TEXT NOT NULL,
	"unit_price"	INTEGER NOT NULL,
	"is_available"	TEXT NOT NULL CHECK("is_available" IN ('YES', 'NO')),
	PRIMARY KEY("item_id"),
	FOREIGN KEY("category_id") REFERENCES "Category"("category_id")
);
CREATE TABLE IF NOT EXISTS "Menu" (
	"menu_id"	INTEGER UNIQUE,
	"name"	TEXT NOT NULL,
	"branch_id"	INTEGER NOT NULL,
	PRIMARY KEY("menu_id"),
	FOREIGN KEY("branch_id") REFERENCES "Branch"("branch_id")
);
CREATE TABLE IF NOT EXISTS "Modifier_Group" (
	"group_id"	INTEGER UNIQUE,
	"item_id"	INTEGER NOT NULL,
	"min_selections"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	"max_selections"	INTEGER,
	PRIMARY KEY("group_id"),
	FOREIGN KEY("item_id") REFERENCES "Item"("item_id")
);
CREATE TABLE IF NOT EXISTS "Modifier_Option" (
	"option_id"	INTEGER UNIQUE,
	"name"	TEXT NOT NULL,
	"group_id"	INTEGER,
	"price"	INTEGER NOT NULL,
	"is_available"	TEXT NOT NULL CHECK("is_available" IN ('YES', 'NO')),
	PRIMARY KEY("option_id"),
	FOREIGN KEY("group_id") REFERENCES "Modifier_Group"("group_id")
);
CREATE TABLE IF NOT EXISTS "Order" (
	"order_id"	INTEGER UNIQUE,
	"branch_id"	INTEGER NOT NULL,
	"captain_id"	INTEGER NOT NULL,
	"total_price"	INTEGER NOT NULL,
	"status"	TEXT NOT NULL CHECK("status" IN ('pending', 'accepted', 'preparing', 'out_for_delivery', 'deliverd', 'cancelled')),
	"type"	TEXT NOT NULL CHECK("type" IN ('ASAP', 'scheduled')),
	"scheduled_delivery_time"	TEXT,
	"is_donation"	TEXT NOT NULL,
	"created_at"	TEXT NOT NULL,
	"customer_id"	INTEGER NOT NULL,
	PRIMARY KEY("order_id"),
	FOREIGN KEY("branch_id") REFERENCES "Branch"("branch_id"),
	FOREIGN KEY("captain_id") REFERENCES "Delivery_Captain"("captain_id"),
	FOREIGN KEY("customer_id") REFERENCES "Customer"("customer_id")
);
CREATE TABLE IF NOT EXISTS "Order_Item" (
	"order_item_id"	INTEGER UNIQUE,
	"order_id"	INTEGER NOT NULL,
	"item_id"	INTEGER NOT NULL,
	"quantity"	INTEGER NOT NULL,
	"unit_price"	INTEGER NOT NULL,
	PRIMARY KEY("order_item_id"),
	FOREIGN KEY("item_id") REFERENCES "Item"("item_id"),
	FOREIGN KEY("order_id") REFERENCES "Order"("order_id")
);
CREATE TABLE IF NOT EXISTS "Order_Item_Modifier" (
	"order_item_modifier_id"	INTEGER UNIQUE,
	"order_item_id"	INTEGER NOT NULL,
	"option_id"	INTEGER NOT NULL,
	"quantity"	INTEGER NOT NULL,
	"unit_price"	INTEGER NOT NULL,
	"created_at"	TEXT NOT NULL,
	PRIMARY KEY("order_item_modifier_id"),
	FOREIGN KEY("option_id") REFERENCES "Modifier_Option"("option_id"),
	FOREIGN KEY("order_item_id") REFERENCES "Order_Item"("order_item_id")
);
CREATE TABLE IF NOT EXISTS "Payment" (
	"payment_id"	INTEGER UNIQUE,
	"order_id"	INTEGER NOT NULL,
	"payment_method"	TEXT NOT NULL CHECK("payment_method" IN ('COD', 'Credit_Card', 'Wallet_Deduction')),
	"status"	TEXT NOT NULL CHECK("status" IN ('pending', 'complete', 'failed')),
	PRIMARY KEY("payment_id"),
	FOREIGN KEY("order_id") REFERENCES "Order"("order_id")
);
CREATE TABLE IF NOT EXISTS "Promocode" (
	"promocode_id"	INTEGER NOT NULL UNIQUE,
	"code"	TEXT NOT NULL,
	"type"	TEXT NOT NULL CHECK("type" IN ('fixed', 'percentage')),
	"discount_value"	REAL NOT NULL CHECK("discount_value" >= 0),
	"expiry_date"	TEXT NOT NULL,
	"max_use_per_user"	INTEGER NOT NULL CHECK("max_use_per_user" >= 0),
	"global_max_uses"	INTEGER NOT NULL CHECK("global_max_uses" >= 0),
	PRIMARY KEY("promocode_id")
);
CREATE TABLE IF NOT EXISTS "Promocode_Usage_Tracking" (
	"usage_id"	INTEGER UNIQUE,
	"promocode_id"	INTEGER NOT NULL,
	"customer_id"	INTEGER NOT NULL,
	"order_id"	INTEGER NOT NULL,
	"created_at"	TEXT NOT NULL,
	PRIMARY KEY("usage_id"),
	FOREIGN KEY("customer_id") REFERENCES "Customer"("customer_id"),
	FOREIGN KEY("order_id") REFERENCES "Order"("order_id"),
	FOREIGN KEY("promocode_id") REFERENCES "Promocode"("promocode_id")
);
CREATE TABLE IF NOT EXISTS "Restaurant" (
	"restaurant_id"	INTEGER UNIQUE,
	"name"	TEXT NOT NULL,
	"email"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("restaurant_id")
);
CREATE TABLE IF NOT EXISTS "Review" (
	"review_id"	INTEGER UNIQUE,
	"restaurant_review"	INTEGER NOT NULL CHECK("restaurant_review" >= 1 AND "restaurant_review" <= 5),
	"order_review"	INTEGER NOT NULL CHECK("order_review" >= 1 AND "order_review" <= 5),
	"captain_review"	INTEGER NOT NULL CHECK("captain_review" >= 1 AND "captain_review" <= 5),
	"order_id"	INTEGER NOT NULL,
	"general_comment"	TEXT NOT NULL,
	PRIMARY KEY("review_id"),
	FOREIGN KEY("order_id") REFERENCES "Order"("order_id")
);
CREATE TABLE IF NOT EXISTS "Transaction" (
	"transaction_id"	INTEGER UNIQUE,
	"order_id"	INTEGER NOT NULL,
	"type"	TEXT NOT NULL CHECK("type" IN ('credit', 'cod', 'debit')),
	"created_at"	TEXT NOT NULL,
	"amount"	INTEGER NOT NULL,
	PRIMARY KEY("transaction_id"),
	FOREIGN KEY("order_id") REFERENCES "Order"("order_id")
);
CREATE TABLE IF NOT EXISTS "Wallet_Ledger" (
	"customer_id"	INTEGER NOT NULL,
	"order_id"	INTEGER NOT NULL,
	"transaction_id"	INTEGER NOT NULL,
	"amount"	INTEGER NOT NULL,
	"type"	TEXT NOT NULL CHECK("type" IN ('credit', 'debit')),
	"created_at"	TEXT NOT NULL,
	PRIMARY KEY("transaction_id","customer_id"),
	FOREIGN KEY("order_id") REFERENCES "Order"("order_id")
);
COMMIT;
