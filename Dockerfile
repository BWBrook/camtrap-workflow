FROM rocker/r-ver:4.5.2

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
    libpng-dev \
    libjpeg-dev \
    libtiff5-dev \
    libglpk40 \
    libglpk-dev \
    libjq-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

ARG QUARTO_VERSION=1.5.57
RUN wget -q "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb" \
    && dpkg -i "quarto-${QUARTO_VERSION}-linux-amd64.deb" \
    && rm "quarto-${QUARTO_VERSION}-linux-amd64.deb"

RUN quarto install tinytex --no-prompt

WORKDIR /app

ENV RENV_PATHS_CACHE=/renv/cache

COPY renv.lock renv/ .Rprofile ./
RUN R -e "install.packages('renv'); renv::restore(prompt = FALSE)"

COPY . .

CMD ["Rscript", "-e", "targets::tar_make(callr_function = NULL)"]
