# MUBB Store — Step 1: Design and Architecture

Internal working document. Scope: e-commerce only, at `mubb.store/tienda`. The existing WordPress site is NOT redesigned or modified.

Industry: **Luxury furniture retail / high-end home furnishings e-commerce**

## 1. What exists today (analysis of mubb.store)

- WordPress + Elementor (theme: Hello Elementor) + WooCommerce, with about 25 plugins.
- Bilingual ES/EN (TranslatePress). Analytics via MonsterInsights. Kommo chat button. WPForms/MetForm.
- Menu: Home, Products, About Us, Locations, Mubb Society, Mubb Design. Also `/catalogo`, `/blog`, `/registro-mubb`.
- Typography seen in CSS: **Montserrat** (main), Roboto / Roboto Slab (secondary), Century Gothic in places.
- Colors seen: white `#ffffff` and black `#000000` dominate. Grays `#efefef`, `#ced3d5`, `#878787`, `#69727d`. Blues in the CSS come from plugin defaults, not the brand. Overall look: white/black, minimal, photography-led.
- Product taxonomy (from `/categoria-producto/`):
  - Salas y ambientes: sofás (chesterfield, importados, modulares, sofás cama, loveseats), poltronas, bench/ottoman, consolas, mesas de centro, mesas auxiliares
  - Comedores: circulares, cuadrados, rectangulares
  - Dormitorios: camas, veladoras
  - Complementos: alfombras, decoración, esculturas, espejos y apliques
  - Lámparas, Sillas, Barstool, Buffets
- 3 to 4 showrooms: Quito, Cumbayá, Manta, Samborondón (Guayaquil).

To verify visually (I only saw code): exact logo, header layout, hover behavior, product card style. Take screenshots before designing.

## 2. Agreed with the client (settled, not open)

- The current WordPress site stays exactly as it is, with its current design.
- The new store is **added on top of the existing site** at `/tienda`, sharing the same identity, header, and menu.
- URL: the client wrote `mubb.com/tienda` earlier and `mubb.store/tienda` in their last message. The live site is `mubb.store`, so the store URL is **`mubb.store/tienda`**.
- To keep the design identical, the site's real resources were cloned into `reference-clone/` (pages, CSS, fonts, images, screenshots) and the store is built from them. See section 9.

## 3. Sitemap (store only)

```
/tienda                      Catalog home (featured categories + all products)
/tienda/[category]           Category listing (filters)
/tienda/producto/[slug]      Product page
/tienda/carrito              Cart
/tienda/checkout             Checkout
/tienda/pedido/exito         Payment approved
/tienda/pedido/rechazado     Payment rejected
/tienda/pedido/pendiente     Payment pending
/tienda/pedido/[id]          Order status (link from email)
/tienda/politicas            Shipping, returns, terms
```

Header and footer: replicate the MUBB WordPress header and menu so it feels like one site. The Home, About Us, and other links go back to the WordPress pages.

## 4. Wireframes (low fidelity)

### Catalog / category
```
[ MUBB header (same as WP)                       ES|EN  Cart(0) ]
-----------------------------------------------------------------
Salas > Sofás                               Sort: [Featured v]
-----------------------------------------------------------------
Filters        |  [img]      [img]      [img]
 Category      |  Name       Name       Name
 Price range   |  $ 3,200    $ 2,800    $ 4,500
 Material      |  [img]      [img]      [img]
 Color         |  ...
 In stock only |            [ Load more ]
-----------------------------------------------------------------
```
Large image cards, lots of white space, no badges or discount clutter.

### Product page
```
[ header ]
[ Gallery: big image + thumbnails ]  | Name
[ zoom, swipe on mobile          ]  | $ Price   (In stock: 4)
                                     | Color [o][o][o]
                                     | Measure [ 2.4m v ]
                                     | Qty [ - 1 + ]  [ Add to cart ]
                                     | Shipping info / Pickup at showroom
-----------------------------------------------------------------
Description | Materials and finishes | Dimensions | Care
Related products (row)
```

### Cart
Line items with image, variant, quantity, price. Summary with subtotal, shipping estimate, total. Button: Go to checkout.

### Checkout (single page, 3 blocks)
1. Contact + shipping data (or "Pick up at showroom", choose showroom)
2. Billing data (name/company, RUC or cédula, email, address)
3. Payment method: Datafast | Kushki (PayPal optional later), then Pay

### Result pages
Approved / Rejected (retry button) / Pending. Each shows the order number and what happens next.

### Mobile
Same flow, single column. Sticky "Add to cart" bar on product pages. Mini-cart drawer.

## 5. Data model (Postgres, or the CMS if Payload is chosen)

| Entity | Main fields |
|---|---|
| Category | id, name_es, name_en, slug, parent_id, image, order |
| Product | id, name_es/en, slug, description_es/en, category_ids, base_price, status (draft/published), images[], materials[], dimensions, care, seo_title, seo_description, featured |
| Variant | id, product_id, sku, options (color, measure, finish), price_override, stock, images[] |
| StockMovement | id, variant_id, delta, reason (order, adjustment, return), order_id, created_at |
| Customer | id, name, email, phone, doc_type, doc_number (RUC/cédula) |
| Address | id, customer_id, type (shipping/billing), street, city, province, notes |
| ShippingZone | id, name, provinces/cities[], cost, free_over, delivery_days |
| PickupPoint | id, name (showroom), address, hours |
| Order | id, number, customer_id, status, shipping_method (delivery/pickup), shipping_zone_id, subtotal, shipping_cost, total, currency, created_at |
| OrderItem | id, order_id, variant_id, name_snapshot, unit_price, qty |
| Payment | id, order_id, provider (datafast/kushki/paypal), provider_ref, amount, status (pending/approved/rejected/refunded), raw_response |
| EmailLog | id, order_id, type, sent_at, status |
| Page/Policy | id, slug, title, blocks (CMS blocks) |

Order states: `pending -> paid -> shipped -> delivered`, plus `cancelled`, `refunded`. Stock is reserved at checkout start (short hold) and decremented at `paid`.

## 6. Payment architecture (per the promise: both gateways at the same checkout)

- One internal `PaymentProvider` interface (`createPayment`, `handleWebhook`, `refund`).
- Adapters: Datafast, Kushki (PayPal later).
- One webhook route per provider, all writing to the same Payment + Order tables. The order is created once.
- Sandbox first; production credentials come from the client before launch.

## 7. Admin (no code changes needed)

Products, photos, prices, stock, variants, orders and statuses, shipping zones and costs, pickup points, policy pages. Order export to CSV. Emails on: order placed, payment confirmed, status changed.

## 8. Step 1 deliverables for this project

- [ ] Screenshots of the current site (header, product card, product page)
- [ ] Wireframes above turned into clean images (desktop, tablet, mobile)
- [ ] Style tokens copied from the WordPress site (fonts, colors, spacing)
- [ ] Data model diagram
- [ ] CMS/admin decision: Sanity vs Payload (recommendation: **Payload**, since stock, orders, and variants fit a database-backed CMS better than Sanity's content model)

## 9. Cloned reference (`reference-clone/`)

Downloaded from the live site so the store copies its design instead of approximating it.

| Folder | Content |
|---|---|
| `pages/` | Rendered HTML of home, category, product, catalog, and about pages |
| `assets/` | All CSS files (theme, Elementor, plugins) with their original paths, 22 MB of images from `wp-content/uploads`, Montserrat and Roboto as woff2 |
| `assets/images/2023/09/logo-mubb.png` | Logo. It is white on transparent, so the header is dark. `LOGO-REDUCIDO.png` is the short version |
| `screenshots/` | Headless Chrome captures of the live site, desktop and mobile |
| `css-urls.txt`, `img-urls.txt`, `font-urls.txt` | Source URL lists |

Findings: the brand colors are black `#000000`, white `#ffffff`, light gray `#CED3D5`, gray `#878787`, dark navy `#0D1427`. Elementor's default green, blue, and gray globals (`#61CE70`, `#6EC1E4`) are unused defaults, not the brand. Fonts are Montserrat (headings and body) with Roboto as secondary.

Next: read the screenshots, then extract the exact header, product card, and button styles into `tokens.css` and a small component CSS for the Next.js store.

## 10. What the screenshots show (visual rules the store must copy)

- **Header:** solid black bar, white "MUBB" logo on the left, small uppercase menu (Inicio, Productos, Sobre nosotros, Ubicaciones, Mubb Society, Mubb Design), social icons, search, cart with counter, Contacto, Blog, ESP / ENG.
- **Category page:** full-width dark photo banner behind the header, then white content. Left sidebar with a category tree (large uppercase parent, small uppercase children). Search bar with category dropdown above the grid. 4-column grid of product images on white, no borders, with a small gray category label and the uppercase name below. No price on the cards. Numbered pagination.
- **Product page:** image slider on the left, uppercase title, gray description, accordions (Información, Metales, Maderas), and two text buttons: **Solicitar información** and **Visitar showroom**. WhatsApp and Facebook share icons. "Productos destacados" carousel below.
- **Footer:** black, "Forma parte de la filosofía MUBB", showrooms (Quito, Manta, Guayaquil), Términos y condiciones, Trabaja con nosotros, contact email, social icons.
- **Type:** Montserrat throughout, uppercase for titles, menu, and product names. Thin weights for big headings.
- **Mobile:** same black header, compact (ESP/ENG, cart, search), full-width images, sections on black.
- Floating round chat button (Kommo) at the bottom right.

**Important finding:** the current product pages have **no price and no add-to-cart**. They are a catalog with "request information" and "visit showroom". This confirms the new store is genuinely new functionality (prices, stock, cart, checkout), not a duplicate of an existing shop. The store must add those elements in the same visual language: black header, uppercase Montserrat, white product grid, black footer, text buttons.

Note: the site has a bot-check ("Checking your browser") in front of the home page for automated visitors, so the home screenshot was not captured. The saved HTML of the home page is real.
