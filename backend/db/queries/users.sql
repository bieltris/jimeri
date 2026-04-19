-- name: CreateUser :one
INSERT INTO users (
    name,
    email,
    password_hash,
    role
) VALUES (
    $1,
    $2,
    $3,
    $4
)
RETURNING *;

-- name: GetUserByID :one
SELECT *
FROM users
WHERE id = $1;

-- name: GetUserByEmail :one
SELECT *
FROM users
WHERE lower(email) = lower($1);

-- name: ListUsers :many
SELECT *
FROM users
ORDER BY name ASC;

-- name: UpdateUser :one
UPDATE users
SET
    name = $2,
    email = $3,
    role = $4,
    updated_at = now()
WHERE id = $1
RETURNING *;

