#
# このファイルにはyoutube APIラッパーが含まれています
#

module YoutubeAPI
  extend self

  # Androidバージョンについては、https://en.wikipedia.org/wiki/Android_version_historyを参照してください。
  private ANDROID_APP_VERSION = "19.32.34"
  private ANDROID_VERSION     = "12"
  private ANDROID_USER_AGENT  = "com.google.android.youtube/#{ANDROID_APP_VERSION} (Linux; U; Android #{ANDROID_VERSION}; US) gzip"
  private ANDROID_SDK_VERSION = 31_i64

  private ANDROID_TS_APP_VERSION = "1.9"
  private ANDROID_TS_USER_AGENT  = "com.google.android.youtube/1.9 (Linux; U; Android 12; US) gzip"

  # Appleのデバイス名については、https://gist.github.com/adamawolf/3048717を参照してください。
  # iOSバージョンについては、https://en.wikipedia.org/wiki/IOS_version_history#Releasesを参照してください。
  # 次に、あなたが望むメジャーバージョンの専用記事に移動します。
  private IOS_APP_VERSION = "19.32.8"
  private IOS_USER_AGENT  = "com.google.ios.youtube/#{IOS_APP_VERSION} (iPhone14,5; U; CPU iOS 17_6 like Mac OS X;)"
  private IOS_VERSION     = "17.6.1.21G93" # Major.Minor.Patch.Build

  private WINDOWS_VERSION = "10.0"

  # API でサポートされているクライアントの 1 つを選択するために使用される列挙
  enum ClientType
    Web
    WebEmbeddedPlayer
    WebMobile
    WebScreenEmbed

    Android
    AndroidEmbeddedPlayer
    AndroidScreenEmbed
    AndroidTestSuite

    IOS
    IOSEmbedded
    IOSMusic

    TvHtml5
    TvHtml5ScreenEmbed
  end

  # 異なるクライアントによって使用されるハードコードされた値のリスト
  HARDCODED_CLIENTS = {
    ClientType::Web => {
      name:       "WEB",
      name_proto: "1",
      version:    "2.20240814.00.00",
      screen:     "WATCH_FULL_SCREEN",
      os_name:    "Windows",
      os_version: WINDOWS_VERSION,
      platform:   "DESKTOP",
    },
    ClientType::WebEmbeddedPlayer => {
      name:       "WEB_EMBEDDED_PLAYER",
      name_proto: "56",
      version:    "1.20240812.01.00",
      screen:     "EMBED",
      os_name:    "Windows",
      os_version: WINDOWS_VERSION,
      platform:   "DESKTOP",
    },
    ClientType::WebMobile => {
      name:       "MWEB",
      name_proto: "2",
      version:    "2.20240813.02.00",
      os_name:    "Android",
      os_version: ANDROID_VERSION,
      platform:   "MOBILE",
    },
    ClientType::WebScreenEmbed => {
      name:       "WEB",
      name_proto: "1",
      version:    "2.20240814.00.00",
      screen:     "EMBED",
      os_name:    "Windows",
      os_version: WINDOWS_VERSION,
      platform:   "DESKTOP",
    },

    # Android

    ClientType::Android => {
      name:                "ANDROID",
      name_proto:          "3",
      version:             ANDROID_APP_VERSION,
      android_sdk_version: ANDROID_SDK_VERSION,
      user_agent:          ANDROID_USER_AGENT,
      os_name:             "Android",
      os_version:          ANDROID_VERSION,
      platform:            "MOBILE",
    },
    ClientType::AndroidEmbeddedPlayer => {
      name:       "ANDROID_EMBEDDED_PLAYER",
      name_proto: "55",
      version:    ANDROID_APP_VERSION,
    },
    ClientType::AndroidScreenEmbed => {
      name:                "ANDROID",
      name_proto:          "3",
      version:             ANDROID_APP_VERSION,
      screen:              "EMBED",
      android_sdk_version: ANDROID_SDK_VERSION,
      user_agent:          ANDROID_USER_AGENT,
      os_name:             "Android",
      os_version:          ANDROID_VERSION,
      platform:            "MOBILE",
    },
    ClientType::AndroidTestSuite => {
      name:                "ANDROID_TESTSUITE",
      name_proto:          "30",
      version:             ANDROID_TS_APP_VERSION,
      android_sdk_version: ANDROID_SDK_VERSION,
      user_agent:          ANDROID_TS_USER_AGENT,
      os_name:             "Android",
      os_version:          ANDROID_VERSION,
      platform:            "MOBILE",
    },

    # IOS

    ClientType::IOS => {
      name:         "IOS",
      name_proto:   "5",
      version:      IOS_APP_VERSION,
      user_agent:   IOS_USER_AGENT,
      device_make:  "Apple",
      device_model: "iPhone14,5",
      os_name:      "iPhone",
      os_version:   IOS_VERSION,
      platform:     "MOBILE",
    },
    ClientType::IOSEmbedded => {
      name:         "IOS_MESSAGES_EXTENSION",
      name_proto:   "66",
      version:      IOS_APP_VERSION,
      user_agent:   IOS_USER_AGENT,
      device_make:  "Apple",
      device_model: "iPhone14,5",
      os_name:      "iPhone",
      os_version:   IOS_VERSION,
      platform:     "MOBILE",
    },
    ClientType::IOSMusic => {
      name:         "IOS_MUSIC",
      name_proto:   "26",
      version:      "7.14",
      user_agent:   "com.google.ios.youtubemusic/7.14 (iPhone14,5; U; CPU iOS 17_6 like Mac OS X;)",
      device_make:  "Apple",
      device_model: "iPhone14,5",
      os_name:      "iPhone",
      os_version:   IOS_VERSION,
      platform:     "MOBILE",
    },

    # TV app

    ClientType::TvHtml5 => {
      name:       "TVHTML5",
      name_proto: "7",
      version:    "7.20240813.07.00",
    },
    ClientType::TvHtml5ScreenEmbed => {
      name:       "TVHTML5_SIMPLY_EMBEDDED_PLAYER",
      name_proto: "85",
      version:    "2.0",
      screen:     "EMBED",
    },
  }

  ####################################################################
  # 構造クライアント設定
  #
  # クライアント構成を異なるものに渡すために使用されるデータ構造
  # APIエンドポイントハンドラー。
  #
  # ユースケースの例：
  #
  # ```
  # # ノルウェー語の検索結果を取得する
  # conf_1 = ClientConfig.new(region: "NO")
  # YoutubeAPI::search("Kollektivet", params: "", client_config: conf_1)
  #
  # # Android クライアントを使用して、ビデオ ストリーム URL を要求します。
  # conf_2 = ClientConfig.new(client_type: ClientType::Android)
  # YoutubeAPI::player(video_id: "dQw4w9WgXcQ", client_config: conf_2)
  #
  #
  struct ClientConfig
    # エミュレートするクライアントの種類。
    # `enum ClientType`と`HARDCODED_CLIENTS`を参照してください。
    property client_type : ClientType

    # 検索結果を変更するなど、YouTubeに提供する地域
    # (this is passed as the `gl` parameter).
    property region : String | Nil

    # 初期化機能
    def initialize(
      *,
      @client_type = ClientType::Web,
      @region = "US"
    )
    end

    # ハードコードされたクライアントに簡単にアクセスできるゲッター関数
    # パラメータ（名前/バージョン文字列および関連するAPIキー）
    def name : String
      HARDCODED_CLIENTS[@client_type][:name]
    end

    def name_proto : String
      HARDCODED_CLIENTS[@client_type][:name_proto]
    end

    # :ditto:
    def version : String
      HARDCODED_CLIENTS[@client_type][:version]
    end

    # :ditto:
    def screen : String
      HARDCODED_CLIENTS[@client_type][:screen]? || ""
    end

    def android_sdk_version : Int64?
      HARDCODED_CLIENTS[@client_type][:android_sdk_version]?
    end

    def user_agent : String?
      HARDCODED_CLIENTS[@client_type][:user_agent]?
    end

    def os_name : String?
      HARDCODED_CLIENTS[@client_type][:os_name]?
    end

    def device_make : String?
      HARDCODED_CLIENTS[@client_type][:device_make]?
    end

    def device_model : String?
      HARDCODED_CLIENTS[@client_type][:device_model]?
    end

    def os_version : String?
      HARDCODED_CLIENTS[@client_type][:os_version]?
    end

    def platform : String?
      HARDCODED_CLIENTS[@client_type][:platform]?
    end

    # ロギング目的で文字列に変換する
    def to_s
      return {
        client_type: self.name,
        region:      @region,
      }.to_s
    end
  end

  # デフォルトのクライアント設定、何も渡されていない場合に使用
  DEFAULT_CLIENT_CONFIG = ClientConfig.new

  ####################################################################
  # make_context(client_config)
  #
  # 要求するために必要な「コンテキスト」データをハッシュとして返す
  # Youtube API エンドポイント。
  #
  private def make_context(client_config : ClientConfig | Nil, video_id = "dQw4w9WgXcQ") : Hash
    # Nil が渡された場合は、デフォルトのクライアント設定を使用します。
    client_config ||= DEFAULT_CLIENT_CONFIG

    client_context = {
      "client" => {
        "hl"            => "en",
        "gl"            => client_config.region || "US", # Can't be empty!
        "clientName"    => client_config.name,
        "clientVersion" => client_config.version,
      } of String => String | Int64,
    }

    # クライアント定義に存在する場合は、さらにコンテキストを追加します。
    if !client_config.screen.empty?
      client_context["client"]["clientScreen"] = client_config.screen
    end

    if client_config.screen == "EMBED"
      client_context["thirdParty"] = {
        "embedUrl" => "https://www.youtube.com/embed/#{video_id}",
      } of String => String | Int64
    end

    if android_sdk_version = client_config.android_sdk_version
      client_context["client"]["androidSdkVersion"] = android_sdk_version
    end

    if device_make = client_config.device_make
      client_context["client"]["deviceMake"] = device_make
    end

    if device_model = client_config.device_model
      client_context["client"]["deviceModel"] = device_model
    end

    if os_name = client_config.os_name
      client_context["client"]["osName"] = os_name
    end

    if os_version = client_config.os_version
      client_context["client"]["osVersion"] = os_version
    end

    if platform = client_config.platform
      client_context["client"]["platform"] = platform
    end

    if CONFIG.visitor_data.is_a?(String)
      client_context["client"]["visitorData"] = CONFIG.visitor_data.as(String)
    end

    return client_context
  end

  ####################################################################
  # browse(continuation, client_config?)
  # browse(browse_id, params, client_config?)
  #
  # 必要なヘッダーでyoutubei/v1/browseエンドポイントを要求します
  # そして、英語のJSON返信を取得するためのPOSTデータ
  # 簡単に解析される。
  #
  # どちらのフォームもオプションのClientConfigパラメータを取ることができます（参照
  # 上記の「struct ClientConfig」).
  #
  # 要求されたデータは、どちらかです。:
  #
  #  - 継続トークン（ctoken）。このトークンに応じて
  #    コンテンツ、返されたデータはプレイリストビデオ、チャンネルにすることができます
  #    コミュニティタブコンテンツ、チャンネル情報、 ...
  #
  #  - プレイリストID（パラメータは空の文字列でなければなりません）
  #
  def browse(continuation : String, client_config : ClientConfig | Nil = nil)
    # API に必要な JSON リクエスト データ
    data = {
      "context"      => self.make_context(client_config),
      "continuation" => continuation,
    }

    return self._post_json("/youtubei/v1/browse", data, client_config)
  end

  # :ditto:
  def browse(
    browse_id : String,
    *, # 次のパラメータを名前で渡すように強制する
    params : String,
    client_config : ClientConfig | Nil = nil
  )
    # API に必要な JSON リクエスト データ
    data = {
      "browseId" => browse_id,
      "context"  => self.make_context(client_config),
    }

    # 追加のパラメータが提供された場合は、追加します。
    # (これは、チャンネル情報、プレイリスト、コミュニティに必要です。)
    if params != ""
      data["params"] = params
    end

    return self._post_json("/youtubei/v1/browse", data, client_config)
  end

  ####################################################################
  # next(continuation, client_config?)
  # next(data, client_config?)
  #
  # 必要なヘッダーでyoutubei/v1/nextエンドポイントを要求します
  # そして、英語のJSON返信を取得するためのPOSTデータ
  # 簡単に解析される。
  #
  # どちらのフォームもオプションのClientConfigパラメータを取ることができます（参照
  # `struct ClientConfig` 詳細は上記).
  #
  # 要求されたデータは:
  #
  #  - 継続トークン（ctoken）。このトークンに応じて
  #    コンテンツ、返されたデータはビデオコメントである可能性があります、
  #    彼らの返事、...この場合、文字列を渡さなければなりません
  #    機能に直接。 E.g:
  #
  #    ```
  #    YoutubeAPI::next("ABCDEFGH_abcdefgh==")
  #    ```
  #
  #  - 任意のパラメータ、ハッシュ形式。以下の例を参照してください。
  #    YouTubeに渡すことができる任意のデータの既知の例:
  #
  #    ```
  #    # 特定のビデオIDに関連するビデオを取得する
  #    YoutubeAPI::next({"videoId" => "dQw4w9WgXcQ"})
  #
  #    # プレイリストビデオの詳細を入手する
  #    YoutubeAPI::next({
  #      "videoId"    => "9bZkp7q19f0",
  #      "playlistId" => "PL_oFlvgqkrjUVQwiiE3F3k3voF4tjXeP0",
  #    })
  #    ```
  #
  def next(continuation : String, *, client_config : ClientConfig | Nil = nil)
    # API に必要な JSON リクエスト データ
    data = {
      "context"      => self.make_context(client_config),
      "continuation" => continuation,
    }

    return self._post_json("/youtubei/v1/next", data, client_config)
  end

  # :ditto:
  def next(data : Hash, *, client_config : ClientConfig | Nil = nil)
    # API に必要な JSON リクエスト データ
    data2 = data.merge({
      "context" => self.make_context(client_config),
    })

    return self._post_json("/youtubei/v1/next", data2, client_config)
  end

  # 名前付きタプルの渡しも許可します。
  def next(data : NamedTuple, *, client_config : ClientConfig | Nil = nil)
    return self.next(data.to_h, client_config: client_config)
  end

  ####################################################################
  # player(video_id, params, client_config?)
  #
  # 必要なヘッダーでyoutubei/v1/playerエンドポイントを要求します
  # そして、JSONの返信を得るためのPOSTデータ。
  #
  # 要求されたデータはビデオID（`v=`パラメータ）であり、いくつか
  # Base64文字列としてフォーマットされた追加パラメータ。
  #
  # オプションのClientConfigパラメータも渡すことができます（参照
  # 詳細については、上記の `struct ClientConfig`)。
  #
  def player(
    video_id : String,
    *, # 次のパラメータを名前で渡すように強制する
    params : String,
    client_config : ClientConfig | Nil = nil
  )
    # 再生コンテキストは、クライアント間で異なる可能性があるため、分離されます。
    playback_ctx = {
      "html5Preference" => "HTML5_PREF_WANTS",
      "referer"         => "https://www.youtube.com/watch?v=#{video_id}",
    } of String => String | Int64

    if {"WEB", "TVHTML5"}.any? { |s| client_config.name.starts_with? s }
      if sts = DECRYPT_FUNCTION.try &.get_sts
        playback_ctx["signatureTimestamp"] = sts.to_i64
      end
    end

    # API に必要な JSON リクエスト データ
    data = {
      "contentCheckOk" => true,
      "videoId"        => video_id,
      "context"        => self.make_context(client_config, video_id),
      "racyCheckOk"    => true,
      "user"           => {
        "lockedSafetyMode" => false,
      },
      "playbackContext" => {
        "contentPlaybackContext" => playback_ctx,
      },
      "serviceIntegrityDimensions" => {
        "poToken" => CONFIG.po_token,
      },
    }

    # 追加のパラメータが提供された場合は、追加します。
    if params != ""
      data["params"] = params
    end

    if CONFIG.invidious_companion.present?
      return self._post_invidious_companion("/youtubei/v1/player", data)
    else
      return self._post_json("/youtubei/v1/player", data, client_config)
    end
  end

  ####################################################################
  # resolve_url(url, client_config?)
  #
  # youtubei/v1/navigation/resolve_urlエンドポイントをリクエストする
  # JSON 返信を取得するには、ヘッダーと POST データが必要です。
  #
  # オプションのClientConfigパラメータも渡すことができます（参照
  # 詳細については、上記の `struct ClientConfig`)。
  #
  # Output:
  #
  # ```
  # # 有効なチャンネル「ブランドURL」は、関連するUCIDと閲覧IDを提供します。
  # channel_a = YoutubeAPI.resolve_url("https://youtube.com/c/google")
  # channel_a # => {
  #   "endpoint": {
  #     "browseEndpoint": {
  #       "params": "EgC4AQA%3D",
  #       "browseId":"UCK8sQmJBp8GCxrOtXWBpyEA"
  #     },
  #     ...
  #   }
  # }
  #
  # # 無効なURLが返され、InfoExceptionがスローされます。
  # channel_b = YoutubeAPI.resolve_url("https://youtube.com/c/invalid")
  # ```
  #
  def resolve_url(url : String, client_config : ClientConfig | Nil = nil)
    data = {
      "context" => self.make_context(nil),
      "url"     => url,
    }

    return self._post_json("/youtubei/v1/navigation/resolve_url", data, client_config)
  end

  ####################################################################
  # search(search_query, params, client_config?)
  #
  # 必要なヘッダーでyoutubei/v1/searchエンドポイントを要求します
  # そして、JSONの返信を得るためのPOSTデータ。検索結果として
  # 地域によって異なり、地域コードは指定できます
  # 米国以外の結果を得るために。
  #
  # 要求されたデータは検索文字列であり、いくつかの追加
  # パラメータ、base64文字列としてフォーマットされた。
  #
  # オプションのClientConfigパラメータも渡すことができます（参照
  # 詳細については、上記の `struct ClientConfig`)。
  #
  def search(
    search_query : String,
    params : String,
    client_config : ClientConfig | Nil = nil
  )
    # API に必要な JSON リクエスト データ
    data = {
      "query"   => search_query,
      "context" => self.make_context(client_config),
      "params"  => params,
    }

    return self._post_json("/youtubei/v1/search", data, client_config)
  end

  ####################################################################
  # get_transcript(params, client_config?)
  #
  # 必要なヘッダーでyoutubei/v1/get_transcriptエンドポイントを要求します
  # JSON 返信を取得するためと POST データ。
  #
  # The requested data is a specially encoded protobuf string that denotes the specific language requested.
  #
  # An optional ClientConfig parameter can be passed, too (see
  # `struct ClientConfig` above for more details).
  #

  def get_transcript(
    params : String,
    client_config : ClientConfig | Nil = nil
  ) : Hash(String, JSON::Any)
    data = {
      "context" => self.make_context(client_config),
      "params"  => params,
    }

    return self._post_json("/youtubei/v1/get_transcript", data, client_config)
  end

  ####################################################################
  # _post_json(endpoint, data, client_config?)
  #
  # Internal function that does the actual request to youtube servers
  # and handles errors.
  #
  # The requested data is an endpoint (URL without the domain part)
  # and the data as a Hash object.
  #
  def _post_json(
    endpoint : String,
    data : Hash,
    client_config : ClientConfig | Nil
  ) : Hash(String, JSON::Any)
    # Use the default client config if nil is passed
    client_config ||= DEFAULT_CLIENT_CONFIG

    # Query parameters
    url = "#{endpoint}?prettyPrint=false"

    headers = HTTP::Headers{
      "Content-Type"              => "application/json; charset=UTF-8",
      "Accept-Encoding"           => "gzip, deflate",
      "x-goog-api-format-version" => "2",
      "x-youtube-client-name"     => client_config.name_proto,
      "x-youtube-client-version"  => client_config.version,
    }

    if user_agent = client_config.user_agent
      headers["User-Agent"] = user_agent
    end

    if CONFIG.visitor_data.is_a?(String)
      headers["X-Goog-Visitor-Id"] = CONFIG.visitor_data.as(String)
    end

    # Logging
    LOGGER.debug("YoutubeAPI: Using endpoint: \"#{endpoint}\"")
    LOGGER.trace("YoutubeAPI: ClientConfig: #{client_config}")
    LOGGER.trace("YoutubeAPI: POST data: #{data}")

    # Send the POST request
    body = YT_POOL.client() do |client|
      client.post(url, headers: headers, body: data.to_json) do |response|
        if response.status_code != 200
          raise InfoException.new("Error: non 200 status code. Youtube API returned \
            status code #{response.status_code}. See <a href=\"https://docs.invidious.io/youtube-errors-explained/\"> \
            https://docs.invidious.io/youtube-errors-explained/</a> for troubleshooting.")
        end
        self._decompress(response.body_io, response.headers["Content-Encoding"]?)
      end
    end

    # Convert result to Hash
    initial_data = JSON.parse(body).as_h

    # Error handling
    if initial_data.has_key?("error")
      code = initial_data["error"]["code"]
      message = initial_data["error"]["message"].to_s.sub(/(\\n)+\^$/, "")

      # Logging
      LOGGER.error("YoutubeAPI: Got error #{code} when requesting #{endpoint}")
      LOGGER.error("YoutubeAPI: #{message}")
      LOGGER.info("YoutubeAPI: POST data was: #{data}")

      raise InfoException.new("Could not extract JSON. Youtube API returned \
      error #{code} with message:<br>\"#{message}\"")
    end

    return initial_data
  end

  ####################################################################
  # _post_invidious_companion(endpoint, data)
  #
  # Internal function that does the actual request to Invidious companion
  # and handles errors.
  #
  # The requested data is an endpoint (URL without the domain part)
  # and the data as a Hash object.
  #
  def _post_invidious_companion(
    endpoint : String,
    data : Hash
  ) : Hash(String, JSON::Any)
    headers = HTTP::Headers{
      "Content-Type"  => "application/json; charset=UTF-8",
      "Authorization" => "Bearer #{CONFIG.invidious_companion_key}",
    }

    # Logging
    LOGGER.debug("Invidious companion: Using endpoint: \"#{endpoint}\"")
    LOGGER.trace("Invidious companion: POST data: #{data}")

    # Send the POST request

    begin
      invidious_companion = CONFIG.invidious_companion.sample
      response = make_client(invidious_companion.private_url, use_http_proxy: false,
        &.post(endpoint, headers: headers, body: data.to_json))
      body = response.body
      if (response.status_code != 200)
        raise Exception.new(
          "Error while communicating with Invidious companion: \
          status code: #{response.status_code} and body: #{body.dump}"
        )
      end
    rescue ex
      raise InfoException.new("Error while communicating with Invidious companion: " + (ex.message || "no extra info found"))
    end

    # Convert result to Hash
    initial_data = JSON.parse(body).as_h

    return initial_data
  end

  ####################################################################
  # _decompress(body_io, headers)
  #
  # Internal function that reads the Content-Encoding headers and
  # decompresses the content accordingly.
  #
  # We decompress the body ourselves (when using HTTP::Client) because
  # the auto-decompress feature is broken in the Crystal stdlib.
  #
  # Read more:
  #  - https://github.com/iv-org/invidious/issues/2612
  #  - https://github.com/crystal-lang/crystal/issues/11354
  #
  def _decompress(body_io : IO, encodings : String?) : String
    if encodings
      # Multiple encodings can be combined, and are listed in the order
      # in which they were applied. E.g: "deflate, gzip" means that the
      # content must be first "gunzipped", then "defated".
      encodings.split(',').reverse.each do |enc|
        case enc.strip(' ')
        when "gzip"
          body_io = Compress::Gzip::Reader.new(body_io, sync_close: true)
        when "deflate"
          body_io = Compress::Deflate::Reader.new(body_io, sync_close: true)
        end
      end
    end

    return body_io.gets_to_end
  end
end # End of module
