<?php
function chain_web04_enabled(): bool {
    $v = strtolower(trim((string)(getenv('CHAIN_WEB04') ?: 'true')));
    return in_array($v, ['1', 'true', 'yes', 'on'], true);
}
?>
<!doctype html><title>Acme Docs</title>
<style>body{font-family:system-ui;margin:2rem;max-width:760px}.warn{color:#a00}</style>
<p class="warn">AUTHORIZED LAB SYSTEM — training use only.</p>
<h1>Acme Document Upload</h1>
<p>Upload a profile image (PNG/JPG/GIF).</p>
<form method="post" action="upload.php" enctype="multipart/form-data">
  <input type="file" name="file">
  <button>Upload</button>
</form>
<p>Uploaded files are served from <code>/uploads/</code>.</p>
<p><a href="/health.php">health</a></p>
