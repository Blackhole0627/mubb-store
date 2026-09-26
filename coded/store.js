// MUBB Store — client-side product catalog and cart.
// No backend yet (that's Fase 3, with Datafast/Kushki). The cart persists in
// localStorage and checkout hands the order to WhatsApp as a formatted
// message, so the flow is fully usable today while payments aren't wired up.

const PRODUCTS = [
  { id:"bilow",    name:"Sofá Bilow",     cat:"Salas › Sofás", price:2850, stock:3, img:"img/p-bilow.jpg",
    desc:"Sofá de líneas rectas en cuero genuino color cognac. Estructura en madera maciza y patas metálicas.",
    materials:"Cuero genuino, madera maciza, metal", dims:"220 x 95 x 75 cm" },
  { id:"bollek",   name:"Sofá Bollek",    cat:"Salas › Sofás", price:2450, stock:5, img:"img/p-bollek.jpg",
    desc:"Sofá modular en tela blanca de alta tecnología, ideal para espacios contemporáneos.",
    materials:"Tela técnica, espuma de alta densidad", dims:"240 x 100 x 80 cm" },
  { id:"bosek",    name:"Sofá Bosek",     cat:"Salas › Sofás", price:2600, stock:2, img:"img/p-bosek.jpg",
    desc:"Sofá seccional en piel azul profundo, con respaldo bajo y líneas minimalistas.",
    materials:"Piel genuina, madera de roble", dims:"260 x 95 x 78 cm" },
  { id:"burnin",   name:"Sofá Burnin",    cat:"Salas › Sofás", price:3900, stock:1, img:"img/p-burnin.jpg",
    desc:"Sofá modular gris de gran formato, pensado para salas amplias y living de doble altura.",
    materials:"Tela bouclé, estructura en madera", dims:"320 x 100 x 80 cm" },
  { id:"ricche",   name:"Sofá Ricche",    cat:"Salas › Sofás", price:3200, stock:2, img:"img/p-ricche.jpg",
    desc:"Sofá de tres cuerpos en cuero cognac con patas metálicas finas.",
    materials:"Cuero genuino, metal", dims:"250 x 90 x 78 cm" },
  { id:"gales",    name:"Mesa Gales",     cat:"Comedores › Mesas", price:3400, stock:2, img:"img/p-gales.jpg",
    desc:"Mesa de comedor circular con cubierta en piedra natural y base en madera torneada.",
    materials:"Piedra natural, madera de roble", dims:"Ø 160 x 75 cm" },
  { id:"infinity", name:"Consola Infinity", cat:"Salas › Consolas", price:1950, stock:4, img:"img/p-infinity.jpg",
    desc:"Consola escultórica con base en acero inoxidable y cubierta en piedra blanca.",
    materials:"Piedra natural, acero inoxidable", dims:"140 x 40 x 78 cm" },
  { id:"consola",  name:"Consola Line",   cat:"Salas › Consolas", price:1680, stock:3, img:"img/p-consola.jpg",
    desc:"Consola en madera con frente ranurado y base metálica curva.",
    materials:"Madera de roble, metal", dims:"160 x 45 x 65 cm" },
  { id:"chaise",   name:"Chaise Longue Curvo", cat:"Salas › Poltronas", price:2200, stock:2, img:"img/p-chaise.jpg",
    desc:"Chaise longue de líneas curvas en terciopelo gris, base en madera.",
    materials:"Terciopelo, madera", dims:"260 x 90 x 70 cm" },
];

function fmt(n){ return "$ " + n.toLocaleString("es-EC"); }
function getProduct(id){ return PRODUCTS.find(p => p.id === id); }

function getCart(){
  try { return JSON.parse(localStorage.getItem("mubb_cart") || "[]"); } catch { return []; }
}
function setCart(cart){
  localStorage.setItem("mubb_cart", JSON.stringify(cart));
  updateCartCount();
}
function addToCart(id, qty){
  qty = qty || 1;
  const cart = getCart();
  const line = cart.find(l => l.id === id);
  if (line) line.qty += qty; else cart.push({ id, qty });
  setCart(cart);
}
function removeFromCart(id){
  setCart(getCart().filter(l => l.id !== id));
}
function setQty(id, qty){
  const cart = getCart();
  const line = cart.find(l => l.id === id);
  if (line) { line.qty = Math.max(1, qty); setCart(cart); }
}
function cartLines(){
  return getCart().map(l => ({ ...l, product: getProduct(l.id) })).filter(l => l.product);
}
function cartTotal(){
  return cartLines().reduce((sum, l) => sum + l.product.price * l.qty, 0);
}
function cartCount(){
  return getCart().reduce((n, l) => n + l.qty, 0);
}
function updateCartCount(){
  document.querySelectorAll(".cart-count").forEach(el => el.textContent = cartCount());
}
document.addEventListener("DOMContentLoaded", updateCartCount);
