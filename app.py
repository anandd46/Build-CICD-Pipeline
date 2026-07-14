import os
import socket
import datetime
import platform
from flask import Flask, jsonify

# timezone-aware UTC helper — avoids the utcnow() deprecation warning in 3.12+
_UTC = datetime.timezone.utc


def _now() -> datetime.datetime:
    return datetime.datetime.now(_UTC)

app = Flask(__name__)

# Pull environment config at startup
ENV = os.environ.get("APP_ENV","production")
CONTAINER_NAME = os.environ.get("HOSTNAME", socket.gethostname())


@app.route("/")
def index():
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>CI/CD Pipeline — Deployed</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #0d1117;
            color: #c9d1d9;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }}
        .card {{
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 12px;
            padding: 40px 50px;
            max-width: 680px;
            width: 90%;
            box-shadow: 0 8px 32px rgba(0,0,0,0.4);
        }}
        .badge {{
            display: inline-block;
            background: #238636;
            color: #ffffff;
            font-size: 12px;
            font-weight: 600;
            padding: 4px 10px;
            border-radius: 20px;
            margin-bottom: 20px;
            letter-spacing: 0.5px;
        }}
        h1 {{
            font-size: 26px;
            color: #58a6ff;
            margin-bottom: 8px;
        }}
        .subtitle {{
            font-size: 14px;
            color: #8b949e;
            margin-bottom: 30px;
        }}
        .stack {{
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-bottom: 30px;
        }}
        .tag {{
            background: #21262d;
            border: 1px solid #30363d;
            border-radius: 6px;
            padding: 5px 12px;
            font-size: 13px;
            color: #79c0ff;
        }}
        .meta {{
            background: #0d1117;
            border: 1px solid #30363d;
            border-radius: 8px;
            padding: 18px 20px;
        }}
        .meta-row {{
            display: flex;
            justify-content: space-between;
            padding: 6px 0;
            border-bottom: 1px solid #21262d;
            font-size: 13px;
        }}
        .meta-row:last-child {{ border-bottom: none; }}
        .meta-key {{ color: #8b949e; }}
        .meta-val {{ color: #e6edf3; font-family: monospace; }}
        footer {{
            margin-top: 24px;
            font-size: 12px;
            color: #484f58;
            text-align: center;
        }}
    </style>
</head>
<body>
    <div class="card">
        <div class="badge">✓ Deployment Successful</div>
        <h1>CI/CD Pipeline Successfully Deployed</h1>
        <p class="subtitle">Automated deployment via GitHub Actions → Docker → AWS EC2</p>

        <div class="stack">
            <span class="tag">GitHub Actions</span>
            <span class="tag">Docker</span>
            <span class="tag">AWS EC2</span>
            <span class="tag">CI/CD Pipeline</span>
        </div>

        <div class="meta">
            <div class="meta-row">
                <span class="meta-key">Hostname</span>
                <span class="meta-val">{socket.gethostname()}</span>
            </div>
            <div class="meta-row">
                <span class="meta-key">Deployment Timestamp</span>
                <span class="meta-val">{_now().strftime('%Y-%m-%d %H:%M:%S UTC')}</span>
            </div>
            <div class="meta-row">
                <span class="meta-key">Python Version</span>
                <span class="meta-val">{platform.python_version()}</span>
            </div>
            <div class="meta-row">
                <span class="meta-key">Container Name</span>
                <span class="meta-val">{CONTAINER_NAME}</span>
            </div>
            <div class="meta-row">
                <span class="meta-key">Environment</span>
                <span class="meta-val">{ENV}</span>
            </div>
            <div class="meta-row">
                <span class="meta-key">Pipeline</span>
                <span class="meta-val">CI/CD — GitHub Actions</span>
            </div>
        </div>

        <footer>Deployed automatically · No manual intervention required</footer>
    </div>
</body>
</html>"""


@app.route("/health")
def health():
    return jsonify(
        status="healthy",
        timestamp=_now().isoformat(),
        hostname=socket.gethostname(),
        environment=ENV,
    ), 200


@app.route("/info")
def info():
    return jsonify(
        python_version=platform.python_version(),
        platform=platform.system(),
        container=CONTAINER_NAME,
        environment=ENV,
    ), 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=False)
