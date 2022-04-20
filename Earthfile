VERSION 0.6
FROM ubuntu:20.04

shared:
    FROM scratch

    COPY .rubocop.yml .
    SAVE ARTIFACT .rubocop.yml

    COPY .gitignore .
    SAVE ARTIFACT .gitignore

deps:
    ARG DEBIAN_FRONTEND="noninteractive"

    RUN apt-get update \
     && apt-get upgrade -y \
     && apt-get install -y --no-install-recommends \
            build-essential \
            dirmngr \
            git \
            bzr \
            mercurial \
            gnupg2 \
            ca-certificates \
            curl \
            file \
            zlib1g-dev \
            liblzma-dev \
            tzdata \
            zip \
            unzip \
            openssh-client \
            software-properties-common \
            make \
     && rm -rf /var/lib/apt/lists/*

docker:
    FROM +deps

    LABEL org.opencontainers.image.title="dependabot-core"
    LABEL org.opencontainers.image.source="https://github.com/dependabot/dependabot-core"
    LABEL org.opencontainers.image.created="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    LABEL org.opencontainers.image.revision="$(git rev-parse HEAD)"
    LABEL org.opencontainers.image.version="$(git describe --tags --abbrev=0)"

    ARG development
    ARG tag="latest"

    ENV DEPENDABOT_NATIVE_HELPERS_PATH="${DEPENDABOT_NATIVE_HELPERS_PATH:-/opt}"

    DO ./bundler+SETUP
    DO ./python+SETUP
    DO ./npm_and_yarn+SETUP

    # Elm is amd64 only, see:
    # - https://github.com/elm/compiler/issues/2007
    # - https://github.com/elm/compiler/issues/2232
    IF  [ "$TARGETARCH" == "amd64" ]
        DO ./elm+SETUP
    END

    DO ./composer+SETUP
    DO ./go_modules+SETUP
    DO ./hex+SETUP
    DO ./cargo+SETUP
    DO ./terraform+SETUP
    DO ./pub+SETUP

    DO ./common+CREATE_DEPENDABOT_USER

    COPY --chown=dependabot:dependabot LICENSE /home/dependabot

    WORKDIR /home/dependabot/dependabot-core

    COPY --chown=dependabot:dependabot --dir \
            omnibus \
            git_submodules \
            terraform \
            github_actions \
            hex \
            elm \
            docker \
            nuget \
            maven \
            gradle \
            cargo \
            composer \
            go_modules \
            python \
            pub \
            npm_and_yarn \
            bundler \
            common \
            .

    USER dependabot

    ENV HOME="/home/dependabot"
    WORKDIR ${HOME}

    ENTRYPOINT ["/bin/sh"]

    IF [ $development ]
        USER root

        RUN apt-get update \
         && apt-get install -y \
                vim \
                strace \
                ltrace \
                gdb \
                shellcheck \
         && rm -rf /var/lib/apt/lists/*
  
        USER dependabot

        DO ./common/+CONFIGURE_GIT_USER

        ENV LOCAL_GITHUB_ACCESS_TOKEN=""
        ENV LOCAL_CONFIG_VARIABLES=""

        SAVE IMAGE --push "dependabot/dependabot-core-development:$tag"
    ELSE
        SAVE IMAGE --push "dependabot/dependabot-core:$tag"
    END
