-- Shared store data model (MUBB Store and SACRUM). PostgreSQL.
-- Step 1 design artifact. Payload/Drizzle collections will mirror these tables.
-- Money is stored in cents (integer) to avoid rounding errors. Currency: USD.

CREATE TYPE product_status  AS ENUM ('draft', 'published', 'archived');
CREATE TYPE order_status    AS ENUM ('pending', 'paid', 'shipped', 'delivered', 'cancelled', 'refunded');
CREATE TYPE ship_method     AS ENUM ('delivery', 'pickup');
CREATE TYPE payment_status  AS ENUM ('pending', 'approved', 'rejected', 'refunded');
CREATE TYPE payment_provider AS ENUM ('datafast', 'kushki', 'paypal');
CREATE TYPE stock_reason    AS ENUM ('order', 'adjustment', 'return', 'initial');

CREATE TABLE category (
  id          serial PRIMARY KEY,
  parent_id   int REFERENCES category(id),
  slug        text UNIQUE NOT NULL,
  name_es     text NOT NULL,
  name_en     text,
  image_url   text,
  sort_order  int DEFAULT 0
);

CREATE TABLE product (
  id              serial PRIMARY KEY,
  slug            text UNIQUE NOT NULL,
  name_es         text NOT NULL,
  name_en         text,
  description_es  text,
  description_en  text,
  base_price      int NOT NULL,            -- cents
  status          product_status DEFAULT 'draft',
  featured        boolean DEFAULT false,
  customizable    boolean DEFAULT false,   -- SACRUM: a piece can be in-stock AND customizable at once
  materials       text[],                  -- e.g. {'cuero', 'madera de roble'}
  dimensions      text,                    -- free text: "240 x 95 x 80 cm"
  care            text,
  seo_title       text,
  seo_description text,
  created_at      timestamptz DEFAULT now()
);

CREATE TABLE product_category (
  product_id  int REFERENCES product(id) ON DELETE CASCADE,
  category_id int REFERENCES category(id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, category_id)
);

CREATE TABLE product_image (
  id          serial PRIMARY KEY,
  product_id  int REFERENCES product(id) ON DELETE CASCADE,
  variant_id  int,                         -- optional: image belongs to one variant
  url         text NOT NULL,
  alt         text,
  sort_order  int DEFAULT 0                -- no limit on images per product
);

CREATE TABLE variant (
  id             serial PRIMARY KEY,
  product_id     int REFERENCES product(id) ON DELETE CASCADE,
  sku            text UNIQUE NOT NULL,
  options        jsonb NOT NULL DEFAULT '{}',   -- {"color":"beige","medida":"2.4m","acabado":"mate"}
  price_override int,                            -- cents, null = use base_price
  stock          int NOT NULL DEFAULT 0 CHECK (stock >= 0),
  low_stock_at   int DEFAULT 1                   -- notify when stock <= this
);
ALTER TABLE product_image ADD FOREIGN KEY (variant_id) REFERENCES variant(id) ON DELETE SET NULL;

CREATE TABLE stock_movement (
  id          serial PRIMARY KEY,
  variant_id  int REFERENCES variant(id),
  delta       int NOT NULL,
  reason      stock_reason NOT NULL,
  order_id    int,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE customer (
  id          serial PRIMARY KEY,
  name        text NOT NULL,
  email       text NOT NULL,
  phone       text,
  doc_type    text,                        -- 'cedula' | 'ruc' | 'pasaporte'
  doc_number  text
);

CREATE TABLE address (
  id           serial PRIMARY KEY,
  customer_id  int REFERENCES customer(id),
  kind         text CHECK (kind IN ('shipping', 'billing')),
  street       text, city text, province text, notes text
);

CREATE TABLE shipping_zone (
  id            serial PRIMARY KEY,
  name          text NOT NULL,             -- "Quito", "Guayaquil", "Resto del país"
  provinces     text[],
  cost          int NOT NULL,              -- cents
  free_over     int,                       -- cents, null = never free
  delivery_days text
);

CREATE TABLE pickup_point (
  id       serial PRIMARY KEY,
  name     text NOT NULL,                  -- showroom
  address  text, hours text, active boolean DEFAULT true
);

CREATE TABLE "order" (
  id               serial PRIMARY KEY,
  number           text UNIQUE NOT NULL,   -- human readable, e.g. MUBB-000123
  customer_id      int REFERENCES customer(id),
  status           order_status DEFAULT 'pending',
  ship_method      ship_method NOT NULL,
  shipping_zone_id int REFERENCES shipping_zone(id),
  pickup_point_id  int REFERENCES pickup_point(id),
  shipping_addr_id int REFERENCES address(id),
  billing_addr_id  int REFERENCES address(id),
  subtotal         int NOT NULL,
  shipping_cost    int NOT NULL DEFAULT 0,
  total            int NOT NULL,
  notes            text,
  created_at       timestamptz DEFAULT now()
);
ALTER TABLE stock_movement ADD FOREIGN KEY (order_id) REFERENCES "order"(id);

CREATE TABLE order_item (
  id          serial PRIMARY KEY,
  order_id    int REFERENCES "order"(id) ON DELETE CASCADE,
  variant_id  int REFERENCES variant(id),
  name        text NOT NULL,               -- snapshot at purchase time
  unit_price  int NOT NULL,                -- snapshot, cents
  qty         int NOT NULL CHECK (qty > 0)
);

CREATE TABLE payment (
  id            serial PRIMARY KEY,
  order_id      int REFERENCES "order"(id),
  provider      payment_provider NOT NULL,
  provider_ref  text,                      -- transaction id from the gateway
  amount        int NOT NULL,
  status        payment_status DEFAULT 'pending',
  raw_response  jsonb,
  created_at    timestamptz DEFAULT now(),
  UNIQUE (provider, provider_ref)          -- makes webhooks idempotent
);

CREATE TABLE email_log (
  id        serial PRIMARY KEY,
  order_id  int REFERENCES "order"(id),
  kind      text,                          -- placed | paid | shipped | delivered | cancelled
  sent_at   timestamptz DEFAULT now(),
  ok        boolean
);

CREATE INDEX ON variant (product_id);
CREATE INDEX ON "order" (status, created_at DESC);
CREATE INDEX ON payment (order_id);
