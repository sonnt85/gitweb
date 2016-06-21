#
## Copyright:: Copyright (c) 2016 GitLab Inc
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

name "haproxy"
default_version "1.6.5"


source url: "http://www.haproxy.org/download/1.6/src/haproxy-#{version}.tar.gz",
       sha256: "c4b3fb938874abbbbd52782087117cc2590263af78fdce86d64e4a11acfe85de"

dependency "pcre"
dependency "openssl"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  env['TARGET'] = "generic"
  env['USE_PCRE'] = 1
  env['USE_OPENSSL'] = 1
  env['USE_ZLIB'] = 1

  command "./config --prefix=#{install_dir}/embedded"
  make "-j #{workers}", env: env
  make "install -j #{workers}", env: env
end
