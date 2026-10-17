"""Unit tests for the healthcheck package.

Includes the boundary (raja-arvo) tests required by the assignment:

- ``test_boundary_499_vs_500``: the exact split between "degraded" and "down"
- ``test_boundary_exactly_at_limit``: the exact split between
  "may retry" and "retries exhausted"
"""

import pytest

from healthcheck.core import Endpoint, classify_status, parse_endpoint, should_retry


class TestParseEndpoint:
    def test_full_spec(self):
        endpoint = parse_endpoint("http://localhost:3000/health")
        assert endpoint == Endpoint(host="localhost", port=3000, path="/health")
        assert endpoint.url() == "http://localhost:3000/health"

    def test_default_ports(self):
        assert parse_endpoint("http://localhost/health").port == 80
        assert parse_endpoint("https://example.com/").port == 443

    def test_missing_scheme_raises(self):
        with pytest.raises(ValueError, match="http://"):
            parse_endpoint("localhost:3000/health")

    def test_bad_port_raises(self):
        with pytest.raises(ValueError, match="invalid port"):
            parse_endpoint("http://localhost:abc/health")


class TestClassifyStatus:
    @pytest.mark.parametrize(
        ("code", "expected"),
        [
            (200, "up"),
            (204, "up"),
            (301, "degraded"),
            (404, "degraded"),
            (503, "down"),
        ],
    )
    def test_classification(self, code, expected):
        assert classify_status(code) == expected

    def test_boundary_499_vs_500(self):
        """Boundary test: 499 is the last 'degraded' code, 500 the first 'down'."""
        assert classify_status(499) == "degraded"
        assert classify_status(500) == "down"

    def test_invalid_code_raises(self):
        with pytest.raises(ValueError):
            classify_status(600)


class TestShouldRetry:
    def test_allows_retries_until_limit(self):
        assert should_retry(1, 3) is True
        assert should_retry(2, 3) is True

    def test_boundary_exactly_at_limit(self):
        """Boundary test: at exactly max_attempts, no more retries are allowed."""
        assert should_retry(3, 3) is False

    def test_zero_attempts(self):
        assert should_retry(1, 0) is False


class TestCli:
    def test_parse_only_reports_ok(self, capsys):
        from healthcheck.cli import main

        exit_code = main(["http://localhost:3000/health"])
        captured = capsys.readouterr()
        assert exit_code == 0
        assert "http://localhost:3000/health" in captured.out
