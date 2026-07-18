FROM rocker/r-ver:4.6.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    git \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libnode-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff5-dev \
    libglpk40 \
    libglpk-dev \
    libjq-dev \
    libuv1-dev \
    libx11-dev \
    cmake \
    pandoc \
    wget \
    && rm -rf /var/lib/apt/lists/*

ARG QUARTO_VERSION=1.9.37
RUN arch="$(dpkg --print-architecture)" \
    && case "$arch" in amd64|arm64) ;; *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; esac \
    && wget -q "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-${arch}.deb" \
    && dpkg -i "quarto-${QUARTO_VERSION}-linux-${arch}.deb" \
    && rm "quarto-${QUARTO_VERSION}-linux-${arch}.deb"

RUN quarto install tinytex --no-prompt

WORKDIR /app

ENV RENV_PATHS_CACHE=/renv/cache

COPY renv.lock .Rprofile ./
COPY renv/ renv/
RUN R -e "install.packages('renv'); renv::restore(prompt = FALSE)"

COPY . .

ARG GIT_COMMIT=unknown
ENV CAMTRAP_WORKFLOW_GIT_COMMIT=${GIT_COMMIT}

CMD ["Rscript", "-e", "targets::tar_make(callr_function = NULL)"]
