<?php require __DIR__ . '/db.php'; acme_db(); /* warm + ensure flag */ ?>
<!doctype html><title>Acme Search</title>
<style>body{font-family:system-ui;margin:2rem;max-width:760px}
.warn{color:#a00}</style>
<p class="warn">AUTHORIZED LAB SYSTEM — training use only.</p>
<h1>Acme Product Search</h1>
<form method="get" action="search.php">
  <input name="q" placeholder="search products" autofocus>
  <button>Search</button>
</form>
<p><a href="/health.php">health</a></p>
