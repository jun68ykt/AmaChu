# coding: utf-8
# ----------------------------------------------------------------
#
#              Amazon Japan 注文履歴データ取得スクリプト用クラス
#
#                                                  2017.2.13 ykt68
# ----------------------------------------------------------------
require './amachu_class'

# 1. 注文情報取得クラスのインスタンス作成
ac = AmaChu.new

# 2. オプション解析
params = ac.get_params

# 3. アマゾンにログイン
ac.login

# 4. 各ページごとの処理ループに使う変数
current_page = 1
done_count = 0
total_amount = 0

# 5. 以下のbegin〜endを1ページ目から最終ページまで回す
begin

  # 注文履歴のページを取得
  ac.get_history_page(current_page)

  # 1ページ目の場合、注文総数を取得
  if current_page == 1 then
    ac.quit('対象年の注文は無かったため、終了します。') if ac.total_num_orders <= 0
    ac.progress_log
  end

  # ページ内の注文データを取得
  ac.wait(current_page).fetch_orders

  # 結果を出力
  ac.each_order do |order|

    order.output(params)

    total_amount += order.total_amount
    done_count += 1
    ac.progress_log(done_count)
  end

  # 処理対象ページをインクリメント
  current_page += 1

end while (current_page <= ac.total_num_pages)

# 6.終了処理
total_amount = total_amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
puts("\n総合計：#{total_amount} 円")
ac.quit

