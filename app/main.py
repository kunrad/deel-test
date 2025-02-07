import re
from models import Base, IpRecord
from db import SessionLocal, engine
from sqlalchemy.orm import Session
import socket
from fastapi.responses import HTMLResponse
from fastapi import FastAPI, Request, Response

# Create the database tables (idempotent - only creates if not exists)
Base.metadata.create_all(bind=engine)

app = FastAPI()


@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    # Extract the IP from headers or from client host info
    # We'll try 'x-forwarded-for' first if behind a proxy, otherwise fall back to client host.
    forwarded_for = request.headers.get('x-forwarded-for')
    if forwarded_for:
        # Sometimes x-forwarded-for can have multiple IPs, take the first.
        client_ip = forwarded_for.split(",")[0].strip()
    else:
        client_ip = request.client.host

    # Validate IP (simple check for IPv4, though you can handle IPv6 similarly).
    ipv4_pattern = r"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$"
    if not re.match(ipv4_pattern, client_ip):
        client_ip = "0.0.0.0"

    # Reverse the IP
    reversed_ip = ".".join(client_ip.split(".")[::-1])

    # Store in the database
    try:
        db = SessionLocal()
        new_record = IpRecord(ip=client_ip, reversed_ip=reversed_ip)
        db.add(new_record)
        db.commit()
    finally:
        db.close()

    # Return as HTML with black background and deep-green text
    html_content = f"""
    <html>
        <head>
            <title>IP Reverse</title>
            <style>
                body {{
                    background-color: #000000;
                    color: #008000; /* Deep Green */
                    font-family: monospace;
                }}
                .container {{
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                }}
                h1, h2 {{
                    margin: 0.5em;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Original IP: {client_ip}</h1>
                <h2>Reversed IP: {reversed_ip}</h2>
            </div>
        </body>
    </html>
    """
    return HTMLResponse(content=html_content)