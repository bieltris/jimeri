-- name: GetDashboardSummary :one
SELECT
    COALESCE(SUM(balance_cents), 0)::bigint AS open_balance_cents,
    COUNT(*) FILTER (WHERE balance_cents > 0)::bigint AS clients_with_debt,
    COUNT(*)::bigint AS total_clients
FROM client_balances;

-- name: GetDailyOrdersTotal :one
SELECT
    COALESCE(SUM(oi.unit_price_cents * oi.quantity), 0)::bigint AS total_cents
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
WHERE o.cancelled_at IS NULL
  AND o.created_at >= $1
  AND o.created_at < $2;

-- name: GetDailyPaymentsTotal :one
SELECT
    COALESCE(SUM(amount_cents), 0)::bigint AS total_cents
FROM payments
WHERE cancelled_at IS NULL
  AND created_at >= $1
  AND created_at < $2;

