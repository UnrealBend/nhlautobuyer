def handle_trades(session, credits, trades)

  puts "Checking #{trades.length} trades."

  trades.find_all {|trade| trade.buy_it_now == 0 }.each do |trade|
    if (credits >= trade.bin)
      puts "You should buy #{trade.card.player_type.name} #{trade.card.name} for #{trade.bin.with_commas} at #{EaUrls.bid_url(session, trade.trade_id, trade.bin)}"
      puts "You were #{Bid.do_bid(session, trade.trade_id, trade.bin)} in buying #{trade.card.player_type.name} #{trade.card.name} for #{trade.bin}"
      purchase = Purchase.new
      purchase.player_type = trade.card.player_type.name
      purchase.player_name = trade.card.name
      purchase.amount = trade.bin
      purchase.status = "Bought"
      purchase.save
    else
      puts "You misssed #{trade.card.player_type.name} #{trade.card.name} for #{trade.bin.with_commas} by #{trade.bin - trade.credits} pucks."
      purchase = Purchase.new
      purchase.player_type = trade.card.player_type.name
      purchase.player_name = trade.card.name
      purchase.amount = trade.bin
      purchase.status = "Missed"
      purchase.save
    end
  end

end

def perform_login(login)

  EaSession.all.each {|session| session.destroy }
  current_session = EaUrls.login(login)

  begin
    do_searches(current_session)
  rescue
    puts "Something bad happened at #{Time.now.strftime('%H:%M:%S')}"
    sleep(30)
    perform_login(login)
  end
end

def do_searches(current_session)
  random = Random.new
  puts "Current session is #{current_session.session_key}"
  while(1==1) do
    puts "Getting searches at #{Time.now.strftime('%H:%M:%S')}"
    credits = CheckCredits.check_credits(current_session)

    puts "You currently have #{credits.with_commas} pucks."

    Search.where(:use_autobuyer => true).order(:name).each do |search|

      puts "Searching for #{search.name}"
      handle_trades(current_session, credits, Searches.get_search(current_session, search))
      puts "\n"
      sleep(random.rand(2..3))
    end
  end
end

login = Login.new
login.username = UnrealBend
login.email = mase72@live.ca

puts 'Enter password:'
login.password = gets.chomp

perform_login(login)

