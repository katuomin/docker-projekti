"""Command-line interface: parse endpoint specs and optionally probe them."""

import argparse
import sys
import urllib.error
import urllib.request

from .core import classify_status, parse_endpoint, should_retry


def probe(endpoint, timeout: float = 5.0) -> str:
    """Send a GET request to the endpoint and classify the outcome."""
    url = endpoint.url()
    try:
        with urllib.request.urlopen(url, timeout=timeout) as response:
            return classify_status(response.status)
    except urllib.error.HTTPError as exc:
        return classify_status(exc.code)
    except OSError as exc:
        print(f"  ! {url} unreachable: {exc}", file=sys.stderr)
        return "down"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="healthcheck",
        description="Check HTTP endpoints and report their health state.",
    )
    parser.add_argument("endpoints", nargs="+", help="endpoint URLs to check")
    parser.add_argument(
        "--check",
        action="store_true",
        help="send real HTTP requests (default is parse-only, no network)",
    )
    parser.add_argument(
        "--retries",
        type=int,
        default=1,
        help="how many attempts to make per endpoint with --check",
    )
    return parser


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    endpoints = [parse_endpoint(spec) for spec in args.endpoints]

    failures = 0
    for endpoint in endpoints:
        if not args.check:
            print(f"ok    {endpoint.url():40} parsed")
            continue

        attempt = 1
        state = probe(endpoint)
        while state != "up" and should_retry(attempt, args.retries):
            attempt += 1
            state = probe(endpoint)

        if state == "up":
            print(f"ok    {endpoint.url():40} {state}")
        else:
            failures += 1
            print(f"FAIL  {endpoint.url():40} {state}")

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
