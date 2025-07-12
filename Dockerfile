# Odoo Local Testing Framework - Odoo 18.0 Docker Environment
#
# This Dockerfile creates an Odoo 18.0 environment for testing and validating custom modules
# with comprehensive development and testing tools

FROM python:3.11-slim-bullseye

# Metadata
LABEL maintainer="Odoo Local Testing Framework"
LABEL description="Odoo 18.0 development environment for module testing and validation"
LABEL version="18.0.1.0.0"

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ODOO_VERSION=18.0
ENV ODOO_USER=odoo
ENV ODOO_UID=1001
ENV ODOO_GID=1001
ENV ODOO_HOME=/opt/odoo
ENV ODOO_PATH=/opt/odoo/odoo
ENV ADDONS_PATH=/opt/odoo/addons
ENV CUSTOM_MODULES_PATH=/opt/odoo/custom_modules
ENV CONFIG_PATH=/etc/odoo
ENV LOGS_PATH=/var/log/odoo
ENV DATA_PATH=/var/lib/odoo

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Core system tools
    curl \
    wget \
    git \
    build-essential \
    # PostgreSQL client and development libraries
    postgresql-client \
    libpq-dev \
    # Python development dependencies
    python3-dev \
    python3-pip \
    python3-wheel \
    python3-setuptools \
    # Odoo system dependencies
    libxml2-dev \
    libxslt1-dev \
    libldap2-dev \
    libsasl2-dev \
    libtiff5-dev \
    libjpeg62-turbo-dev \
    libopenjp2-7-dev \
    zlib1g-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libwebp-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libxcb1-dev \
    # Additional tools for development
    vim \
    less \
    htop \
    tree \
    # Fonts for PDF generation
    fonts-noto-cjk \
    fonts-dejavu-core \
    fonts-freefont-ttf \
    fonts-liberation \
    # Node.js and npm for web assets
    nodejs \
    npm \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create odoo user and group
RUN groupadd -g $ODOO_GID $ODOO_USER \
    && useradd -u $ODOO_UID -g $ODOO_GID -d $ODOO_HOME -m -s /bin/bash $ODOO_USER

# Create necessary directories with proper permissions
RUN mkdir -p \
    $ODOO_HOME \
    $ODOO_PATH \
    $ADDONS_PATH \
    $CUSTOM_MODULES_PATH \
    $CONFIG_PATH \
    $LOGS_PATH \
    $DATA_PATH \
    /opt/odoo/backups \
    /opt/odoo/scripts \
    && chown -R $ODOO_USER:$ODOO_USER /opt/odoo \
    && chown -R $ODOO_USER:$ODOO_USER $LOGS_PATH \
    && chown -R $ODOO_USER:$ODOO_USER $DATA_PATH \
    && chmod 755 $CONFIG_PATH

# Switch to odoo user for installation
USER $ODOO_USER
WORKDIR $ODOO_HOME

# Clone Odoo 18.0 (matching our local installation)
RUN git clone --depth 1 --branch $ODOO_VERSION https://github.com/odoo/odoo.git $ODOO_PATH

# Create Python virtual environment
RUN python3 -m venv $ODOO_HOME/venv

# Activate virtual environment and install Python dependencies
RUN . $ODOO_HOME/venv/bin/activate \
    && pip install --upgrade pip wheel setuptools \
    && pip install -r $ODOO_PATH/requirements.txt \
    && pip install \
        # Development and testing tools (matching local installation)
        debugpy \
        pytest \
        coverage \
        pylint-odoo \
        black \
        isort \
        flake8 \
        mypy \
        # Additional utilities
        ipython \
        psycopg2-binary

# Copy our scripts and tools (integrate with existing infrastructure)
COPY --chown=$ODOO_USER:$ODOO_USER scripts/ /opt/odoo/scripts/
COPY --chown=$ODOO_USER:$ODOO_USER Makefile /opt/odoo/

# Make scripts executable
RUN chmod +x /opt/odoo/scripts/*.sh

# Create docker-specific configuration directory
RUN mkdir -p $ODOO_HOME/docker-configs

# Switch back to root for final setup
USER root

# Create docker entrypoint script
COPY --chown=$ODOO_USER:$ODOO_USER docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create health check script
RUN echo '#!/bin/bash\ncurl -f http://localhost:8069/web/health || exit 1' > /usr/local/bin/healthcheck.sh \
    && chmod +x /usr/local/bin/healthcheck.sh

# Set up environment variables for Docker
ENV PATH="$ODOO_HOME/venv/bin:$PATH"
ENV PYTHONPATH="$ODOO_PATH:$PYTHONPATH"

# Expose ports
EXPOSE 8069 8072

# Volume mount points
VOLUME ["$CUSTOM_MODULES_PATH", "$DATA_PATH", "$LOGS_PATH", "/opt/odoo/backups"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Switch back to odoo user
USER $ODOO_USER

# Working directory
WORKDIR $ODOO_HOME

# Default command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["odoo"]
