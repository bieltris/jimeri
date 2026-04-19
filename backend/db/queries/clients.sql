-- name: CreateClient :one
INSERT INTO clients (
    name,
    responsible_name,
    responsible_whatsapp,
    note
) VALUES (
    $1,
    $2,
    $3,
    $4
)
RETURNING *;

-- name: GetClientByID :one
SELECT *
FROM clients
WHERE id = $1;

-- name: ListClients :many
SELECT
    c.*,
    cb.balance_cents
FROM clients c
JOIN client_balances cb ON cb.client_id = c.id
WHERE sqlc.narg('search')::text IS NULL
   OR c.name ILIKE '%' || sqlc.narg('search')::text || '%'
   OR c.responsible_name ILIKE '%' || sqlc.narg('search')::text || '%'
ORDER BY c.active DESC, c.name ASC;

-- name: UpdateClient :one
UPDATE clients
SET
    name = $2,
    responsible_name = $3,
    responsible_whatsapp = $4,
    note = $5,
    active = $6,
    updated_at = now()
WHERE id = $1
RETURNING *;

-- name: GetClientBalance :one
SELECT *
FROM client_balances
WHERE client_id = $1;

-- name: ListClientsWithDebt :many
SELECT
    c.*,
    cb.balance_cents
FROM clients c
JOIN client_balances cb ON cb.client_id = c.id
WHERE cb.balance_cents > 0
ORDER BY cb.balance_cents DESC, c.name ASC;

