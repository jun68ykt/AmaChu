# coding: utf-8
# ----------------------------------------------------------------
#
#              Amazon Japan 注文履歴データ取得スクリプト用クラス
#
#                                                  2017.2.13 ykt68
# ----------------------------------------------------------------
require 'selenium-webdriver'
require 'optparse'
require 'open-uri'

class AmaChu

  # 定数定義
  module Constants
    # CSSセレクタ
    CSS_NUM_ORDERS = 'span.num-orders'
    CSS_ORDERS = 'div.a-box-group.a-spacing-base.order'
    CSS_ONE_ORDER = 'div.a-box-group.a-spacing-base.order'

    # 出力ディレクトリ
    OUTPUT_DIR = './orders'

    # アカウントのホームページURL
    HOME_PAGE_URL = 'https://www.amazon.co.jp/gp/css/homepage.html'

    # 注文情報のURL
    ORDER_HISTORY_URL = 'https://www.amazon.co.jp/gp/your-account/order-history/'
    ORDER_HISTORY_PARAMS = 'ref=oh_aui_pagination_3_1?ie=UTF8&orderFilter=year-%d&search=&startIndex=%d'

    # 注文履歴の1ページごとの注文件数
    NUM_ORDERS_PER_PAGE = 10

    # ウェイト時間
    WAITING_SECONDS_AFTER_LOGIN = 5
    WAITING_SECONDS_PAGE_LOAD = 15

    # JavaScript のリソース名
    JQUERY_SCRIPT_URL = 'https://code.jquery.com/jquery-3.1.1.min.js'
    ORDER_DETAILS_SCRIPT = './amachu.js'

    # -y オプションで指定できる西暦年の最小値(=アマゾンジャパンのサービス開始年)
    MIN_YEAR = 2000

  end

  # 注文情報一件を保持するクラス
  class Order

    attr_reader :date, :order_id, :total_amount

    # 初期化
    def initialize(order)
      text_to_i(order)
      @date = order['date']
      @order_id = order['order_id']
      @total_amount = order['total_amount']
      @items = order['items']
    end

    # 何らかの形式で出力
    def output(params=nil)

      return if (params.nil? || !params.has_key?(:output_dir))

      filename = @order_id + '.json'
      File.open("#{params[:output_dir]}/#{filename}", 'w') do |f|
        f.puts(self.to_json)
      end
    end

    # JSON文字列化
    def to_json
      JSON.pretty_generate(self.to_h)
    end

    # ハッシュ化
    def to_h
      {date: @date, order_id: @order_id, total_amount: @total_amount, items: @items}
    end

    private

    # 注文情報に含まれる価格の文字列を整数型に変換
    def text_to_i(order)

      if order['date'].match(/([0-9]+)年([0-9]+)月([0-9]+)日/) then
        order['date'] = sprintf('%4d-%02d-%02d', $1.to_i, $2.to_i, $3.to_i)
      end

      begin
        if order['total_amount'].match(/([0-9,]+)$/) then
          order['total_amount'] = $1.gsub(/,/, '').to_i
        end
      rescue
        puts 'ERROR: order_id=' + order['order_id']
        order['total_amount'] = -1
      end

      order['items'].each do |item|
        if item.has_key?('name') then
          if item.has_key?('price') && item['price'].match(/([0-9,]+)$/) then
            item['price'] = $1.gsub(/,/, '').to_i
          end
        end
      end
    end
  end

  # 初期化
  def initialize
    @user = nil
    @password = nil
    @year = Date.today.year
    @output_dir = Constants::OUTPUT_DIR

    begin
      @driver = Selenium::WebDriver.for :firefox
    rescue => e
      msg = "FireFoxが正しくインストールされていないか、他の何らかの理由により\n" +
          'FireFox用WebDriverの作成に失敗しました。詳細は以下です。'
      quit(msg, 1, e)
    end

    @wait = Selenium::WebDriver::Wait.new(
        :timeout => Constants::WAITING_SECONDS_PAGE_LOAD)

    @total_num_orders = nil
    @total_num_pages = nil

    @orders = nil

    begin
      open(Constants::ORDER_DETAILS_SCRIPT) do |file|
        @order_details_js = file.read
      end
    rescue => e
      puts e.message
      exit 1
    end
  end

  # エラーメッセージ等を出力してスクリプトを終了
  def quit(message=nil, exit_code=0, ex=nil)

    puts(message) if message

    if ex then
      puts '----------'
      puts "例外クラス： #{ex.class}"
      puts "例外メッセージ： #{ex.message}"
      puts '----------'
    end

    puts "終了ステータス=#{exit_code.to_s} で終了します。" if exit_code != 0

    @driver.quit if @driver

    exit exit_code
  end


  # 起動パラメータ解析
  def get_params
    begin
      params = ARGV.getopts('u:p:y:o:')
    rescue => e
      case e.message
        when /missing argument: -([upydo])/
          puts "-#$1オプションに値を指定してください。"
        when /invalid option: (.*)/
          puts "#$1 は不正なオプションです。"
        else
          puts '不明なオプションエラーです。'
      end

      quit(nil, 1, nil)
    end

    params.each do |k, v|
      case k
        when 'u';
          @user = v
        when 'p';
          @password = v
        when 'o'
          @output_dir = v unless v.nil?

        when 'y'
          begin
            @year = v.to_i unless v.nil?
            unless Constants::MIN_YEAR <= @year && @year <= Date.today.year
              raise ArgumentError.new('対象年の指定が不正です。')
            end
          rescue => e
            quit("-yオプションには、#{Constants::MIN_YEAR}以上、" +
                     '今年の西暦年以下の数字を指定してください。(例：-y 2016)', 1, e)
          end
      end
    end

    quit('-u <ユーザー名> は必須です。', 1, nil) if @user.nil?
    quit('-p <パスワード> は必須です。', 1, nil) if @password.nil?

    check_output_dir

    {user: @user, password: @password, year: @year, output_dir: @output_dir}
  end


  # アマゾンにログイン
  def login

    # 注文履歴のページに遷移
    @driver.get(Constants::ORDER_HISTORY_URL)

    # ログイン情報を入力してサブミットボタンをクリック
    @driver.find_element(:id, 'ap_email').send_keys(@user)
    @driver.find_element(:id, 'ap_password').send_keys(@password)
    @driver.find_element(:id, 'signInSubmit').click

    # 数秒待つ
    sleep(Constants::WAITING_SECONDS_AFTER_LOGIN)

    # JQueryを読み込む
    jquery

    # 再びログインフォームが表示されている場合、終了
    script = <<'EOS'
  		return ($('form[name="signIn"]').length == 0);
EOS
    unless @driver.execute_script(script)
      quit('指定されたIDとパスワードでログインできませんでした。', 1, nil)
    end
  end


  # 指定されたページ番号の注文履歴ページを取得
  def get_history_page(page)
    url = history_url(@year, page)
    @driver.get(url)
    jquery
    self
  end


  # 進捗ログ出力
  def progress_log(done_count=0)
    return if @total_num_orders.nil?

    len = @total_num_orders.to_s.length
    fmt = "%#{len}d"
    progress = sprintf('%4.1f', done_count.to_f * 100 / @total_num_orders)
    print("\r全 #{@total_num_orders} 件のうち、#{sprintf(fmt, done_count)} 件(#{progress}%)が処理済み");
  end


  # 総注文数の取得
  def total_num_orders
    if @total_num_orders.nil? then
      element = @wait.until { @driver.find_element(css: AmaChu::Constants::CSS_NUM_ORDERS) }
      str = get_text(element)
      @total_num_orders = (str.match(/([0-9]+)件/) ? $1.to_i : 0)
    end
    @total_num_orders
  end


  # 全ページ数の取得
  def total_num_pages
    @total_num_pages = (total_num_orders / Constants::NUM_ORDERS_PER_PAGE) +
        (total_num_orders % Constants::NUM_ORDERS_PER_PAGE > 0 ? 1 : 0) if @total_num_pages.nil?
    @total_num_pages
  end


  # 注文情報の取得
  def fetch_orders

    @orders = []

    order_divs = @driver.find_elements(css: Constants::CSS_ONE_ORDER)

    order_divs.each do |div|
      script = @order_details_js + 'return(order_details);'
      order = Order.new(@driver.execute_script(script, div))
      @orders << order
    end
  end


  # 指定されたページ番号の注文履歴ページが読み込まれるまで待つ
  def wait(page)
    start_index = (page - 1) * Constants::NUM_ORDERS_PER_PAGE
    end_index = [page * Constants::NUM_ORDERS_PER_PAGE - 1, @total_num_orders - 1].min
    num_orders = end_index - start_index + 1

    @wait.until { @driver.find_element(css: "#{Constants::CSS_ORDERS}:nth-of-type(#{num_orders})") }
    self
  end


  # 取得した各注文情報に何らかの処理を行うためのイテレータ
  def each_order
    @orders.each do |order|
      yield(order)
    end
  end


  private

  # JQuery の読み込み
  def jquery
    script = nil
    begin
      open(Constants::JQUERY_SCRIPT_URL) do |file|
        script = file.read
      end
    rescue => e
      quit('JQueryの読み込みでエラーが発生しました。', 1, e)
    end

    @driver.execute_script(script)
  end


  # 指定した要素で囲まれたテキストを取得
  def get_text(element)
    script = <<'EOS'
  			return $(arguments[0]).contents().filter(function() {
        	return this.nodeType == Node.TEXT_NODE;
    		}).text();
EOS
    @driver.execute_script(script, element)
  end


  # 注文履歴ページのURL
  def history_url(year=Date.today.year, page_num=1)
    start_index = Constants::NUM_ORDERS_PER_PAGE * (page_num-1)
    Constants::ORDER_HISTORY_URL + sprintf(Constants::ORDER_HISTORY_PARAMS, year, start_index)
  end


  # ファイルを作成するディレクトリの確認️
  def check_output_dir
    @output_dir.chomp!('/') if @output_dir.length > 1

    if FileTest.exist?(@output_dir) then
      unless (FileTest.directory?(@output_dir) && FileTest.writable?(@output_dir))
        quit(
            "出力ディレクトリに指定されたパス #{path} がディレクトリではないか、\n" +
                'もしくは、書き込み権限がありません。', 1, nil)
      end
    else
      begin
        FileUtils.mkdir_p(@output_dir)
      rescue => e
        quit('出力ディレクトリを作成できませんでした。詳細は以下です。', 1, e)
      end
    end
  end

end