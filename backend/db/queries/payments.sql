-- name: CreatePayment :one
INSERT INTO payments (
    client_id,
    amount_cents,
    payment_method,
    note,
    created_by
) VALUES (
    $1,
    $2,
    $3,
    $4,
    $5
)
RETURNING *;

-- name: GetPaymentByID :one
SELECT *
FROM payments
WHERE id = $1;

-- name: ListClientPayments :many
SELECT *
FROM payments
WHERE client_id = $1
ORDER BY created_at DESC;

-- name: CancelPayment :one
UPDATE payments
SET
    cancelled_at = now(),
    cancelled_by = $2,
    cancel_reason = $3
WHERE id = $1
  AND cancelled_at IS NULL
RETURNING *;
