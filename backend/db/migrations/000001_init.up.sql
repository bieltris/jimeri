CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'staff',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT users_role_check CHECK (role IN ('admin', 'staff'))
);

CREATE UNIQUE INDEX users_email_lower_unique ON users (lower(email));

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX refresh_tokens_token_hash_unique ON refresh_tokens (token_hash);
CREATE INDEX refresh_tokens_user_id_idx ON refresh_tokens (user_id);
CREATE INDEX refresh_tokens_expires_at_idx ON refresh_tokens (expires_at);

CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    responsible_name TEXT,
    responsible_whatsapp TEXT,
    note TEXT,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT clients_responsible_whatsapp_digits_check
        CHECK (responsible_whatsapp IS NULL OR responsible_whatsapp ~ '^[0-9]+$')
);

CREATE INDEX clients_name_idx ON clients (name);
CREATE INDEX clients_active_idx ON clients (active);

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT,
    price_cents BIGINT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT products_price_cents_check CHECK (price_cents >= 0)
);

CREATE INDEX products_name_idx ON products (name);
CREATE INDEX products_category_idx ON products (category);
CREATE INDEX products_active_idx ON products (active);

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id),
    created_by UUID NOT NULL REFERENCES users(id),
    note TEXT,
    cancelled_at TIMESTAMPTZ,
    cancelled_by UUID REFERENCES users(id),
    cancel_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT orders_cancel_fields_check CHECK (
        (cancelled_at IS NULL AND cancelled_by IS NULL AND cancel_reason IS NULL)
        OR
        (cancelled_at IS NOT NULL AND cancelled_by IS NOT NULL AND cancel_reason IS NOT NULL)
    )
);

CREATE INDEX orders_client_id_idx ON orders (client_id);
CREATE INDEX orders_created_by_idx ON orders (created_by);
CREATE INDEX orders_created_at_idx ON orders (created_at);
CREATE INDEX orders_not_cancelled_idx ON orders (client_id, created_at)
    WHERE cancelled_at IS NULL;

CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price_cents BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT order_items_quantity_check CHECK (quantity > 0),
    CONSTRAINT order_items_unit_price_cents_check CHECK (unit_price_cents >= 0)
);

CREATE INDEX order_items_order_id_idx ON order_items (order_id);
CREATE INDEX order_items_product_id_idx ON order_items (product_id);

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id),
    amount_cents BIGINT NOT NULL,
    note TEXT,
    created_by UUID NOT NULL REFERENCES users(id),
    cancelled_at TIMESTAMPTZ,
    cancelled_by UUID REFERENCES users(id),
    cancel_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT payments_amount_cents_check CHECK (amount_cents > 0),
    CONSTRAINT payments_cancel_fields_check CHECK (
        (cancelled_at IS NULL AND cancelled_by IS NULL AND cancel_reason IS NULL)
        OR
        (cancelled_at IS NOT NULL AND cancelled_by IS NOT NULL AND cancel_reason IS NOT NULL)
    )
);

CREATE INDEX payments_client_id_idx ON payments (client_id);
CREATE INDEX payments_created_by_idx ON payments (created_by);
CREATE INDEX payments_created_at_idx ON payments (created_at);
CREATE INDEX payments_not_cancelled_idx ON payments (client_id, created_at)
    WHERE cancelled_at IS NULL;

CREATE VIEW client_balances AS
SELECT
    c.id AS client_id,
    COALESCE(o.orders_total_cents, 0)::BIGINT AS orders_total_cents,
    COALESCE(p.payments_total_cents, 0)::BIGINT AS payments_total_cents,
    (COALESCE(o.orders_total_cents, 0) - COALESCE(p.payments_total_cents, 0))::BIGINT AS balance_cents
FROM clients c
LEFT JOIN (
    SELECT
        o.client_id,
        SUM(oi.unit_price_cents * oi.quantity)::BIGINT AS orders_total_cents
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.cancelled_at IS NULL
    GROUP BY o.client_id
) o ON o.client_id = c.id
LEFT JOIN (
    SELECT
        p.client_id,
        SUM(p.amount_cents)::BIGINT AS payments_total_cents
    FROM payments p
    WHERE p.cancelled_at IS NULL
    GROUP BY p.client_id
) p ON p.client_id = c.id;

