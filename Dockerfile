FROM perl:5.36-bullseye AS build

ENV APP_HOME=/app
WORKDIR ${APP_HOME}

# System deps for building, packing, and staticx
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        cpanminus \
        python3 \
        python3-pip \
        musl-tools \
        patchelf \
        binutils; \
    rm -rf /var/lib/apt/lists/*

# Perl dependencies for Asciiquarium
RUN cpanm --notest Curses PAR::Packer

# Bring in project sources
COPY Asciiquarium.pm ${APP_HOME}/Asciiquarium.pm
COPY Animation.pm ${APP_HOME}/Animation.pm
COPY Entity.pm ${APP_HOME}/Entity.pm

# Term::Animation expects a module layout; install the provided sources
RUN set -eux; \
    install -d ${APP_HOME}/lib/Term/Animation; \
    install -m 644 Animation.pm ${APP_HOME}/lib/Term/Animation.pm; \
    install -m 644 Entity.pm ${APP_HOME}/lib/Term/Animation/Entity.pm

# Build the PAR binary; force inclusion of modules that the runtime
# discovers dynamically (e.g., File::Temp) so the final binary stands alone.
RUN pp \
      -I lib \
      -M Term::Animation \
      -M Term::Animation::Entity \
      -M File::Temp \
      -o asciiquarium_dynamic \
      Asciiquarium.pm

# Wrap with staticx to get a fully static self-extracting binary, then strip it
RUN pip3 install --no-cache-dir staticx && \
    staticx asciiquarium_dynamic asciiquarium_static && \
    strip asciiquarium_static

FROM busybox:1.36.1-uclibc AS artifact
COPY --from=build /app/asciiquarium_static /asciiquarium_static
ENTRYPOINT ["/bin/sh"]
