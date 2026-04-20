CREATE TABLE product_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX product_categories_name_lower_unique
    ON product_categories (lower(name));
CREATE INDEX product_categories_active_idx ON product_categories (active);

INSERT INTO product_categories (name)
SELECT DISTINCT trim(category)
FROM products
WHERE category IS NOT NULL
  AND trim(category) <> ''
  AND NOT EXISTS (
      SELECT 1
      FROM product_categories pc
      WHERE lower(pc.name) = lower(trim(products.category))
  );

ALTER TABLE products
    ADD COLUMN category_id UUID REFERENCES product_categories(id);

UPDATE products
SET category_id = product_categories.id
FROM product_categories
WHERE products.category IS NOT NULL
  AND lower(trim(products.category)) = lower(product_categories.name);

DROP INDEX IF EXISTS products_category_idx;
ALTER TABLE products DROP COLUMN category;
CREATE INDEX products_category_id_idx ON products (category_id);
