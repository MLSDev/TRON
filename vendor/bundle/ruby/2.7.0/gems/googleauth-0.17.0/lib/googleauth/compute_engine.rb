# Copyright 2015, Google Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "faraday"
require "googleauth/signet"
require "memoist"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    NO_METADATA_SERVER_ERROR = <<~ERROR.freeze
      Error code 404 trying to get security access token
      from Compute Engine metadata for the default service account. This
      may be because the virtual machine instance does not have permission
      scopes specified.
    ERROR
    UNEXPECTED_ERROR_SUFFIX = <<~ERROR.freeze
      trying to get security access token from Compute Engine metadata for
      the default service account
    ERROR

    # Extends Signet::OAuth2::Client so that the auth token is obtained from
    # the GCE metadata server.
    class GCECredentials < Signet::OAuth2::Client
      # The IP Address is used in the URIs to speed up failures on non-GCE
      # systems.
      DEFAULT_METADATA_HOST = "169.254.169.254".freeze

      # @private Unused and deprecated
      COMPUTE_AUTH_TOKEN_URI =
        "http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token".freeze
      # @private Unused and deprecated
      COMPUTE_ID_TOKEN_URI =
        "http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/identity".freeze
      # @private Unused and deprecated
      COMPUTE_CHECK_URI = "http://169.254.169.254".freeze

      class << self
        extend Memoist

        def metadata_host
          ENV.fetch "GCE_METADATA_HOST", DEFAULT_METADATA_HOST
        end

        def compute_check_uri
          "http://#{metadata_host}".freeze
        end

        def compute_auth_token_uri
          "#{compute_check_uri}/computeMetadata/v1/instance/service-accounts/default/token".freeze
        end

        def compute_id_token_uri
          "#{compute_check_uri}/computeMetadata/v1/instance/service-accounts/default/identity".freeze
        end

        # Detect if this appear to be a GCE instance, by checking if metadata
        # is available.
        def on_gce? options = {}
          # TODO: This should use google-cloud-env instead.
          c = options[:connection] || Faraday.default_connection
          headers = { "Metadata-Flavor" => "Google" }
          resp = c.get compute_check_uri, nil, headers do |req|
            req.options.timeout = 1.0
            req.options.open_timeout = 0.1
          end
          return false unless resp.status == 200
          resp.headers["Metadata-Flavor"] == "Google"
        rescue Faraday::TimeoutError, Faraday::ConnectionFailed
          false
        end

        memoize :on_gce?
      end

      # Overrides the super class method to change how access tokens are
      # fetched.
      def fetch_access_token options = {}
        c = options[:connection] || Faraday.default_connection
        retry_with_error do
          uri = target_audience ? GCECredentials.compute_id_token_uri : GCECredentials.compute_auth_token_uri
          query = target_audience ? { "audience" => target_audience, "format" => "full" } : {}
          query[:scopes] = Array(scope).join "," if scope
          resp = c.get uri, query, "Metadata-Flavor" => "Google"
          case resp.status
          when 200
            content_type = resp.headers["content-type"]
            if ["text/html", "application/text"].include? content_type
              { (target_audience ? "id_token" : "access_token") => resp.body }
            else
              Signet::OAuth2.parse_credentials resp.body, content_type
            end
          when 403, 500
            msg = "Unexpected error code #{resp.status} #{UNEXPECTED_ERROR_SUFFIX}"
            raise Signet::UnexpectedStatusError, msg
          when 404
            raise Signet::AuthorizationError, NO_METADATA_SERVER_ERROR
          else
            msg = "Unexpected error code #{resp.status} #{UNEXPECTED_ERROR_SUFFIX}"
            raise Signet::AuthorizationError, msg
          end
        end
      end
    end
  end
end
