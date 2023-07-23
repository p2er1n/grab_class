#!/bin/env elvish

# 询问会话id
echo '请输入你的sessionid：';
var session_id = (read-line);

# 询问课程类型
echo '请输入你的课程类型(1.必修 2.选修):';
var class_type = (read-line);
if (or (eq $class_type 1) (eq $class_type '必修')) {
  set class_type = 1;
} elif (or (eq $class_type 2) (eq $class_type '选修')) {
  set class_type = 2;
} else {
  echo '课程类需输入错误，请输入课程序号或者名称！';
  exit;
}

# 询问选课名称
echo '请输入你要选的课程的名称:';
var class_name = (read-line);
if (eq $class_name '') {
  echo '课程名称不能为空！';
  exit;
}

# 搜索可能匹配的课程
# 必修选课课表 url: http://jwgl.sdust.edu.cn/jsxsd/xsxkkcRedis/xsxkBxxk - 青岛校区体育课选课
# 选修选课课表 url: http://jwgl.sdust.edu.cn/jsxsd/xsxkkcRedis/xsxkXxxk - 青岛校区专业选修课补选
fn remove_white_spaces {
  var str = (read-upto "\x00");
  var res = '';
  for c $str {
    if (not (or (eq $c ' ') (eq $c "\n"))) {
      set res = $res$c;
    }
  }
  put $res;
};
var class_list;
if (eq $class_type 1) {
  set class_list = (curl -s 'http://jwgl.sdust.edu.cn/jsxsd/xsxkkcRedis/xsxkBxxk' --compressed -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0' -H 'Accept: */*' -H 'Accept-Language: zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2' -H 'Accept-Encoding: gzip, deflate' -H 'Content-Type: application/x-www-form-urlencoded' -H 'X-Requested-With: XMLHttpRequest' -H 'Origin: http://jwgl.sdust.edu.cn' -H 'Connection: keep-alive' -H 'Referer: http://jwgl.sdust.edu.cn/jsxsd/xsxkkcRedis/comeInBxxk' -H 'Cookie: JSESSIONID='$session_id --data-raw 'sEcho=1&iColumns=12&sColumns=&iDisplayStart=0&iDisplayLength=15&mDataProp_0=kch&mDataProp_1=kcmc&mDataProp_2=fzmc&mDataProp_3=xf&mDataProp_4=skls&mDataProp_5=ktmc&mDataProp_6=sksj&mDataProp_7=skdd&mDataProp_8=xqmc&mDataProp_9=ctsm&mDataProp_10=txkbz&mDataProp_11=czOper' | jq '[.aaData[] |{kcmc: .kcmc, jx0404id: .jx0404id, jx02id: .jx02id, fzmc: .fzmc}]' | slurp);
} elif (eq $class_type 2) {
  set class_list = (curl -s 'http://jwgl.sdust.edu.cn/jsxsd/xsxkkcRedis/xsxkXxxk' --compressed -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0' -H 'Accept: */*' -H 'Accept-Language: zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2' -H 'Accept-Encoding: gzip, deflate' -H 'Content-Type: application/x-www-form-urlencoded' -H 'X-Requested-With: XMLHttpRequest' -H 'Origin: http://jwgl.sdust.edu.cn' -H 'Connection: keep-alive' -H 'Referer: http://jwgl.sdust.edu.cn/jsxsd/xsxkkcRedis/comeInXxxk' -H 'Cookie: JSESSIONID='$session_id --data-raw 'sEcho=1&iColumns=13&sColumns=&iDisplayStart=0&iDisplayLength=15&mDataProp_0=kch&mDataProp_1=kcmc&mDataProp_2=kcfx&mDataProp_3=fzmc&mDataProp_4=xf&mDataProp_5=skls&mDataProp_6=ktmc&mDataProp_7=sksj&mDataProp_8=skdd&mDataProp_9=xqmc&mDataProp_10=ctsm&mDataProp_11=txkbz&mDataProp_12=czOper' | jq '[.aaData[] |{kcmc: .kcmc, jx0404id: .jx0404id, jx02id: .jx02id, fzmc: .fzmc}]' | slurp);
}
var possible_class_list_idx = '';
var cnt = 0;
echo $class_list | jq '.[] | .kcmc' | each {|item|
  use re;
  if (re:match $class_name $item) {
    set possible_class_list_idx = $possible_class_list_idx' '$cnt;
  }
  set cnt = (+ $cnt 1);
}
if (eq $possible_class_list_idx '') {
  echo '未找到相关课程！';
  exit;
} else {
  use str;
  str:split ' ' $possible_class_list_idx | take 10000 | each {|idx|
    if (not (eq $idx '')) {
      echo $class_list | jq '.['$idx'] | .kcmc, .fzmc, .jx0404id, .jx02id'
    }
  }
}

# 开始抢课
echo '输入课程id(jx02id):';
var kcid = (read-line);
echo '输入jx0404id:';
var jx0404id = (read-line);
curl 'http://jwgl.sdust.edu.cn/jsxsd/xsxkkcRedis/bxxkOper?kcid='$kcid'&cfbs=null&jx0404id='$jx0404id --compressed -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0' -H 'Accept: */*' -H 'Accept-Language: zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2' -H 'Accept-Encoding: gzip, deflate' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'Referer: http://jwgl.sdust.edu.cn/jsxsd/xsxkkcRedis/comeInBxxk' -H 'Cookie: JSESSIONID='$session_id;
