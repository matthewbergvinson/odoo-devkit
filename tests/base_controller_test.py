"""
RTP Denver - Base Controller Test Classes
Task 4.2: Create base test classes for models, views, and controllers

This module provides comprehensive base test classes for testing Odoo controllers,
including HTTP endpoint testing, JSON response validation, and authentication.
"""

import json
import logging
from typing import Any, Dict, List, Optional
from unittest.mock import Mock, patch

import pytest

# These imports will work when Odoo is available
try:
    import werkzeug

    from odoo.exceptions import AccessError, UserError, ValidationError
    from odoo.http import request
    from odoo.tests.common import HttpCase, TransactionCase
    from odoo.tools import mute_logger

    ODOO_AVAILABLE = True
except ImportError:
    # Mock classes for when Odoo is not available (unit testing)
    ODOO_AVAILABLE = False

    class HttpCase:
        pass

    class TransactionCase:
        pass

    class AccessError(Exception):
        pass

    class UserError(Exception):
        pass

    class ValidationError(Exception):
        pass

    request = Mock()
    werkzeug = Mock()


class BaseControllerTest:
    """
    Base test class for Odoo controller testing without database dependency.

    This class provides functionality for testing controller logic,
    request handling, and response formatting.
    """

    @pytest.fixture(autouse=True)
    def setup_logging(self, caplog):
        """Setup logging for tests."""
        caplog.set_level(logging.INFO)
        self.logger = logging.getLogger(self.__class__.__name__)

    @pytest.fixture
    def mock_request(self):
        """Create a mock HTTP request for testing."""
        mock_req = Mock()
        mock_req.httprequest = Mock()
        mock_req.httprequest.method = 'GET'
        mock_req.httprequest.url = 'http://localhost:8069/test'
        mock_req.httprequest.headers = {}
        mock_req.httprequest.args = {}
        mock_req.httprequest.form = {}
        mock_req.httprequest.json = {}
        mock_req.session = Mock()
        mock_req.session.uid = 1
        mock_req.env = Mock()
        return mock_req

    @pytest.fixture
    def sample_json_data(self):
        """Provide sample JSON data for testing."""
        return {
            'name': 'Test Record',
            'email': 'test@example.com',
            'phone': '+1-555-0123',
            'active': True,
        }

    def assert_json_response(self, response_data: str, expected_data: Dict):
        """Assert that JSON response contains expected data."""
        try:
            actual_data = json.loads(response_data)
        except json.JSONDecodeError as e:
            pytest.fail(f"Invalid JSON response: {e}")

        for key, expected_value in expected_data.items():
            assert key in actual_data, f"Key {key} not found in response"
            assert (
                actual_data[key] == expected_value
            ), f"Response {key} should be {expected_value}, got {actual_data[key]}"

    def assert_response_status(self, response, expected_status: int):
        """Assert that response has expected status code."""
        if hasattr(response, 'status_code'):
            actual_status = response.status_code
        elif hasattr(response, 'status'):
            actual_status = response.status
        else:
            pytest.fail("Response object has no status code attribute")

        assert actual_status == expected_status, f"Response status should be {expected_status}, got {actual_status}"

    def assert_response_headers(self, response, expected_headers: Dict):
        """Assert that response contains expected headers."""
        if hasattr(response, 'headers'):
            headers = response.headers
        elif hasattr(response, 'header_list'):
            headers = dict(response.header_list)
        else:
            pytest.fail("Response object has no headers attribute")

        for header, expected_value in expected_headers.items():
            assert header in headers, f"Header {header} not found in response"
            assert (
                headers[header] == expected_value
            ), f"Header {header} should be {expected_value}, got {headers[header]}"

    def assert_error_response(self, response_data: str, error_message: str):
        """Assert that response contains an error message."""
        try:
            actual_data = json.loads(response_data)
        except json.JSONDecodeError:
            # If not JSON, check if error message is in raw response
            assert error_message in response_data, f"Error message '{error_message}' not found in response"
            return

        # Check common error response formats
        error_found = False
        for error_key in ['error', 'message', 'errors', 'detail']:
            if error_key in actual_data:
                error_content = str(actual_data[error_key])
                if error_message in error_content:
                    error_found = True
                    break

        assert error_found, f"Error message '{error_message}' not found in response: {actual_data}"


class BaseOdooControllerTest(HttpCase if ODOO_AVAILABLE else BaseControllerTest):
    """
    Base test class for Odoo controller testing with HTTP client.

    This class provides functionality for testing controllers with actual
    HTTP requests using Odoo's test client.
    """

    @classmethod
    def setUpClass(cls):
        """Set up class-level test data."""
        if ODOO_AVAILABLE:
            super().setUpClass()

    def setUp(self):
        """Set up individual test."""
        if ODOO_AVAILABLE:
            super().setUp()

        # Common test URLs
        self.base_url = '/web'
        self.api_url = '/api'
        self.test_endpoint = '/test'

    def authenticate_user(self, login: str = 'admin', password: str = 'admin'):
        """Authenticate a user for testing."""
        if not ODOO_AVAILABLE:
            return Mock()

        self.authenticate(login, password)
        return self.env.user

    def make_get_request(self, url: str, params: Dict = None) -> 'Response':
        """Make a GET request to the specified URL."""
        if not ODOO_AVAILABLE:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.text = '{"status": "success"}'
            mock_response.json.return_value = {"status": "success"}
            return mock_response

        return self.url_open(url, data=params)

    def make_post_request(self, url: str, data: Dict = None, json_data: Dict = None) -> 'Response':
        """Make a POST request to the specified URL."""
        if not ODOO_AVAILABLE:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.text = '{"status": "success"}'
            mock_response.json.return_value = {"status": "success"}
            return mock_response

        headers = {}
        if json_data:
            headers['Content-Type'] = 'application/json'
            data = json.dumps(json_data)

        return self.url_open(url, data=data, headers=headers)

    def make_put_request(self, url: str, data: Dict = None, json_data: Dict = None) -> 'Response':
        """Make a PUT request to the specified URL."""
        if not ODOO_AVAILABLE:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.text = '{"status": "success"}'
            mock_response.json.return_value = {"status": "success"}
            return mock_response

        headers = {}
        if json_data:
            headers['Content-Type'] = 'application/json'
            data = json.dumps(json_data)

        # Odoo's test client may not have direct PUT support
        # This is a simplified implementation
        return self.url_open(url, data=data, headers=headers)

    def make_delete_request(self, url: str) -> 'Response':
        """Make a DELETE request to the specified URL."""
        if not ODOO_AVAILABLE:
            mock_response = Mock()
            mock_response.status_code = 204
            mock_response.text = ''
            return mock_response

        # Odoo's test client may not have direct DELETE support
        # This is a simplified implementation
        return self.url_open(url)

    def assert_endpoint_exists(self, url: str):
        """Assert that an endpoint exists and returns a response."""
        response = self.make_get_request(url)
        # Don't assert 200 here as endpoints might require authentication
        # Just assert that we get some response (not 404)
        if hasattr(response, 'status_code'):
            assert response.status_code != 404, f"Endpoint {url} not found (404)"

    def assert_endpoint_requires_auth(self, url: str):
        """Assert that an endpoint requires authentication."""
        # First try without authentication
        if ODOO_AVAILABLE:
            # Clear any existing authentication
            self.session.logout()

        response = self.make_get_request(url)

        # Should get 401, 403, or redirect to login
        if hasattr(response, 'status_code'):
            assert response.status_code in [401, 403, 302], f"Endpoint {url} should require authentication"

    def assert_endpoint_accessible(self, url: str, user_login: str = 'admin'):
        """Assert that an endpoint is accessible to a specific user."""
        self.authenticate_user(user_login)
        response = self.make_get_request(url)

        # Should be able to access the endpoint
        if hasattr(response, 'status_code'):
            assert response.status_code in [200, 201], f"Endpoint {url} should be accessible to user {user_login}"

    def assert_json_api_response(self, url: str, expected_fields: List[str], method: str = 'GET', data: Dict = None):
        """Assert that a JSON API endpoint returns expected fields."""
        if method.upper() == 'GET':
            response = self.make_get_request(url, data)
        elif method.upper() == 'POST':
            response = self.make_post_request(url, json_data=data)
        else:
            pytest.fail(f"Unsupported HTTP method: {method}")

        self.assert_response_status(response, 200)

        try:
            response_data = json.loads(response.text)
        except (json.JSONDecodeError, AttributeError):
            if hasattr(response, 'json'):
                response_data = response.json()
            else:
                pytest.fail("Response is not valid JSON")

        for field in expected_fields:
            assert field in response_data, f"Field {field} not found in API response"


class BaseWebControllerTest(BaseOdooControllerTest):
    """
    Specialized base class for testing web controllers.
    """

    def setUp(self):
        """Set up web controller test environment."""
        super().setUp()
        self.web_base_url = '/web'

    def assert_web_page_loads(self, url: str):
        """Assert that a web page loads successfully."""
        response = self.make_get_request(url)
        self.assert_response_status(response, 200)

        # Check that we get HTML content
        content_type = None
        if hasattr(response, 'headers'):
            content_type = response.headers.get('Content-Type', '')

        if content_type:
            assert 'text/html' in content_type, f"Web page {url} should return HTML content"

    def assert_web_form_submission(self, url: str, form_data: Dict):
        """Assert that a web form can be submitted successfully."""
        response = self.make_post_request(url, data=form_data)

        # Successful form submission might return 200, 201, or 302 (redirect)
        if hasattr(response, 'status_code'):
            assert response.status_code in [
                200,
                201,
                302,
            ], f"Form submission to {url} failed with status {response.status_code}"

    def assert_ajax_endpoint(self, url: str, json_data: Dict = None):
        """Assert that an AJAX endpoint works correctly."""
        response = self.make_post_request(url, json_data=json_data)
        self.assert_response_status(response, 200)

        # AJAX endpoints should return JSON
        expected_headers = {'Content-Type': 'application/json'}
        self.assert_response_headers(response, expected_headers)


class BaseAPIControllerTest(BaseOdooControllerTest):
    """
    Specialized base class for testing API controllers.
    """

    def setUp(self):
        """Set up API controller test environment."""
        super().setUp()
        self.api_base_url = '/api/v1'

    def assert_api_crud_operations(self, base_url: str, create_data: Dict, update_data: Dict):
        """Test complete CRUD operations for an API endpoint."""
        # CREATE
        create_response = self.make_post_request(base_url, json_data=create_data)
        self.assert_response_status(create_response, 201)

        # Extract created record ID
        try:
            create_result = json.loads(create_response.text)
            record_id = create_result.get('id')
            assert record_id, "Created record should have an ID"
        except (json.JSONDecodeError, AttributeError):
            pytest.fail("Create response should contain valid JSON with ID")

        # READ
        read_url = f"{base_url}/{record_id}"
        read_response = self.make_get_request(read_url)
        self.assert_response_status(read_response, 200)

        # UPDATE
        update_response = self.make_put_request(read_url, json_data=update_data)
        self.assert_response_status(update_response, 200)

        # DELETE
        delete_response = self.make_delete_request(read_url)
        self.assert_response_status(delete_response, 204)

    def assert_api_error_handling(self, url: str, invalid_data: Dict, expected_status: int = 400):
        """Assert that API properly handles invalid data."""
        response = self.make_post_request(url, json_data=invalid_data)
        self.assert_response_status(response, expected_status)

        # API should return error details in JSON
        try:
            error_data = json.loads(response.text)
            assert 'error' in error_data or 'errors' in error_data, "API error response should contain error details"
        except (json.JSONDecodeError, AttributeError):
            pytest.fail("API error response should be valid JSON")

    def assert_api_pagination(self, url: str, page_size: int = 10):
        """Assert that API supports pagination."""
        # Test first page
        page1_response = self.make_get_request(url, params={'page': 1, 'limit': page_size})
        self.assert_response_status(page1_response, 200)

        try:
            page1_data = json.loads(page1_response.text)
            assert 'results' in page1_data or 'data' in page1_data, "Paginated API should return results/data field"
            assert 'total' in page1_data or 'count' in page1_data, "Paginated API should return total/count field"
        except (json.JSONDecodeError, AttributeError):
            pytest.fail("Paginated API response should be valid JSON")


# Example test classes showing usage
class ExampleWebControllerTest(BaseWebControllerTest):
    """
    Example test class demonstrating web controller testing.
    """

    @pytest.mark.database
    def test_home_page_loads(self):
        """Example test for home page loading."""
        if not ODOO_AVAILABLE:
            pytest.skip("Odoo not available")

        self.authenticate_user()
        self.assert_web_page_loads('/web')

    @pytest.mark.database
    def test_login_form_submission(self):
        """Example test for login form submission."""
        if not ODOO_AVAILABLE:
            pytest.skip("Odoo not available")

        form_data = {
            'login': 'admin',
            'password': 'admin',
        }
        self.assert_web_form_submission('/web/login', form_data)


class ExampleAPIControllerTest(BaseAPIControllerTest):
    """
    Example test class demonstrating API controller testing.
    """

    @pytest.mark.database
    def test_partner_api_endpoint(self):
        """Example test for partner API endpoint."""
        if not ODOO_AVAILABLE:
            pytest.skip("Odoo not available")

        self.authenticate_user()

        # Test that the endpoint exists and returns JSON
        expected_fields = ['name', 'email', 'phone']
        self.assert_json_api_response('/api/partners', expected_fields, method='GET')

    @pytest.mark.unit
    @pytest.mark.no_database
    def test_json_response_validation(self, sample_json_data):
        """Example unit test for JSON response validation."""
        response_data = json.dumps(sample_json_data)
        expected_data = {'name': 'Test Record', 'active': True}
        self.assert_json_response(response_data, expected_data)


# Controller testing utilities
def create_mock_response(status_code: int = 200, json_data: Dict = None, text: str = None) -> Mock:
    """Create a mock HTTP response for testing."""
    response = Mock()
    response.status_code = status_code

    if json_data:
        response.json.return_value = json_data
        response.text = json.dumps(json_data)
    elif text:
        response.text = text
    else:
        response.text = '{"status": "success"}'
        response.json.return_value = {"status": "success"}

    response.headers = {'Content-Type': 'application/json'}
    return response


def create_test_request(method: str = 'GET', url: str = '/test', data: Dict = None, headers: Dict = None) -> Mock:
    """Create a mock HTTP request for testing."""
    request = Mock()
    request.method = method.upper()
    request.url = url
    request.headers = headers or {}
    request.json = data or {}
    request.form = data or {}
    request.args = data or {}
    return request
