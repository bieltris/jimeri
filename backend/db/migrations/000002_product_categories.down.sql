ALTER TABLE products
    ADD COLUMN category TEXT;

UPDATE products
SET category = product_categories.name
FROM product_categories
WHERE products.category_id = product_categories.id;

DROP INDEX IF EXISTS products_category_id_idx;
ALTER TABLE products DROP COLUMN category_id;

DROP TABLE IF EXISTS product_categories;

CREATE INDEX products_category_idx ON products (category);
