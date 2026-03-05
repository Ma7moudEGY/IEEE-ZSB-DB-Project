-- ============================================================
--  business_logic.sql
--  12 queries representing real Wagba app screen features.
--  Each query is preceded by a comment describing the feature
--  it powers, the screen it belongs to, and how it is used.
-- ============================================================


-- ============================================================
-- QUERY 1 – Feature: User Wallet Balance
-- Screen: Wallet / Checkout screen
-- Purpose: Computes a customer's current spendable wallet
--   balance by summing all credit entries and subtracting all
--   debit entries from their Wallet_Ledger history.
--   Used every time the app renders the wallet badge and to
--   decide whether "Pay with Wallet" is available at checkout.
-- ============================================================
SELECT
    c.customer_id,
    c.name,
    SUM(
        CASE WHEN wl.type = 'credit' THEN  wl.amount
             ELSE                         -wl.amount
        END
    ) AS wallet_balance
FROM Customer c
JOIN Wallet_Ledger wl ON c.customer_id = wl.customer_id
WHERE c.customer_id = 11
GROUP BY c.customer_id, c.name;


-- ============================================================
-- QUERY 2 – Feature: Restaurant Kitchen Screen
-- Screen: Branch kitchen / operations tablet
-- Purpose: Fetches all active (accepted / preparing) orders
--   for a specific branch so kitchen staff can see what to
--   cook. ASAP orders appear first; upcoming Iftar pre-orders
--   are listed after, sorted by their scheduled delivery time
--   so nothing slips through before iftar.
-- ============================================================
SELECT
    o.order_id,
    o.type,
    o.scheduled_delivery_time,
    o.created_at,
    o.total_price,
    o.is_donation,
    GROUP_CONCAT(i.name || '  x' || oi.quantity, '  |  ') AS order_items
FROM "Order" o
JOIN Order_Item oi ON o.order_id  = oi.order_id
JOIN Item i        ON oi.item_id  = i.item_id
WHERE o.branch_id = 1
  AND o.status IN ('accepted', 'preparing')
GROUP BY o.order_id
ORDER BY
    CASE WHEN o.type = 'ASAP' THEN 0 ELSE 1 END,  -- ASAP first
    o.scheduled_delivery_time ASC;                  -- then by time


-- ============================================================
-- QUERY 3 – Feature: Admin Analytics – Late Night Top Items
-- Screen: Admin analytics dashboard
-- Purpose: Finds the top 3 most ordered items during the
--   late-night window (8 PM – 11 PM) across all branches and all
--   time. Powers the "what to stock at night" insight card on
--   the admin dashboard.
-- ============================================================
SELECT
    i.name                  AS item_name,
    SUM(oi.quantity)        AS total_ordered,
    COUNT(DISTINCT o.order_id) AS orders_containing_item
FROM "Order" o
JOIN Order_Item oi ON o.order_id = oi.order_id
JOIN Item i        ON oi.item_id = i.item_id
WHERE CAST(strftime('%H', o.created_at) AS INTEGER) >= 20
  AND CAST(strftime('%H', o.created_at) AS INTEGER) <  23
GROUP BY i.item_id, i.name
ORDER BY total_ordered DESC
LIMIT 3;


-- ============================================================
-- QUERY 4 – Feature: Captain Earnings Report
-- Screen: Delivery captain's earnings / payout screen
-- Purpose: Calculates a specific captain's total earnings,
--   broken down into base delivery fees, surge bonuses, and
--   customer tips. Used to render the earnings summary card
--   visible when the captain taps "My Earnings" in the driver app.
-- ============================================================
SELECT
    dc.name                                                         AS captain_name,
    SUM(CASE WHEN dcl.earning_type = 'base'  THEN dcl.amount ELSE 0 END) AS base_fees,
    SUM(CASE WHEN dcl.earning_type = 'bonus' THEN dcl.amount ELSE 0 END) AS surge_bonuses,
    SUM(CASE WHEN dcl.earning_type = 'tip'   THEN dcl.amount ELSE 0 END) AS tips,
    SUM(dcl.amount)                                                 AS total_earned
FROM Delivery_Captain dc
JOIN Delivery_Captain_Ledger dcl ON dc.captain_id = dcl.captain_id
WHERE dc.captain_id = 3
GROUP BY dc.captain_id, dc.name;


-- ============================================================
-- QUERY 5 – Feature: Order Detail Screen
-- Screen: Customer "order details" page and receipt view
-- Purpose: Retrieves the full breakdown of a single order —
--   every item, its quantity and price, plus all selected
--   modifiers and their prices. Used to render the detailed
--   receipt both during active orders and in order history.
-- ============================================================
SELECT
    o.order_id,
    c.name                        AS customer_name,
    o.status,
    o.type,
    o.created_at,
    o.scheduled_delivery_time,
    o.is_donation,
    i.name                        AS item_name,
    oi.quantity,
    oi.unit_price                 AS item_unit_price,
    mo.name                       AS modifier_name,
    oim.quantity                  AS modifier_qty,
    oim.unit_price                AS modifier_price
FROM "Order" o
JOIN Customer c         ON o.customer_id        = c.customer_id
JOIN Order_Item oi      ON o.order_id            = oi.order_id
JOIN Item i             ON oi.item_id            = i.item_id
LEFT JOIN Order_Item_Modifier oim ON oi.order_item_id  = oim.order_item_id
LEFT JOIN Modifier_Option mo      ON oim.option_id     = mo.option_id
WHERE o.order_id = 28
ORDER BY oi.order_item_id, oim.order_item_modifier_id;


-- ============================================================
-- QUERY 6 – Feature: Branch Revenue Report
-- Screen: Admin / operations analytics dashboard
-- Purpose: Provides a per-branch revenue summary: total
--   delivered orders, gross revenue, revenue from charity
--   donations, and average order value. Used by management to
--   compare branch performance and allocate resources.
-- ============================================================
SELECT
    b.branch_id,
    b.location,
    COUNT(o.order_id)                                                     AS total_orders,
    SUM(o.total_price)                                                    AS gross_revenue,
    SUM(CASE WHEN o.is_donation = 'YES' THEN o.total_price ELSE 0 END)   AS donation_revenue,
    ROUND(AVG(o.total_price), 0)                                          AS avg_order_value
FROM Branch b
LEFT JOIN "Order" o ON b.branch_id = o.branch_id
                    AND o.status NOT IN ('cancelled', 'pending')
GROUP BY b.branch_id, b.location
ORDER BY gross_revenue DESC;


-- ============================================================
-- QUERY 7 – Feature: Customer Order History
-- Screen: "My Orders" tab in the customer app
-- Purpose: Fetches a paginated list of a customer's past
--   orders with item names, total price, order type, donation
--   flag, and their review scores (if left). Powers the order
--   history screen and the "reorder" button.
-- ============================================================
SELECT
    o.order_id,
    o.created_at,
    o.status,
    o.type,
    o.total_price,
    o.is_donation,
    GROUP_CONCAT(i.name || ' x' || oi.quantity, ', ') AS items,
    r.restaurant_review,
    r.order_review,
    r.captain_review
FROM "Order" o
JOIN Order_Item oi  ON o.order_id   = oi.order_id
JOIN Item i         ON oi.item_id   = i.item_id
LEFT JOIN Review r  ON o.order_id   = r.order_id
WHERE o.customer_id = 4  -- Nour Samir
GROUP BY o.order_id
ORDER BY o.created_at DESC;


-- ============================================================
-- QUERY 8 – Feature: Promo Code Validity Check at Checkout
-- Screen: Checkout – "Apply promo code" step
-- Purpose: Before applying a discount, the app validates that
--   the code exists, is not expired, has not exceeded its
--   global cap, and has not been used too many times by this
--   specific customer. Returns a validity_status field the
--   backend uses to accept or reject the code.
-- ============================================================
SELECT
    p.code,
    p.type,
    p.discount_value,
    p.expiry_date,
    p.max_use_per_user,
    p.global_max_uses,
    COUNT(put.usage_id)                                              AS global_uses_so_far,
    SUM(CASE WHEN put.customer_id = 10 THEN 1 ELSE 0 END) AS uses_by_this_customer,
    CASE
        WHEN p.expiry_date < date('now')
             THEN 'expired'
        WHEN COUNT(put.usage_id) >= p.global_max_uses
             THEN 'global_limit_reached'
        WHEN SUM(CASE WHEN put.customer_id = 10 THEN 1 ELSE 0 END)
             >= p.max_use_per_user
             THEN 'per_user_limit_reached'
        ELSE 'valid'
    END AS validity_status
FROM Promocode p
LEFT JOIN Promocode_Usage_Tracking put ON p.promocode_id = put.promocode_id
WHERE p.code = 'WELCOME10'
GROUP BY p.promocode_id;


-- ============================================================
-- QUERY 9 – Feature: Live Order Tracking Screen
-- Screen: Customer "track your order" map screen
-- Purpose: Returns the captain's current status, vehicle
--   details, and contact number for a customer's active order.
--   Polled every few seconds so the app can update the
--   captain's pin on the map and show "on the way" progress.
-- ============================================================
SELECT
    o.order_id,
    o.status                  AS order_status,
    o.type,
    o.scheduled_delivery_time,
    o.total_price,
    dc.name                   AS captain_name,
    dc.vehicle_type,
    dc.vehicle_plate,
    dc.current_status         AS captain_status,
    cpn.phone_number          AS captain_phone
FROM "Order" o
JOIN Delivery_Captain dc       ON o.captain_id   = dc.captain_id
JOIN Captain_Phone_Number cpn  ON dc.captain_id  = cpn.captain_id
                               AND cpn.is_primary = 'YES'
WHERE o.customer_id = 15
  AND o.status IN ('accepted', 'preparing', 'out_for_delivery');


-- ============================================================
-- QUERY 10 – Feature: Captain Leaderboard
-- Screen: Admin / HR performance dashboard
-- Purpose: Ranks all captains by total earnings and includes
--   their completed delivery count and average customer rating.
--   Used to identify top performers for bonuses and to flag
--   underperformers for coaching.
-- ============================================================
SELECT
    dc.captain_id,
    dc.name,
    dc.vehicle_type,
    COUNT(DISTINCT o.order_id)       AS deliveries_completed,
    SUM(dcl.amount)                  AS total_earned,
    ROUND(AVG(r.captain_review), 2)  AS avg_captain_rating
FROM Delivery_Captain dc
JOIN "Order" o
    ON dc.captain_id = o.captain_id
    AND o.status     = 'deliverd'
JOIN Delivery_Captain_Ledger dcl ON dc.captain_id = dcl.captain_id
LEFT JOIN Review r               ON o.order_id    = r.order_id
GROUP BY dc.captain_id, dc.name, dc.vehicle_type
ORDER BY total_earned DESC
LIMIT 10;


-- ============================================================
-- QUERY 11 – Feature: Iftar Pre-orders Dashboard
-- Screen: Branch operations screen – "Today's Scheduled" tab
-- Purpose: Shows all Iftar pre-orders scheduled for today,
--   sorted by delivery time, so the kitchen can start
--   preparing them in advance. Only shows orders that are
--   not yet delivered or cancelled.
-- ============================================================
SELECT
    o.order_id,
    c.name                         AS customer_name,
    b.location                     AS branch,
    o.scheduled_delivery_time,
    o.total_price,
    o.status,
    GROUP_CONCAT(i.name || ' x' || oi.quantity, '  |  ') AS items
FROM "Order" o
JOIN Customer c    ON o.customer_id = c.customer_id
JOIN Branch b      ON o.branch_id   = b.branch_id
JOIN Order_Item oi ON o.order_id    = oi.order_id
JOIN Item i        ON oi.item_id    = i.item_id
WHERE o.type = 'scheduled'
  AND date(o.scheduled_delivery_time) = '2025-04-05'
  AND o.status NOT IN ('cancelled', 'deliverd')
GROUP BY o.order_id
ORDER BY o.scheduled_delivery_time ASC;


-- ============================================================
-- QUERY 12 – Feature: Charity & Donation Impact Report
-- Screen: Admin / marketing dashboard – "Social Impact" card
-- Purpose: Aggregates all completed donation orders per
--   branch: total orders, total monetary value donated,
--   number of unique donors, and average donation size.
--   Used to report community impact and drive marketing
--   campaigns around the charity feature.
-- ============================================================
SELECT
    b.location                        AS branch,
    COUNT(o.order_id)                 AS total_donation_orders,
    SUM(o.total_price)                AS total_donated_value,
    COUNT(DISTINCT o.customer_id)     AS unique_donors,
    ROUND(AVG(o.total_price), 0)      AS avg_donation_amount
FROM "Order" o
JOIN Branch b ON o.branch_id = b.branch_id
WHERE o.is_donation = 'YES'
  AND o.status      = 'deliverd'
GROUP BY b.branch_id, b.location
ORDER BY total_donated_value DESC;
