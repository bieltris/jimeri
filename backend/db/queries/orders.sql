-- name: CreateOrder :one
INSERT INTO orders (
    client_id,
    created_by,
    note
) VALUES (
    $1,
    $2,
    $3
)
RETURNING *;

-- name: CreateOrderItem :one
INSERT INTO order_items (
    order_id,
    product_id,
    product_name,
    quantity,
    unit_price_cents
) VALUES (
    $1,
    $2,
    $3,
    $4,
    $5
)
RETURNING *;

-- name: GetOrderByID :one
SELECT *
FROM orders
WHERE id = $1;

-- name: ListClientOrders :many
SELECT
    o.*,
    COALESCE(SUM(oi.unit_price_cents * oi.quantity), 0)::bigint AS total_cents
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.id
WHERE o.client_id = $1
GROUP BY o.id
ORDER BY o.created_at DESC;

-- name: ListOrderItems :many
SELECT *
FROM order_items
WHERE order_id = $1
ORDER BY created_at ASC;

-- name: CancelOrder :one
UPDATE orders
SET
    cancelled_at = now(),
    cancelled_by = $2,
    cancel_reason = $3
WHERE id = $1
  AND cancelled_at IS NULL
RETURNING *;

