FROM elixir:1.10.3-alpine as releaser

ARG MIX_ENV
ENV HOME=/app

RUN apk add --no-cache build-base cmake git

RUN mix do local.hex --force, local.rebar --force

WORKDIR $HOME

COPY ./mix.exs ./mix.lock $HOME/
COPY ./config $HOME/config
RUN MIX_ENV=${MIX_ENV} mix do deps.get, deps.compile

COPY ./priv $HOME/priv
COPY ./rel $HOME/rel
COPY ./lib $HOME/lib
RUN MIX_ENV=${MIX_ENV} mix do compile, release

########################################################################
FROM alpine:edge

ARG MIX_ENV
ENV LANG=en_US.UTF-8 \
  HOME=/app \
  REPLACE_OS_VARS=true \
  SHELL=/bin/sh \
  APP=what_you_listen \
  V=0.1.0

RUN apk add --no-cache bash ncurses-libs openssl 'tesseract-ocr=4.1.1-r3'
ADD https://github.com/tesseract-ocr/tessdata_best/raw/master/eng.traineddata /usr/share/tessdata/eng.traineddata
ADD https://github.com/tesseract-ocr/tessdata_best/raw/master/rus.traineddata /usr/share/tessdata/rus.traineddata

WORKDIR $HOME

COPY --from=releaser $HOME/rel/$APP $HOME

ENTRYPOINT ["/app/bin/what_you_listen"]
CMD ["start"]
