#ARG IMG_VERSION=6.0-alpine
#FROM mcr.microsoft.com/dotnet/runtime:$IMG_VERSION
### START OF REMOVE WHEN NEW MS IMG IS OUT
FROM alpine:3.16

LABEL maintainer="JJTC <oci@jjtc.eu>"

RUN apk add --no-cache \
        ca-certificates \
        \
        # .NET dependencies
        icu-libs \
        krb5-libs \
        libgcc \
        libintl \
        libssl1.1 \
        libstdc++ \
        zlib

# Install .NET SDK
RUN wget -O dotnet.tar.gz https://dotnetcli.blob.core.windows.net/dotnet/Sdk/6.0.300/dotnet-sdk-6.0.300-linux-musl-x64.tar.gz \
    && mkdir -p /usr/share/dotnet \
    && tar -C /usr/share/dotnet -oxzf dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

### END OF REMOVE WHEN NEW MS IMG IS OUT

ARG ddler_ver=2.4.6
ENV WINEPREFIX=/home/steam/wine/ \
    WINEARCH=win64

# Get and setup DepotDownloader
RUN mkdir /usr/share/ddler \
    && cd /usr/share/ddler \
    && wget https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_$ddler_ver/depotdownloader-$ddler_ver.zip \
    && unzip depotdownloader-$ddler_ver.zip \
    && rm depotdownloader-$ddler_ver.zip \
    && echo "#!/usr/bin/env sh" > /usr/bin/ddler \
    && echo "dotnet /usr/share/ddler/DepotDownloader.dll \"\$@\"" >> /usr/bin/ddler \
    && chmod +x /usr/bin/ddler \
    # Install Wine + deps and Xvfb
    && apk add --no-cache wine gnutls xvfb xvfb-run \
    # Create steam group and user
    && addgroup -S steam \
    && adduser -D steam -G steam \
    # Create wineprefix folder and set owner
    && mkdir /home/steam/wine \
    && chown steam /home/steam/wine

# Switch to steam user
USER steam

WORKDIR /home/steam

ENTRYPOINT [ "echo", "Use https://steamdb.info/search/?a=app&q=server or https://developer.valvesoftware.com/wiki/Dedicated_Servers_List to find the appid.\n\n\
# Examples of installing an app:\n\
\n\
- Conan Exiles Dedicated Server for Windows\n\
    ddler -app 443030 -os windows -dir conanexiles/ -validate" ]

CMD [ "ddler", "$@" ]
