class EaUrls
  require 'net/http'
  require 'faraday'
  require 'active_support/core_ext/hash/conversions'
  require 'awesome_print'


  def self.login(login_info)

    authentication_hash = self.authenticate(login_info)

    current_session = EaSession.new
    current_session.session_key = authentication_hash["fulllogin"]["sessioninfo"]["sessionkey"]

    verification_hash = self.validate_session(current_session)
    current_session.user_id = verification_hash["sessioninfo"]["personadetails"]["personaid"]
    current_session.user_name = verification_hash["sessioninfo"]["personadetails"]["displayname"]

    login_hash = self.login_to_cardhouse(current_session)

    current_session.save

    current_session
  end

  def self.get_connection
    connection = Faraday::Connection.new 'https://walams.tools.gos.ea.com/', :ssl => { :verify => false } do |c|
            c.use Faraday::Adapter::NetHttp
    end
    connection.headers[:user_agent] = 'NHL® 14 App/1.0.1 CFNetwork/672.0.8 Darwin/14.0.0'
    connection
  end

  def self.watchlist_url(current_session)
    return "/wal/nhl-2014-ps3-ios/cardhouse/isWatchList/#{current_session.session_key}?uid=#{current_session.user_id}&st=0&num=45&srt=0"
  end

  def self.search_url(current_session, search)
    return "/wal/nhl-2014-ps3-ios/cardhouse/isSearch/#{current_session.session_key}?ctyp=1&minb=#{search.min_bin}&noac=0&numr=90&macr=-1&leag=0&maxb=#{search.bin_filter}&rtng=0&iret=true&micr=-1&styl=#{search.style.ea_id}&pos=#{search.position.ea_id}&uid=#{current_session.user_id}&form=-1&cat=-1&team=#{search.team.ea_id}&mytr=0&zone=-1&plrt=#{search.player_type.ea_id}&lev=-1&strt=0&nat=-1"
  end

  def self.bid_url(current_session, trade_id, bid_amount)
    return "/wal/nhl-2014-ps3-ios/cardhouse/isOfferTrade/#{current_session.session_key}?uid=#{current_session.user_id}&cred=#{bid_amount}&tid=#{trade_id}"
  end

  def self.deck_info_url(current_session)
    return "/wal/nhl-2014-ps3-ios/cardhouse/deckInfo/#{current_session.session_key}?uid=#{current_session.user_id}&acid=-1&ver=1&pers=0"
  end

  private

  def self.authenticate(login_info)
    connection = get_connection

    response = connection.get self.authentication_url(login_info.username, login_info.email, login_info.password)

    authentication_hash = Hash.from_xml(response.body)
    ap authentication_hash

    authentication_hash
  end

  def self.validate_session(current_session)
    connection = get_connection
    response = connection.get self.validate_session_key_url(current_session.session_key)

    verification_hash = Hash.from_xml(response.body)
    ap verification_hash

    verification_hash
  end

  def self.login_to_cardhouse(current_session)
    connection = get_connection
    response = connection.get self.login_to_cardhouse_url(current_session.session_key, current_session.user_id, current_session.user_name)

    login_hash = Hash.from_xml(response.body)
    ap login_hash

    login_hash
  end

  def self.base_url 
    return "https://walams.tools.gos.ea.com"
  end

  def self.authentication_url(username, email, password)
    return "/wal/nhl-2014-ps3-ios/authentication/expressLogin?pass=#{password}&pnam=#{username}&mail=#{email}"
  end

  def self.validate_session_key_url(session_key)
    return "/wal/nhl-2014-ps3-ios/authentication/validateSessionKey/#{session_key}?skey=#{session_key}"
  end

  def self.login_to_cardhouse_url(session_key, userid, username)
    return "/wal/nhl-2014-ps3-ios/cardhouse/login/#{session_key}?clnt=0&pur=0&uid=#{userid}&cp=0&lang=0&pers=#{username}"
  end


end
