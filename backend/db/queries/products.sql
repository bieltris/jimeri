-- name: CreateProduct :one
WITH inserted AS (
    INSERT INTO products (
        name,
        category_id,
        price_cents
    ) VALUES (
        $1,
        sqlc.narg('category_id')::uuid,
        $2
    )
    RETURNING *
)
SELECT
    inserted.id,
    inserted.name,
    inserted.category_id,
    product_categories.name AS category_name,
    inserted.price_cents,
    inserted.active,
    inserted.created_at,
    inserted.updated_at
FROM inserted
LEFT JOIN product_categories ON product_categories.id = inserted.category_id;

-- name: GetProductByID :one
SELECT
    products.id,
    products.name,
    products.category_id,
    product_categories.name AS category_name,
    products.price_cents,
    products.active,
    products.created_at,
    products.updated_at
FROM products
LEFT JOIN product_categories ON product_categories.id = products.category_id
WHERE products.id = $1;

-- name: ListProducts :many
SELECT
    products.id,
    products.name,
    products.category_id,
    product_categories.name AS category_name,
    products.price_cents,
    products.active,
    products.created_at,
    products.updated_at
FROM products
LEFT JOIN product_categories ON product_categories.id = products.category_id
WHERE sqlc.narg('search')::text IS NULL
   OR products.name ILIKE '%' || sqlc.narg('search')::text || '%'
   OR product_categories.name ILIKE '%' || sqlc.narg('search')::text || '%'
ORDER BY products.active DESC, product_categories.name ASC NULLS LAST, products.name ASC;

-- name: ListActiveProducts :many
SELECT
    products.id,
    products.name,
    products.category_id,
    product_categories.name AS category_name,
    products.price_cents,
    products.active,
    products.created_at,
    products.updated_at
FROM products
LEFT JOIN product_categories ON product_categories.id = products.category_id
LEFT JOIN (
    SELECT
        oi.product_id,
        COALESCE(SUM(oi.quantity), 0)::bigint AS total_ordered_quantity
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    WHERE o.cancelled_at IS NULL
    GROUP BY oi.product_id
) product_popularity ON product_popularity.product_id = products.id
WHERE products.active = true
ORDER BY
    COALESCE(product_popularity.total_ordered_quantity, 0) DESC,
    product_categories.name ASC NULLS LAST,
    products.name ASC;

-- name: UpdateProduct :one
WITH updated AS (
    UPDATE products
    SET
        name = $2,
        category_id = sqlc.narg('category_id')::uuid,
        price_cents = $3,
        active = $4,
        updated_at = now()
    WHERE products.id = $1
    RETURNING *
)
SELECT
    updated.id,
    updated.name,
    updated.category_id,
    product_categories.name AS category_name,
    updated.price_cents,
    updated.active,
    updated.created_at,
    updated.updated_at
FROM updated
LEFT JOIN product_categories ON product_categories.id = updated.category_id;
