"""
Acme Portal - intentionally vulnerable training web app (ELX DMZ Range, Phase 2).
Hosts three toggleable attack chains:
  WEB-01  Broken access control  (CHAIN_WEB01)
  WEB-02  IDOR                    (CHAIN_WEB02)
  WEB-08  Weak password reset     (CHAIN_WEB08)

AUTHORIZED LAB USE ONLY. Each weakness is gated by an env toggle so the *fixed*
code path can be taught for the remediation lesson. Flags are injected from the
environment at startup (rendered per-deploy, never committed).
"""
import hashlib
import os
import secrets
import time

import pymysql
from flask import (Flask, abort, jsonify, redirect, render_template_string,
                   request, session, url_for)
from werkzeug.security import check_password_hash, generate_password_hash


# ---------------------------------------------------------------------------
# Config (all from environment; safe defaults for local dev only)
# ---------------------------------------------------------------------------
def _bool(name: str, default: str = "true") -> bool:
    return os.environ.get(name, default).strip().lower() in ("1", "true", "yes", "on")


DB_HOST = os.environ.get("DB_HOST", "db")
DB_USER = os.environ.get("DB_USER", "portal_app")
DB_PASS = os.environ.get("DB_PASS", "portal_app_pw")
DB_NAME = os.environ.get("DB_NAME", "portal")

CHAIN_WEB01 = _bool("CHAIN_WEB01")   # broken access control
CHAIN_WEB02 = _bool("CHAIN_WEB02")   # IDOR
CHAIN_WEB08 = _bool("CHAIN_WEB08")   # weak password reset

FLAG_WEB01 = os.environ.get("FLAG_WEB01", "ELX{web01_PLACEHOLDER}")
FLAG_WEB02 = os.environ.get("FLAG_WEB02", "ELX{web02_PLACEHOLDER}")
FLAG_WEB08 = os.environ.get("FLAG_WEB08", "ELX{web08_PLACEHOLDER}")

# padmin's portal password is intentionally the same plaintext whose weak MD5
# is seeded into the Acme Search DB (cross-link: WEB-03 crack -> padmin login).
PADMIN_PW = os.environ.get("PADMIN_PW", "Autumn2024!")

RESET_TTL = 900  # seconds (fixed-mode token expiry)

app = Flask(__name__)
app.secret_key = os.environ.get("FLASK_SECRET", secrets.token_hex(32))

# In-memory reset-token store: username -> {token, exp, used}
_reset_tokens: dict = {}


# ---------------------------------------------------------------------------
# DB helpers
# ---------------------------------------------------------------------------
def get_db():
    return pymysql.connect(
        host=DB_HOST, user=DB_USER, password=DB_PASS, database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor, autocommit=True,
    )


def init_db(retries: int = 30):
    """Create portal schema + seed users/invoices/settings idempotently.
    Flags are written from the environment here so they rotate per-deploy."""
    last = None
    for _ in range(retries):
        try:
            conn = get_db()
            break
        except Exception as exc:  # DB not ready yet
            last = exc
            time.sleep(2)
    else:
        raise RuntimeError(f"DB never became ready: {last}")

    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INT PRIMARY KEY AUTO_INCREMENT,
                username VARCHAR(64) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                role VARCHAR(16) NOT NULL DEFAULT 'user',
                email VARCHAR(128),
                secret TEXT
            )""")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS invoices (
                id INT PRIMARY KEY,
                owner VARCHAR(64) NOT NULL,
                amount DECIMAL(10,2) NOT NULL,
                description VARCHAR(255),
                note TEXT
            )""")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS settings (
                k VARCHAR(64) PRIMARY KEY,
                v TEXT
            )""")

        def upsert_user(username, password, role, email, secret):
            cur.execute(
                """INSERT INTO users (username, password_hash, role, email, secret)
                   VALUES (%s,%s,%s,%s,%s)
                   ON DUPLICATE KEY UPDATE password_hash=VALUES(password_hash),
                       role=VALUES(role), email=VALUES(email), secret=VALUES(secret)""",
                (username, generate_password_hash(password), role, email, secret),
            )

        # padmin's personal secret IS the WEB-08 flag (only readable once you
        # take over padmin via the weak reset flow).
        upsert_user("analyst1", "analyst-pw", "user",
                    "analyst1@acme.lab", "Nothing interesting in your profile.")
        upsert_user("padmin", PADMIN_PW, "admin",
                    "padmin@acme.lab", FLAG_WEB08)
        upsert_user("cfo", secrets.token_urlsafe(12), "user", "cfo@acme.lab", "-")
        upsert_user("procurement", secrets.token_urlsafe(12), "user",
                    "procurement@acme.lab", "-")

        def upsert_invoice(iid, owner, amount, desc, note):
            cur.execute(
                """INSERT INTO invoices (id, owner, amount, description, note)
                   VALUES (%s,%s,%s,%s,%s)
                   ON DUPLICATE KEY UPDATE owner=VALUES(owner), amount=VALUES(amount),
                       description=VALUES(description), note=VALUES(note)""",
                (iid, owner, amount, desc, note),
            )

        # analyst1 legitimately owns 1005. The WEB-02 flag is in 1001 (owner cfo).
        # 1007 (owner procurement) carries a bonus vendor credential.
        upsert_invoice(1001, "cfo", 48250.00, "Q3 board materials", FLAG_WEB02)
        upsert_invoice(1002, "cfo", 1200.00, "Travel", "-")
        upsert_invoice(1005, "analyst1", 320.00, "Software license", "Your invoice.")
        upsert_invoice(1007, "procurement", 9800.00, "Vendor onboarding",
                       "Vendor portal cred -> vendor:Vend0rP@ss (bonus path).")
        upsert_invoice(1009, "procurement", 540.00, "Office supplies", "-")

        cur.execute(
            """INSERT INTO settings (k, v) VALUES ('web01_flag', %s)
               ON DUPLICATE KEY UPDATE v=VALUES(v)""", (FLAG_WEB01,))
    conn.close()


# ---------------------------------------------------------------------------
# Auth helpers
# ---------------------------------------------------------------------------
def current_user():
    return session.get("username")


def current_role():
    return session.get("role", "anon")


def require_login():
    if not current_user():
        abort(401)


# ---------------------------------------------------------------------------
# Templates (inline to keep the toy app to a few files)
# ---------------------------------------------------------------------------
BASE = """<!doctype html><title>Acme Portal</title>
<style>body{font-family:system-ui;margin:2rem;max-width:760px}
code,pre{background:#f4f4f4;padding:.2rem .4rem;border-radius:4px}
a{margin-right:1rem}.warn{color:#a00}</style>
<p class="warn">AUTHORIZED LAB SYSTEM — training use only.</p>
{% block body %}{% endblock %}"""

LOGIN_HTML = """{% extends base %}{% block body %}
<h1>Acme Portal — Sign in</h1>
<form method=post action="{{ url_for('login') }}">
  <input name=username placeholder=username>
  <input name=password placeholder=password type=password>
  <button>Sign in</button>
</form>
<p><a href="{{ url_for('reset_request_page') }}">Forgot password?</a></p>
{% if error %}<p class=warn>{{ error }}</p>{% endif %}
{% endblock %}"""

PORTAL_HTML = """{% extends base %}{% block body %}
<h1>Welcome, {{ user }} ({{ role }})</h1>
<p><a href="{{ url_for('my_secret') }}">My profile secret</a>
   <a href="{{ url_for('logout') }}">Log out</a></p>
<p>Your invoices: <a href="/api/invoice?id=1005">#1005</a></p>
<!-- admin link intentionally hidden from non-admins in the UI only -->
{% if role == 'admin' %}<p><a href="{{ url_for('admin_settings') }}">Admin settings</a></p>{% endif %}
{% endblock %}"""


def page(tpl, **kw):
    return render_template_string(tpl, base=app.jinja_env.from_string(BASE), **kw)


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------
@app.route("/health")
def health():
    return "ok", 200


@app.route("/")
def index():
    if current_user():
        return redirect(url_for("portal"))
    return page(LOGIN_HTML, error=None)


@app.route("/login", methods=["POST"])
def login():
    username = request.form.get("username", "")
    password = request.form.get("password", "")
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM users WHERE username=%s", (username,))
        row = cur.fetchone()
    conn.close()
    if row and check_password_hash(row["password_hash"], password):
        session["username"] = row["username"]
        session["role"] = row["role"]
        return redirect(url_for("portal"))
    return page(LOGIN_HTML, error="Invalid credentials"), 401


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("index"))


@app.route("/portal")
def portal():
    require_login()
    return page(PORTAL_HTML, user=current_user(), role=current_role())


@app.route("/me/secret")
def my_secret():
    """Returns the *logged-in* user's own secret. Always ownership-checked.
    padmin's secret is FLAG_WEB08 -> only reachable after WEB-08 takeover."""
    require_login()
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute("SELECT secret FROM users WHERE username=%s", (current_user(),))
        row = cur.fetchone()
    conn.close()
    return jsonify({"user": current_user(), "secret": row["secret"] if row else None})


# ----- WEB-01: Broken access control -----------------------------------------
def _admin_guard():
    """Fixed behavior enforces server-side role check. When the chain is enabled
    the guard is skipped (UI-only gating == the vulnerability)."""
    require_login()
    if not CHAIN_WEB01 and current_role() != "admin":
        abort(403)


@app.route("/admin/users")
def admin_users():
    _admin_guard()
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute("SELECT id, username, role, email FROM users")
        rows = cur.fetchall()
    conn.close()
    return jsonify({"users": rows})


@app.route("/admin/settings")
def admin_settings():
    _admin_guard()
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute("SELECT k, v FROM settings")
        rows = {r["k"]: r["v"] for r in cur.fetchall()}
    conn.close()
    return jsonify({"settings": rows})  # contains web01_flag


# ----- WEB-02: IDOR -----------------------------------------------------------
@app.route("/api/invoice")
def api_invoice():
    require_login()
    try:
        iid = int(request.args.get("id", "0"))
    except ValueError:
        abort(400)
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM invoices WHERE id=%s", (iid,))
        inv = cur.fetchone()
    conn.close()
    if not inv:
        abort(404)
    # Fixed behavior verifies object ownership; the chain skips that check.
    if not CHAIN_WEB02 and inv["owner"] != current_user():
        abort(403)
    return jsonify(inv)


# ----- WEB-08: Weak password reset -------------------------------------------
RESET_REQUEST_HTML = """{% extends base %}{% block body %}
<h1>Reset password</h1>
<form method=post action="{{ url_for('reset_request') }}">
  <input name=username placeholder=username><button>Request reset</button>
</form>
<p>Have a token? <a href="{{ url_for('reset_confirm_page') }}">Set new password</a></p>
{% endblock %}"""

RESET_CONFIRM_HTML = """{% extends base %}{% block body %}
<h1>Set new password</h1>
<form method=post action="{{ url_for('reset_confirm') }}">
  <input name=username placeholder=username>
  <input name=token placeholder=token>
  <input name=new_password placeholder="new password" type=password>
  <button>Set password</button>
</form>
{% endblock %}"""


def _make_reset_token(username: str) -> str:
    if CHAIN_WEB08:
        # VULNERABLE: predictable, derived only from username, not bound to a
        # session, never random. An attacker can compute it without the request.
        return hashlib.md5(f"acme-reset-{username}".encode()).hexdigest()[:16]
    # FIXED: cryptographically random, single-use, expiring.
    return secrets.token_urlsafe(32)


@app.route("/reset/request", methods=["GET"])
def reset_request_page():
    return page(RESET_REQUEST_HTML)


@app.route("/reset/request", methods=["POST"])
def reset_request():
    username = request.form.get("username", "")
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute("SELECT username FROM users WHERE username=%s", (username,))
        exists = cur.fetchone()
    conn.close()
    if exists:
        token = _make_reset_token(username)
        _reset_tokens[username] = {"token": token, "exp": time.time() + RESET_TTL,
                                   "used": False}
        # In a real system the token is emailed out-of-band; we never display it.
    # Always respond identically (no user enumeration via this endpoint).
    return jsonify({"status": "if the account exists, a reset token was issued"})


@app.route("/reset/confirm", methods=["GET"])
def reset_confirm_page():
    return page(RESET_CONFIRM_HTML)


@app.route("/reset/confirm", methods=["POST"])
def reset_confirm():
    username = request.form.get("username", "")
    token = request.form.get("token", "")
    new_password = request.form.get("new_password", "")
    if not (username and token and new_password):
        abort(400)

    if CHAIN_WEB08:
        # VULNERABLE: accept any token equal to the predictable value; the
        # attacker never needed to trigger /reset/request at all.
        if token != _make_reset_token(username):
            abort(403, "bad token")
    else:
        # FIXED: token must exist, match, be unexpired and single-use.
        rec = _reset_tokens.get(username)
        if (not rec or rec["used"] or token != rec["token"]
                or time.time() > rec["exp"]):
            abort(403, "bad token")
        rec["used"] = True

    conn = get_db()
    with conn.cursor() as cur:
        cur.execute("UPDATE users SET password_hash=%s WHERE username=%s",
                    (generate_password_hash(new_password), username))
    conn.close()
    return jsonify({"status": "password updated", "username": username})


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=8000)
else:
    # Under gunicorn: seed once at import.
    init_db()
