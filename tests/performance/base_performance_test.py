"""
Base Performance Test Class for Royal Textiles Sales Module

This module provides comprehensive performance testing infrastructure for Odoo,
including timing, memory monitoring, CPU usage tracking, and benchmark utilities.
"""

import gc
import statistics
import time
from contextlib import contextmanager
from typing import Any, Callable, Dict, List, Optional
from unittest.mock import patch

import psutil

from odoo.tests.common import TransactionCase, tagged
from odoo.tools import mute_logger


class PerformanceMetrics:
    """Container for performance measurement results"""

    def __init__(self):
        self.execution_time: float = 0.0
        self.memory_usage: Dict[str, float] = {}
        self.cpu_usage: float = 0.0
        self.database_queries: int = 0
        self.sql_time: float = 0.0
        self.custom_metrics: Dict[str, Any] = {}

    def to_dict(self) -> Dict[str, Any]:
        """Convert metrics to dictionary for reporting"""
        return {
            'execution_time': self.execution_time,
            'memory_usage': self.memory_usage,
            'cpu_usage': self.cpu_usage,
            'database_queries': self.database_queries,
            'sql_time': self.sql_time,
            'custom_metrics': self.custom_metrics,
        }


class PerformanceThresholds:
    """Performance threshold definitions for different operations"""

    # Database operation thresholds (seconds)
    SINGLE_CREATE_MAX = 0.1
    SINGLE_READ_MAX = 0.05
    SINGLE_UPDATE_MAX = 0.1
    SINGLE_DELETE_MAX = 0.05

    # Bulk operation thresholds (seconds)
    BULK_CREATE_100_MAX = 2.0
    BULK_UPDATE_100_MAX = 1.5
    BULK_DELETE_100_MAX = 1.0

    # Search operation thresholds (seconds)
    SIMPLE_SEARCH_MAX = 0.2
    COMPLEX_SEARCH_MAX = 1.0
    FILTERED_SEARCH_MAX = 0.5

    # View rendering thresholds (seconds)
    FORM_VIEW_RENDER_MAX = 0.3
    LIST_VIEW_RENDER_MAX = 0.5
    KANBAN_VIEW_RENDER_MAX = 0.4

    # Memory thresholds (MB)
    MEMORY_GROWTH_MAX = 50.0
    TOTAL_MEMORY_MAX = 500.0

    # Query count thresholds
    SINGLE_OPERATION_QUERIES_MAX = 5
    BULK_OPERATION_QUERIES_MAX = 10


@tagged('performance')
class BasePerformanceTest(TransactionCase):
    """
    Base class for performance testing in Odoo

    Provides utilities for:
    - Execution time measurement
    - Memory usage monitoring
    - CPU usage tracking
    - Database query counting
    - Performance threshold validation
    - Benchmark reporting
    """

    @classmethod
    def setUpClass(cls):
        """Set up performance testing environment"""
        super().setUpClass()
        cls.performance_results: List[Dict[str, Any]] = []
        cls.thresholds = PerformanceThresholds()

        # Get initial memory baseline
        process = psutil.Process()
        cls.baseline_memory = process.memory_info().rss / 1024 / 1024  # MB

    def setUp(self):
        """Set up each performance test"""
        super().setUp()
        self.test_start_time = time.time()

        # Force garbage collection for clean measurement
        gc.collect()

        # Get process for monitoring
        self.process = psutil.Process()

        # Reset query counter
        self.query_count = 0
        self.sql_time = 0.0

    @contextmanager
    def measure_performance(self, operation_name: str) -> PerformanceMetrics:
        """
        Context manager for measuring performance of operations

        Usage:
            with self.measure_performance('create_customer') as metrics:
                # Perform operation
                customer = self.env['res.partner'].create({...})

            # metrics now contains performance data
        """
        metrics = PerformanceMetrics()

        # Capture initial state
        start_time = time.perf_counter()
        start_memory = self.process.memory_info().rss / 1024 / 1024
        start_cpu = self.process.cpu_percent()
        start_queries = self.query_count
        start_sql_time = self.sql_time

        # Force garbage collection before measurement
        gc.collect()

        try:
            yield metrics
        finally:
            # Capture final state
            end_time = time.perf_counter()
            end_memory = self.process.memory_info().rss / 1024 / 1024
            end_cpu = self.process.cpu_percent()

            # Calculate metrics
            metrics.execution_time = end_time - start_time
            metrics.memory_usage = {
                'start_mb': start_memory,
                'end_mb': end_memory,
                'growth_mb': end_memory - start_memory,
            }
            metrics.cpu_usage = max(end_cpu - start_cpu, 0)
            metrics.database_queries = self.query_count - start_queries
            metrics.sql_time = self.sql_time - start_sql_time

            # Store results for reporting
            result = {'operation': operation_name, 'timestamp': time.time(), 'metrics': metrics.to_dict()}
            self.performance_results.append(result)

    def benchmark_function(self, func: Callable, iterations: int = 10, warmup: int = 2) -> Dict[str, float]:
        """
        Benchmark a function with multiple iterations

        Args:
            func: Function to benchmark
            iterations: Number of iterations to run
            warmup: Number of warmup iterations (not counted)

        Returns:
            Dictionary with timing statistics
        """
        times = []

        # Warmup iterations
        for _ in range(warmup):
            func()

        # Measured iterations
        for _ in range(iterations):
            start_time = time.perf_counter()
            func()
            end_time = time.perf_counter()
            times.append(end_time - start_time)

        return {
            'mean': statistics.mean(times),
            'median': statistics.median(times),
            'min': min(times),
            'max': max(times),
            'std_dev': statistics.stdev(times) if len(times) > 1 else 0,
            'iterations': iterations,
        }

    def assert_performance_threshold(self, metrics: PerformanceMetrics, threshold_seconds: float, operation_name: str):
        """Assert that execution time is within threshold"""
        self.assertLess(
            metrics.execution_time,
            threshold_seconds,
            f"{operation_name} took {metrics.execution_time:.3f}s, " f"threshold is {threshold_seconds}s",
        )

    def assert_memory_threshold(self, metrics: PerformanceMetrics, max_growth_mb: float, operation_name: str):
        """Assert that memory growth is within threshold"""
        growth = metrics.memory_usage.get('growth_mb', 0)
        self.assertLess(
            growth, max_growth_mb, f"{operation_name} memory growth {growth:.1f}MB, " f"threshold is {max_growth_mb}MB"
        )

    def assert_query_threshold(self, metrics: PerformanceMetrics, max_queries: int, operation_name: str):
        """Assert that database query count is within threshold"""
        self.assertLessEqual(
            metrics.database_queries,
            max_queries,
            f"{operation_name} executed {metrics.database_queries} queries, " f"threshold is {max_queries}",
        )

    def create_test_data_bulk(self, model_name: str, count: int, data_factory: Callable) -> None:
        """Create bulk test data efficiently"""
        with self.measure_performance(f'bulk_create_{model_name}_{count}'):
            records = []
            for i in range(count):
                records.append(data_factory(i))
            self.env[model_name].create(records)

    def simulate_user_load(self, operations: List[Callable], concurrent_users: int = 5) -> Dict[str, Any]:
        """
        Simulate multiple concurrent users performing operations

        Note: This is a simplified simulation for single-threaded testing
        """
        results = []

        for user_id in range(concurrent_users):
            user_results = []
            for operation in operations:
                start_time = time.perf_counter()
                operation()
                end_time = time.perf_counter()
                user_results.append(end_time - start_time)
            results.append(user_results)

        # Calculate aggregate statistics
        all_times = [time for user_times in results for time in user_times]
        return {
            'concurrent_users': concurrent_users,
            'total_operations': len(all_times),
            'mean_response_time': statistics.mean(all_times),
            'max_response_time': max(all_times),
            'min_response_time': min(all_times),
            'std_dev': statistics.stdev(all_times) if len(all_times) > 1 else 0,
        }

    def profile_database_queries(self, operation: Callable) -> Dict[str, Any]:
        """Profile database queries executed during an operation"""
        initial_query_count = self.query_count
        initial_sql_time = self.sql_time

        start_time = time.perf_counter()
        operation()
        end_time = time.perf_counter()

        return {
            'execution_time': end_time - start_time,
            'query_count': self.query_count - initial_query_count,
            'sql_time': self.sql_time - initial_sql_time,
            'avg_query_time': ((self.sql_time - initial_sql_time) / max(1, self.query_count - initial_query_count)),
        }

    def generate_performance_report(self) -> str:
        """Generate a human-readable performance report"""
        if not self.performance_results:
            return "No performance data collected"

        report = ["Performance Test Results", "=" * 50]

        for result in self.performance_results:
            operation = result['operation']
            metrics = result['metrics']

            report.append(f"\nOperation: {operation}")
            report.append(f"  Execution Time: {metrics['execution_time']:.3f}s")
            report.append(f"  Memory Growth: {metrics['memory_usage']['growth_mb']:.1f}MB")
            report.append(f"  Database Queries: {metrics['database_queries']}")
            report.append(f"  SQL Time: {metrics['sql_time']:.3f}s")

            if metrics['custom_metrics']:
                report.append("  Custom Metrics:")
                for key, value in metrics['custom_metrics'].items():
                    report.append(f"    {key}: {value}")

        return "\n".join(report)

    @classmethod
    def tearDownClass(cls):
        """Clean up after all performance tests"""
        super().tearDownClass()

        # Generate final performance report
        if hasattr(cls, 'performance_results') and cls.performance_results:
            print("\n" + "=" * 60)
            print("PERFORMANCE TEST SUMMARY")
            print("=" * 60)

            for result in cls.performance_results[-10:]:  # Show last 10 results
                operation = result['operation']
                metrics = result['metrics']
                print(
                    f"{operation}: {metrics['execution_time']:.3f}s, "
                    f"{metrics['database_queries']} queries, "
                    f"{metrics['memory_usage']['growth_mb']:.1f}MB growth"
                )

            print("=" * 60)
