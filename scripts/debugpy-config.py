#!/usr/bin/env python3
"""
Debugpy Configuration Helper for Odoo Development

This script helps configure debugpy in Odoo code for remote debugging.
Usage examples:

1. Add to your Odoo module __init__.py:
   from scripts.debugpy_config import start_debugpy
   start_debugpy()

2. Add breakpoint in your code:
   from scripts.debugpy_config import debug_here
   debug_here()
"""

import os
import sys


def start_debugpy(port=5678, wait_for_client=False):
    """
    Start debugpy server for remote debugging

    Args:
        port (int): Port to listen on (default: 5678)
        wait_for_client (bool): Whether to wait for client before continuing
    """
    try:
        import debugpy

        # Check if debugpy is already listening
        if not debugpy.is_client_connected():
            print(f"🐛 Starting debugpy on port {port}")
            debugpy.listen(("0.0.0.0", port))

            if wait_for_client:
                print("⏳ Waiting for debugger client to attach...")
                debugpy.wait_for_client()
                print("🔗 Debugger client attached!")
        else:
            print("🔗 Debugpy client already connected")

    except ImportError:
        print("❌ debugpy not installed. Run: pip install debugpy")
    except Exception as e:
        print(f"❌ Failed to start debugpy: {e}")


def debug_here(port=5678):
    """
    Set a breakpoint at this location and start debugpy if not already running

    Args:
        port (int): Port to listen on (default: 5678)
    """
    start_debugpy(port, wait_for_client=False)

    try:
        import debugpy

        debugpy.breakpoint()
        print("🔍 Breakpoint set - debugger should pause here")
    except ImportError:
        print("❌ debugpy not available for breakpoint")


def is_debugging():
    """Check if we're currently in a debugging session"""
    try:
        import debugpy

        return debugpy.is_client_connected()
    except ImportError:
        return False


# Auto-start debugpy in development mode
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Start debugpy server")
    parser.add_argument("--port", type=int, default=5678, help="Port to listen on")
    parser.add_argument("--wait", action="store_true", help="Wait for client to attach")

    args = parser.parse_args()
    start_debugpy(args.port, args.wait)
