# はじめに
&nbsp;&nbsp;Amazonで買った注文の情報を取得するプログラムAmaChu(アマ注、"アマゾンでの注文"の意)を書きましたのでソースを公開します。

# 謝辞
&nbsp;&nbsp;制作にあたり、特にJavaScript部分の開発では以下を参考にさせて頂きました。ありがとうございました。
    
* [Amazonで一年間に使った金額と、注文履歴のTSVを出力するブックマークレット【2016年版】](http://qiita.com/Libitina/items/6417bcb33bf76b0ac55b#_reference-52c1a0c64fc17cbd0f51)

# 開発の経緯

&nbsp;&nbsp;以下のように、2016年分の確定申告のために、Amazonに注文して購入した注文データ（何にいくら使ったか）を<br />
ローカルに取り込みたかったためです。
<br />
* 昨年（2016年)分の確定申告にあたって、一年間でAmazonで購入した書籍、文具、消耗品などが<br />
注文単位で180件ぐらいあった。
* これらの注文を、購入品の明細単位で、経費を管理するためのシステムのDB(MySQL)に投入したかった。<br />
* 購入品単位で投入したいのは、経費に計上するものに勘定科目を付番したかったからです。
&nbsp;(たとえば、一回の注文の中に、書籍とプリンターのトナーがあった場合、書籍は新聞図書費、トナーは消耗品費としたい。)
* が、Amazonの注文履歴や注文の詳細ページを目視しながら、画面に投入するという手作業をやりたくない。
* そこで、プログラムから自動的に注文履歴のページをたどり、注文情報（品目、金額など）を取得して<br />
ローカルにMySQLに投入しやすい形式で、ファイルに保存するようなものを作りたいと考えました。


# 実現方法

* [Selenium Webdriver](http://www.seleniumhq.org/projects/webdriver/) を使ってFireFoxで注文履歴ページを巡回さて欲しいデータを取得
* 開発言語は Ruby 2.2
* ローカルに、１注文に対して１ファイルをJSONで出力

# ソースコードの場所

https://github.com/jun68ykt/AmaChu

# インストールから実行の手順

## ご注意(重要)

&nbsp;&nbsp;当プログラムは指定されたユーザーアカウントでAmazonにログインした状態で動作します。<br />
「誰が作ったものか分からないものを動かしてもし誤発注などがあったら？」というご不安の<br />
ある方は使用しないでください。<br />
&nbsp;&nbsp;このプログラムの実行によって、何らかの誤動作があり、利用者の不利益となるような状況が<br />
発生しても開発者は責任を負いかねます。<br />&nbsp;&nbsp;以上をご了解のもとでご使用をお願い致します。

# 前提

* Ruby を実行させることのできる環境が必要です。制作者の開発と実行は Ruby 2.2　で行っています。 

* [Selenium Webdriver](https://rubygems.org/gems/selenium-webdriver/) が必要です。入っていなければ、

```
　　gem install selenium-webdriver
```
&nbsp;からインストールしてください。

* FireFox が必要です。なければ https://www.mozilla.org/ja/firefox/new/
から インストールをお願いします。

&nbsp;&nbsp;上記２点が正しくインストールされているかどうかは、ターミナルから以下の手順で確認できます。
(以下の説明で、```/Users/ykt68/work```は、適宜お手元の作業ディレクトに読み替えてください。)

```shell-session
[ykt68@macbook work]$ pwd
/Users/ykt68/work
[ykt68@macbook work]$ ls -l
[ykt68@macbook work]$ ruby -v
ruby 2.2.6p396 (2016-11-15 revision 56800) [x86_64-darwin15]
[ykt68@macbook work]$ irb
irb(main):001:0> require 'selenium-webdriver'
=> true
irb(main):002:0> driver = Selenium::WebDriver.for :firefox
=> #<Selenium::WebDriver::Driver:0x..f29fbe877999ca6e browser=:firefox>
irb(main):003:0> driver.get 'https://www.amazon.co.jp'
=> #<Selenium::WebDriver::Remote::Response:0x007f9b7b135948 @code=200, @payload={}>
irb(main):004:0>
```
上記で、
```
 driver = Selenium::WebDriver.for :firefox
```
としたときに、FireFoxが起動して
```
driver.get 'https://www.amazon.co.jp'
```
で、Amazonのトップページが表示されたら準備OKです。

# 実行手順

2016年の注文情報を取得するには、以下のようにします。

1. レポジトリのクローン
```
[ykt68@macbook work]$ pwd
/Users/ykt68/work
[ykt68@macbook work]$ git clone https://github.com/jun68ykt/AmaChu.git AmaChu
Cloning into 'AmaChu'...
remote: Counting objects: 14, done.
remote: Compressing objects: 100% (10/10), done.
remote: Total 14 (delta 5), reused 13 (delta 4), pack-reused 0
Unpacking objects: 100% (14/14), done.
[ykt68@macbook work]$ cd AmaChu
[ykt68@macbook AmaChu (master)]$ ls -l
total 48
-rw-r--r--  1 ykt68  staff    194  2 13 18:06 README.md
-rw-r--r--  1 ykt68  staff   1747  2 13 18:06 amachu.js
-rw-r--r--  1 ykt68  staff  10063  2 13 18:06 amachu_class.rb
-rw-r--r--  1 ykt68  staff   1494  2 13 18:06 amachu_main.rb
```
2. 以下のコマンドを実行

&nbsp;&nbsp;説明のため、Amazonのログインアカウントが以下であるとします。
* ID: foo＠bar.baz
* パスワード：FOOBARBAZ

```
[ykt68@macbook AmaChu (master)]$ ruby amachu_main.rb -u foo@bar.baz -p FOOBARBAZ -y 2016 -o ./amazon_data
```
上記のコマンド実行で、FireFoxが起動し2016年の注文履歴を取得して、<br />
./amazon_data
ディレクトリの下に
```
<注文番号>.json
```
という名前のJSONが作成されます。
<br /><br />
また、ターミナルには
```
全 177 件のうち、 80 件(45.2%)が処理済み
```
という表示で、進捗率が表示されます。
<br /><br />
&nbsp;&nbsp;すべての注文データの取得が完了すると、自動的にFireFoxが閉じ、<br />
スクリプトの実行が終了します。

# 実行時間の目安（参考）

&nbsp;&nbsp;回線の状況によって左右されるでしょうが、作者の環境では以下のように、177件の注文データを
ほぼ1分で取得でき、177個のJSONが作られました。
```
[ykt68@macbook AmaChu (master)]$ cat > run-amachu.sh
date
ruby amachu_main.rb -u xxxxxx@xxxxx.com -p xxxxxx -y 2016 -o ./amazon_data
date
[ykt68@macbook AmaChu (master)]$ sh run-amachu.sh 
2017年 2月13日 月曜日 18時33分35秒 JST
全 177 件のうち、177 件(100.0%)が処理済み
総合計：439,051 円
2017年 2月13日 月曜日 18時34分34秒 JST
[ykt68@macbook AmaChu (master)]$ ls amazon_data/*.json | wc
     177     177    5664
```


# 起動オプション

* メインスクリプト、amachu_main.rb　は、以下のオプションを取ります。

    * -u <i><Amazon アカウント></i>　：必須
    
    * -p <i><パスワード></i> :必須
    
    * -y <i><西暦年></i> :省略可。省略した場合は、現在日時の西暦となります。<br />指定できる最小値は2000（=日本アマゾンのサービス開始の年）
    
    * -o <i><出力ディレクトリ></i> ：省略可。<br />省略した場合は、```./orders``` というディレクトリが作成され、そこに出力されます。

# 現時点のバージョンの機能制限

* 制作者が自分のAmazonアカウントで実行した範囲では、書籍、日用雑貨、およびAmazonビデオしか購入品があり
<br>ませんでしたので、その範囲の注文品で対応したプログラムになっています。<br />もしこれらの範疇ではない物品が含まれていた場合、注文データを取得できない場合があるかもしれません。

* 制作者の開発および実行環境は以下です。
    * Ruby 2.2.6
    * PC: MacBookPro  (Retina 15-inch、Early 2013)
    * OS: MacOS 10.11.6
    * FireFox: 51.0.1 (64 ビット)
    
  <b>WindowsやLINUXなどの他のOSや、他のブラウザ、もしくはFireFoxの他のバージョンでは検証していません。</b>
  　　他のブラウザを使う場合、注文情報の表示場所が微妙に異なるかもしれません。その場合は、<br />
  ```amachu_class.rb```の中で、定数として定義しているCSSや、```amachu.js```での要素の検索の仕方を修正する必要が<br />あるかもしれません。
  
  
# 改修のポイント

&nbsp;&nbsp;もしお使い頂ける場合に、利用目的に沿うように改修するために、ソースのどのあたりに<br />
手を入れたらいいかを挙げます。

### 出力形式を変えたい。
&nbsp;&nbsp;たとえば、JSONではなく1注文明細1行のCSVにしたい、あるいは、データベースにAmazon用の注文テーブル、<br />
明細テーブルを作っておき、これに直接保存したい場合などがあるかもしれません。<br />
&nbsp;&nbsp;その場合は```amachu_class.rb```の、```AmaChu::Order#output```メソッドを改修すると早いと思います。
  
</p>
  
### 注文履歴のページから、他の情報も取得したい。あるいは、取得した情報のハッシュの構成要素を変えたい。

&nbsp;&nbsp;出力されるJSONは以下のようなものです。
```json
{
  "date": "2016-04-29",
  "order_id": "999-9999999-9999999",
  "total_amount": 9288,
  "items": [
    {
      "name": "詳説 正規表現 第3版",
      "price": 5184
    },
    {
      "name": "プログラミング言語 Ruby",
      "price": 4104
    }
  ]
}
```

* JSONプロパティitems の一要素として、送料は含まれません。したがってitems に含まれる各アイテムの price の合計が total_amount になるとは限りません。

* このJSONを元データから取得しているソースコードは、```amachu.js``` です。JQueryで欲しい情報を持つDOMに、CSSセレクタでアクセスしています。このJSを改修すると
Ruby側に渡される連想配列オブジェクトを拡張、変更できます。

### FireFoxではないWebDriverを使いたい。

&nbsp;&nbsp;FireFox用ドライバの初期化は```AmaChu```のinitializeメソッドで
```ruby
    begin
      @driver = Selenium::WebDriver.for :firefox
    rescue => e
    ・・・
```
としている部分を適宜、当該のドライバに合わせて変更してください。
    
    
以上



