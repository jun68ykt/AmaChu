/*
 * ----------------------------------------------------------------
 *
 *               Amazon Japan 注文履歴データ取得スクリプト
 *
 *                                                  2017.2.13 ykt68
 * ----------------------------------------------------------------
 */
var order_details = {};

var order_info = $('div.order-info', $(arguments[0]));

var text_ary = [];
$('span', order_info).each(function () {
  var text = $(this).text().trim();
  if (text.length > 0)
    text_ary.push(text);
});

for (var i = 0; i < text_ary.length; ++i) {
  var s = text_ary[i];
  if (s == '注文日' && i + 1 < text_ary.length)
    order_details.date = text_ary[i + 1];
  else if (s == '合計' && i + 1 < text_ary.length)
    order_details.total_amount = text_ary[i + 1];
  else if (s == '注文番号' && i + 1 < text_ary.length)
    order_details.order_id = text_ary[i + 1];
}

order_details.items = [];

for (var div_items = order_info.next(); div_items; div_items = div_items.next()) {
  if (div_items.prop('tagName') != 'DIV' || div_items[0].className.indexOf('a-box') < 0)
    break;

  $('div.a-fixed-left-grid-col.a-col-right', div_items).each(function () {
      var item = {};
      $('span', $(this)).each(function () {
        var str = $(this).text().replace(/\s/g, '');
        if (str.length > 0 && /￥\s*[0-9,]*[0-9]/.test(str)) {
          item.price = str;
          return;
        }
      });

      $('a', $(this)).each(function () {
        if ($(this).attr('href').indexOf('seller') < 0) {
          var text = $(this).text().replace(/\s/g, '');
          if (text.length > 0) {
            item.name = text;
            return;
          }
        }
      });
      order_details.items.push(item);
    }
  );
}
