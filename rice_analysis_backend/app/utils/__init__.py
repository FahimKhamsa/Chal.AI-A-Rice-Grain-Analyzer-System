"""
app/utils/__init__.py
----------------------
General-purpose helper utilities.

Add logging configuration, custom formatters, performance timers, etc. here.
"""
import logging
import sys


def configure_logging(level: str = "INFO") -> None:
    """
    Set up a structured console logger for the application.

    Args:
        level: Logging level string (DEBUG, INFO, WARNING, ERROR, CRITICAL).
    """
    logging.basicConfig(
        stream=sys.stdout,
        level=getattr(logging, level.upper(), logging.INFO),
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
