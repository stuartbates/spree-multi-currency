# encoding: utf-8

require 'open-uri'
require 'nokogiri'

# add custom rake tasks here
namespace :spree_multi_currency do
  eur_hash = { num_code: '978', char_code: 'EUR', name: 'Euro' }

  namespace :currency do

    desc 'Load currency ISO4217 http://en.wikipedia.org/wiki/ISO_4217'
    task :iso4217 => :environment do
      locale_preset = { en: 'USD', de: 'EUR', ru: 'RUB' }
      errors_array = []
      url = 'http://en.wikipedia.org/wiki/ISO_4217'
      data = Nokogiri::HTML.parse(open(url))
      keys = [:char_code, :num_code, :discharge, :name, :countries]
      data.css('table:eq(1) tr')[1..-1].map do |d|
        Hash[*keys.zip(d.css('td').map do |x|
          x.text.strip
        end).flatten]
      end.each do |n|
        n[:locale] = locale_preset.key(n[:char_code]).to_s if locale_preset.has_value?(n[:char_code])
        begin
          Spree::Currency.find_by_num_code(n[:num_code]) ||
            Spree::Currency.create(n.except(:discharge).except(:countries))
        rescue
          errors_array << n
        end
      end
      puts "#{errors_array.count} errors during import."
      errors_array.each {|ea| puts "#{ea}/n"} if errors_array
    end

  end

  namespace :rates do

    desc 'Rates from Yahoo'
    task :yahoo, [:currency] => :environment do |t, args|
      if args.currency
        default_currency = Spree::Currency.where('char_code = :currency_code or num_code = :currency_code', currency_code: args.currency.upcase ).first
      else
        default_currency = Spree::Currency.get('978', eur_hash)
      end
      #default_currency.basic!
      # for spree 2.x require set config currency
      Spree::Config.currency = default_currency.char_code
      date = Time.now
      puts "Loads currency data from Yahoo using #{default_currency}"
      Spree::Currency.all.each do |currency|
        unless currency == default_currency
          url = "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20%28%22#{ currency.char_code }#{ default_currency.char_code }%22%29&format=json&env=store://datatables.org/alltableswithkeys&callback="
          @data = JSON.load(open(url))
          @value = BigDecimal(@data['query']['results']['rate']['Rate'])

          Spree::CurrencyConverter.add(currency, date, @value, 1)
        end
      end
    end
  end
end
