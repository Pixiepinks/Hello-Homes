(function () {
  'use strict';

  var products = [
    ['Cloud Sofa', 'Modular comfort for modern living rooms.', '$899'],
    ['Oak Dining Set', 'Warm wood tones for everyday gatherings.', '$1,249'],
    ['Linen Bed Frame', 'Soft upholstered lines with hidden storage.', '$749'],
    ['Ceramic Lamp', 'A sculptural glow for shelves and side tables.', '$129']
  ];

  function card(product) {
    return '<article class="hh-card"><div><div class="hh-art"></div><h3>' + product[0] + '</h3><p>' + product[1] + '</p></div><div class="hh-price">' + product[2] + '</div></article>';
  }

  function render() {
    document.body.innerHTML = '<div class="hh-shell">' +
      '<header class="hh-nav"><a class="hh-brand" href="/"><span class="hh-logo">⌂</span><span>Hello Homes</span></a><nav class="hh-links"><a href="#categories">Categories</a><a href="#products">Products</a><a href="/login">Login</a><a href="/checkout">Cart</a></nav></header>' +
      '<main><section class="hh-hero"><div><div class="hh-eyebrow">Furniture • Decor • Home essentials</div><h1>Beautiful rooms start at Hello Homes.</h1><p>Shop curated furniture, thoughtful decor, and practical essentials for every room. This Railway bundle serves the web app directly from the backend public directory.</p><div class="hh-actions"><a class="hh-button primary" href="#products">Shop trending products</a><a class="hh-button secondary" href="#categories">Explore categories</a></div></div><div class="hh-showcase" aria-label="Featured home collections"><div class="hh-tile large"><b>Living Room</b><span>Comfortable pieces with timeless finishes.</span></div><div class="hh-tile"><b>Bedroom</b><span>Soft textures and restful storage.</span></div><div class="hh-tile"><b>Decor</b><span>Details that make it yours.</span></div></div></section>' +
      '<section class="hh-section" id="categories"><div class="hh-section-head"><div><h2>Top Categories</h2><p>Curated essentials for every room.</p></div><a class="hh-button secondary" href="/categories">View all</a></div><div class="hh-grid"><article class="hh-card"><h3>Living Room</h3><p>Sofas, media units, coffee tables, and more.</p><div class="hh-price">Explore</div></article><article class="hh-card"><h3>Dining</h3><p>Tables, chairs, and hosting essentials.</p><div class="hh-price">Explore</div></article><article class="hh-card"><h3>Bedroom</h3><p>Beds, mattresses, wardrobes, and linens.</p><div class="hh-price">Explore</div></article><article class="hh-card"><h3>Decor</h3><p>Lighting, rugs, accents, and finishing touches.</p><div class="hh-price">Explore</div></article></div></section>' +
      '<section class="hh-section" id="products"><div class="hh-section-head"><div><h2>Trending Now</h2><p>Most popular items this week.</p></div><a class="hh-button secondary" href="/products">View all</a></div><div class="hh-grid">' + products.map(card).join('') + '</div></section></main>' +
      '<footer class="hh-footer"><strong>Hello Homes</strong><span>Secure checkout • Fast delivery • Helpful support</span></footer>' +
      '</div>';
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', render);
  } else {
    render();
  }
}());
