"""Pure, unit-testable core logic for the healthcheck CLI."""

from dataclasses import dataclass


@dataclass(frozen=True)
class Endpoint:
    """A parsed endpoint: where to send the request and what path to hit."""

    host: str
    port: int
    path: str

    def url(self) -> str:
        return f"http://{self.host}:{self.port}{self.path}"


def parse_endpoint(spec: str) -> Endpoint:
    """Parse a URL like ``http://localhost:3000/health`` into an Endpoint.

    Raises:
        ValueError: if the spec has no http(s) scheme, no host, or a
            non-numeric port.
    """
    if not spec.startswith(("http://", "https://")):
        raise ValueError(f"spec must start with http:// or https://, got {spec!r}")

    rest = spec.split("://", 1)[1]
    host_port, slash, path = rest.partition("/")
    if not slash:
        path = "/"
    else:
        path = "/" + path

    if ":" in host_port:
        host, port_text = host_port.rsplit(":", 1)
        if not port_text.isdigit():
            raise ValueError(f"invalid port {port_text!r} in {spec!r}")
        port = int(port_text)
    else:
        host = host_port
        port = 443 if spec.startswith("https://") else 80

    if not host:
        raise ValueError(f"missing host in {spec!r}")

    return Endpoint(host=host, port=port, path=path)


def classify_status(code: int) -> str:
    """Map an HTTP status code to a coarse health state.

    2xx -> "up", 3xx/4xx -> "degraded", 5xx -> "down".
    """
    if 200 <= code <= 299:
        return "up"
    if 300 <= code <= 499:
        return "degraded"
    if 500 <= code <= 599:
        return "guh????"
    raise ValueError(f"not a valid HTTP status code: {code}")


def should_retry(attempt: int, max_attempts: int) -> bool:
    """Return True if more attempts are allowed.

    ``attempt`` is the 1-based number of attempts already made, so with
    ``max_attempts=3`` the answer is True for attempts 1 and 2 and False
    from attempt 3 on.
    """
    return attempt < max_attempts
