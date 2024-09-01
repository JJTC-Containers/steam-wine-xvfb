ARG IMG_VERSION=8.0-alpine
FROM mcr.microsoft.com/dotnet/sdk:$IMG_VERSION AS builder

ARG ddler_ver=2.7.1

RUN cd /tmp && \
    wget https://github.com/SteamRE/DepotDownloader/archive/refs/tags/DepotDownloader_$ddler_ver.tar.gz && \
    tar -xzf DepotDownloader_$ddler_ver.tar.gz && \
    rm DepotDownloader_$ddler_ver.tar.gz && \
    mv DepotDownloader-DepotDownloader_$ddler_ver DepotDownloader && \
    cd DepotDownloader && \
    dotnet publish DepotDownloader/DepotDownloader.csproj \
        --framework "net8.0" \
        --no-self-contained \
        -p:PublishSingleFile=true \
        -p:DebugType=embedded \
        --use-current-runtime \
        --configuration Release \
        --output publish


FROM mcr.microsoft.com/dotnet/runtime:$IMG_VERSION

LABEL maintainer="JJTC <oci@jjtc.eu>"

RUN apk add --no-cache ca-certificates

COPY --from=builder /tmp/DepotDownloader/publish/DepotDownloader /usr/local/bin/depotdownloader

ENV WINEPREFIX=/home/steam/wine/ \
    WINEARCH=win64

# Install Wine + deps and Xvfb
RUN apk add --no-cache wine gnutls xvfb xvfb-run tzdata && \
    # Create steam group and user
    addgroup -g 10001 -S steam && \
    adduser -u 10000 -D steam -G steam && \
    # Create wineprefix folder and set owner
    mkdir /home/steam/wine && \
    chown steam /home/steam/wine

# Switch to steam user
USER steam

WORKDIR /home/steam

ENTRYPOINT [ "echo", "Use https://steamdb.info/search/?a=app&q=server or https://developer.valvesoftware.com/wiki/Dedicated_Servers_List to find the appid.\n\n\
# Examples of installing an app:\n\
\n\
- Conan Exiles Dedicated Server for Windows\n\
    depotdownloader -app 443030 -os windows -dir conanexiles/ -validate" ]

CMD [ "depotdownloader", "$@" ]
