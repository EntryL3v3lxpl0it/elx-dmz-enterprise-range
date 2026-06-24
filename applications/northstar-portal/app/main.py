import os
from fastapi import FastAPI, Form, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from starlette.middleware.sessions import SessionMiddleware
import os

app = FastAPI(title="Northstar Portal")

app.add_middleware(
    SessionMiddleware,
    secret_key=os.getenv("NORTHSTAR_SESSION_SECRET", "lab-only-dev-session-key")
)

FLAG = os.getenv("NORTHSTAR_FLAG", "ELX{local:missing_flag:dev}")

USERS = {
    "alex.customer": {
        "password": os.getenv("NORTHSTAR_LAB_PASSWORD", "Password123!"),
        "role": "customer",
        "customer_id": 1001,
    },
    "sam.customer": {
        "password": os.getenv("NORTHSTAR_LAB_PASSWORD", "Password123!"),
        "role": "customer",
        "customer_id": 1002,
    },
}

CUSTOMERS = {
    1001: {
        "name": "Alex Rivera",
        "company": "Rivera Components",
        "account_status": "Active",
        "note": "Standard synthetic customer record.",
    },
    1002: {
        "name": "Sam Patel",
        "company": "Patel Industrial Supply",
        "account_status": "Active",
        "note": f"Training flag: {FLAG}",
    },
}


def current_user(request: Request):
    username = request.session.get("username")
    if not username:
        return None

    return USERS.get(username)


@app.get("/", response_class=HTMLResponse)
def index(request: Request):
    user = current_user(request)
    if not user:
        return """
        <h1>Northstar Components Group</h1>
        <p>Customer Portal</p>
        <a href="/login">Login</a>
        <hr>
        <p>Authorized training environment only.</p>
        """

    return RedirectResponse(
        url=f"/customers/{user['customer_id']}",
        status_code=302
    )


@app.get("/login", response_class=HTMLResponse)
def login_form():
    return """
    <h1>Northstar Customer Login</h1>
    <form method="post" action="/login">
      <label>Username</label><br>
      <input name="username"><br>
      <label>Password</label><br>
      <input name="password" type="password"><br><br>
      <button type="submit">Login</button>
    </form>
    <p>Authorized training environment only.</p>
    """


@app.post("/login")
def login(
    request: Request,
    username: str = Form(...),
    password: str = Form(...),
):
    user = USERS.get(username)

    if user and user["password"] == password:
        request.session["username"] = username
        return RedirectResponse(
            url=f"/customers/{user['customer_id']}",
            status_code=302
        )

    return HTMLResponse(
        "<h1>Login failed</h1><a href='/login'>Try again</a>",
        status_code=401
    )


@app.get("/logout")
def logout(request: Request):
    request.session.clear()
    return RedirectResponse(url="/", status_code=302)


@app.get("/customers/{customer_id}", response_class=HTMLResponse)
def customer_profile(request: Request, customer_id: int):
    user = current_user(request)

    if not user:
        return RedirectResponse(url="/login", status_code=302)

    # Intentional training vulnerability:
    # The application verifies authentication but does not verify object ownership.
    # This creates a controlled IDOR for the MVP.
    customer = CUSTOMERS.get(customer_id)

    if not customer:
        return HTMLResponse("<h1>Customer not found</h1>", status_code=404)

    return f"""
    <h1>Customer Profile</h1>
    <p><b>Name:</b> {customer['name']}</p>
    <p><b>Company:</b> {customer['company']}</p>
    <p><b>Status:</b> {customer['account_status']}</p>
    <p><b>Note:</b> {customer['note']}</p>
    <hr>
    <p>Logged in as: {request.session.get('username')}</p>
    <a href="/logout">Logout</a>
    """


@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "northstar-portal"
    }
