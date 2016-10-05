#
# Copyright:: Copyright (c) 2016 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative 'nginx.rb'

module GitlabMattermost
  class << self
    def parse_variables
      parse_mattermost_external_url
      parse_gitlab_mattermost
      parse_gitlab_commands
    end

    def parse_mattermost_external_url
      return unless Gitlab['mattermost_external_url']

      Gitlab['mattermost']['enable'] = true if Gitlab['mattermost']['enable'].nil?

      uri = URI(Gitlab['mattermost_external_url'].to_s)

      unless uri.host
        raise "GitLab Mattermost external URL must include a schema and FQDN, e.g. http://mattermost.example.com/"
      end

      Gitlab['mattermost']['host'] = uri.host

      case uri.scheme
      when "http"
        Gitlab['mattermost']['service_use_ssl'] = false
        Nginx.parse_proxy_headers('mattermost_nginx', false)
      when "https"
        Gitlab['mattermost']['service_use_ssl'] = true
        Gitlab['mattermost_nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{uri.host}.crt"
        Gitlab['mattermost_nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{uri.host}.key"
        Nginx.parse_proxy_headers('mattermost_nginx', true)
      else
        raise "Unsupported external URL scheme: #{uri.scheme}"
      end

      unless ["", "/"].include?(uri.path)
        raise "Unsupported CI external URL path: #{uri.path}"
      end

      Gitlab['mattermost']['port'] = uri.port
    end

    def parse_gitlab_mattermost
      return unless Gitlab['mattermost']['enable']

      Gitlab['mattermost_nginx']['enable'] = true if Gitlab['mattermost_nginx']['enable'].nil?
    end

    def parse_gitlab_commands
      return unless Gitlab['external_url']
      return unless Gitlab['mattermost']['enable']
      return unless Gitlab['mattermost']['gitlab_commands_enable']

      gitlab_url = Gitlab['external_url'].chomp("/")
      commands_endpoint = Gitlab['mattermost']['gitlab_commands_endpoint'] || "#{gitlab_url}/commands/trigger"
      commands_secret = Gitlab['mattermost']['gitlab_commands_secret']

      Gitlab['mattermost']['commands'] ||= []

      Gitlab['mattermost']['commands'] += [
        {
          Token: commands_secret,
          URL: gitlab_url,
          Trigger: '/deploy',
          Method: 'POST',
          AutoComplete: true,
          AutCompleteDesc: 'easily deploy from one to another environment',
          AutCompleteHint: '/deploy <environment> to <action>'
        },
        {
          Token: commands_secret,
          URL: gitlab_url,
          Trigger: '/issue',
          Method: 'POST',
          AutoComplete: true,
          AutCompleteDesc: 'easily search or create issues',
          AutCompleteHint: '/issue create|search string'
        },
        {
          Token: commands_secret,
          URL: gitlab_url,
          Trigger: '/merge_request',
          Method: 'POST',
          AutoComplete: true,
          AutCompleteDesc: 'easily search merge requests',
          AutCompleteHint: '/merge_request search string'
        }
      ]
    end
  end
end
