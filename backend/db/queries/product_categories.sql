-- name: CreateProductCategory :one
INSERT INTO product_categories (
    name
) VALUES (
    $1
)
RETURNING *;

-- name: ListProductCategories :many
SELECT *
FROM product_categories
WHERE sqlc.narg('search')::text IS NULL
   OR name ILIKE '%' || sqlc.narg('search')::text || '%'
ORDER BY active DESC, name ASC;

-- name: ListActiveProductCategories :many
SELECT *
FROM product_categories
WHERE active = true
ORDER BY name ASC;

-- name: GetProductCategoryByID :one
SELECT *
FROM product_categories
WHERE id = $1;

-- name: UpdateProductCategory :one
UPDATE product_categories
SET
    name = $2,
    active = $3,
    updated_at = now()
WHERE id = $1
RETURNING *;
