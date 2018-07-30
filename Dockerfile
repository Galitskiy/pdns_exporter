FROM golang:1.10 as builder
ENV PACKAGE_PATH $GOPATH/src/git.host/mypackage
RUN mkdir -p  $PACKAGE_PATH
COPY . $PACKAGE_PATH
WORKDIR $PACKAGE_PATH
ARG version_string
ARG binary_name
ENV BINARY_NAME $binary_name
RUN make build && cp ${binary_name} /${binary_name}

FROM ruby:2.3
RUN  gem install --quiet --no-document fpm

ARG binary_name
ARG deb_package_name
ARG version_string
ARG deb_package_description
ARG pkg_vendor
ARG pkg_maintainer
ARG pkg_url

RUN mkdir /deb-package
COPY --from=builder /$binary_name /deb-package/
RUN mkdir dpkg-sources
COPY dpkg-sources/prometheus-pdns-exporter.service dpkg-sources/prometheus-pdns-exporter /dpkg-sources/
WORKDIR dpkg-sources
RUN fpm --output-type deb \
  --input-type dir --chdir /deb-package \
  --prefix /usr/bin --name $binary_name \
  --version $version_string \
  --description "${deb_package_description}" \
  --vendor "${pkg_vendor}" \
  --maintainer "${pkg_maintainer}" \
  --url "${pkg_url}" \
  --deb-systemd "prometheus-pdns-exporter.service" \
  --deb-default "prometheus-pdns-exporter" \
  -p ${deb_package_name}-${version_string}.deb \
  $binary_name && cp *.deb /deb-package/
