require "open-uri"
require "nokogiri"
require "csv"

$base = "http://aucfree.com/"

def get_doc(url)
	charset = nil
	html = open(url) do |f|
		charset = f.charset
		f.read
	end

	return Nokogiri::HTML.parse(html, nil, charset)
end

def get_aucfree_url(from, to, user_id, page = 1)
	return  $base + "search?" + "from=" + from + "&o=t2" + "&p=" + page.to_s + "&seller=" + user_id + "&to=" + to
end

def usage()
	STDERR.puts "使い方： ruby aucfree.rb 保存csvファイル名 開始月(YYYY-MM) 終了月(YYYY-MM) ユーザID"
	STDERR.puts "例　　： ruby aucfree.rb 2016.csv 2016-01 2016-12 foobaron"
	exit(1)
end

def date_fmt(str)
	if ARGV[1] =~ /^[0-9]{4,4}-[0-9]{2,2}$/ then
		return true
	else
		return false
	end
end

def check_argv(argv)
	file = user_id = from = to = ""

	if argv.length != 4 then
		usage()
	else
		file = ARGV[0]
		if date_fmt(ARGV[1]) == true then
			from = ARGV[1]
		else
			usage()
		end
		if date_fmt(ARGV[2]) == true then
			to = ARGV[2]
		else
			usage()
		end
		if date_fmt(ARGV[3]) == true then
			user_id = ARGV[3]
		else
			usage()
		end
	end

	return file, from, to, user_id
end

file, from, to, user_id = check_argv(ARGV)

url = get_aucfree_url(from, to, user_id, 1)
doc = get_doc(url)

total = doc.css("p.sort_count").text.match(/約.*件/).to_s.gsub(/約/, "").gsub(/件/, "").gsub(/,/, "").to_i
pages = total / 50
total_cost = 0

STDERR.puts "合計#{pages}ページあります"

csv = CSV.open(file, "w", :encoding => "SJIS")
for page in 1..pages do
	STDERR.puts "#{page}ページ目の取得開始"

	url  = get_aucfree_url(from, to, user_id, page)
	d = get_doc(url)

	d.css("tr.results_bid.hover_on").each do |tr|
		date       = tr.children.css("td.results-limit").text.match(/[0-9]{4,4}年[0-9]{1,2}月[0-9]{1,2}日/).to_s
		title      = tr.children.css("a.item_title").text
		price      = tr.children.css("a.item_price").text.gsub(/,/, "").gsub(/円/, "").to_i
		sub_url    = $base + tr.children.css("a").attribute("href").text
		sub_d      = get_doc(sub_url)
		auction_id = sub_d.css("dl.auction_id").children.css("dd").text.match(/\S+/).to_s
		csv << [date, auction_id, title, price]
		total_cost += price
	end
end
csv.close

STDERR.puts "処理が完了しました"
STDERR.puts "合計金額は#{total_cost}円です"
