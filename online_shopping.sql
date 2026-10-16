CREATE TABLE IF NOT EXISTS products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL CHECK (length(trim(name)) > 0),
    description TEXT NOT NULL DEFAULT '',
    price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS products_active_name_idx
    ON products (name)
    WHERE is_active = TRUE;

CREATE OR REPLACE FUNCTION set_product_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS products_set_updated_at ON products;
CREATE TRIGGER products_set_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION set_product_updated_at();

-- CREATE
PREPARE product_create (VARCHAR, VARCHAR, TEXT, NUMERIC, INTEGER) AS
    INSERT INTO products (sku, name, description, price, stock_quantity)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *;

-- READ
PREPARE product_list AS
    SELECT *
    FROM products
    WHERE is_active = TRUE
    ORDER BY created_at DESC;

-- READ
PREPARE product_get (BIGINT) AS
    SELECT *
    FROM products
    WHERE id = $1;

-- UPDATE
PREPARE product_update (BIGINT, VARCHAR, VARCHAR, TEXT, NUMERIC, INTEGER, BOOLEAN) AS
    UPDATE products
    SET sku = $2,
        name = $3,
        description = $4,
        price = $5,
        stock_quantity = $6,
        is_active = $7
    WHERE id = $1
    RETURNING *;

-- DELETE
PREPARE product_delete (BIGINT) AS
    DELETE FROM products
    WHERE id = $1
    RETURNING *;