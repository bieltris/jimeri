-- name: CreateProduct :one
INSERT INTO products (
    name,
    category,
    price_cents
) VALUES (
    $1,
    $2,
    $3
)
RETURNING *;

-- name: GetProductByID :one
SELECT *
FROM products
WHERE id = $1;

-- name: ListProducts :many
SELECT *
FROM products
WHERE sqlc.narg('search')::text IS NULL
   OR name ILIKE '%' || sqlc.narg('search')::text || '%'
   OR category ILIKE '%' || sqlc.narg('search')::text || '%'
ORDER BY active DESC, category ASC NULLS LAST, name ASC;

-- name: ListActiveProducts :many
SELECT *
FROM products
WHERE active = true
ORDER BY category ASC NULLS LAST, name ASC;

-- name: UpdateProduct :one
UPDATE products
SET
    name = $2,
    category = $3,
    price_cents = $4,
    active = $5,
    updated_at = now()
WHERE id = $1
RETURNING *;

