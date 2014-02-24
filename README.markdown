# Spree Multi-Currency

Support different currency and recalculate price from one to another

Installation
---------
Add to Gemfile

    gem "spree_multi_currency", :github => "stuartbates/spree-multi-currency"

Run
---
Install the migrations for two new tables (currencies and currency conversion rates):

    rake spree_multi_currency:install:migrations
    rake db:migrate

Load currencies:
---------------
Load up the list of all international currencies with corresponding codes:

	# Load currency ISO4217 table from Wikipedia http://en.wikipedia.org/wiki/ISO_4217
    rake spree_multi_currency:currency:iso4217

This step is not obligatory, i.e. you can manually fill up the 'currencies' table, but it's more practical to load the list with rake task above (and be sure the codes are OK), and then remove the currencies you don't want to support.

Rake tasks will set 'locale' automatically for the currencies USD, EUR, RUB. For other currencies you have to do this manually.

If you want get amount in base currency use base_total

Load rates:
----------
**Warning** Rates are being calculated relative to currency configured as 'basic'. It is therefore obligatory to visit Spree admin panel (or use Rails console) and edit one of the currencies to be the 'basic' one.

Basic currency is also the one considered to be stored as product prices, shipment rates etc., from which all the other ones will be calculated using the rates.

After setting the basic currency, time to load the rates using one of the rake tasks below. There are three sources of conversion rates supported by this extension:

1. Rates from Yahoo.

        rake spree_multi_currency:rates:yahoo[gbp]

There's also an optional square-bracket-enclosed parameter "load_currencies" for :rates tasks above, but it just loads up currencies table from Wikipedia, so is not needed at this point.

Settings
---------
In Spree Admin Panel, Configuration tab, two new options appear: Currency Settings and Currency Converters.

It's best to leave Currency Converters as-is, to be populated and updated by rake spree_multi_currency:rates tasks.

Within Currency Settings, like mentioned above, it is essential to set one currency as the Basic one. It's also necessary to set currency's locale for every locale you want to support (again, one locale - one currency).
Feel free to go through currencies and delete the ones you don't want to support -- it will make everything easier to manage (and the :rates rake tasks will execute faster).

Changing Currency in store
--------------------------
Self-explanatory:

    http://[domain]/currency/[isocode]
    <%= link_to raw "&euro;", currency_path(:eur) %>


## Technical Overview

- We introduce 2 new models
  - currency.rb
  - currency_converter.rb

The `Currency` model represents a single currency e.g. GBP, EUR, USD etc…  Each currency object HAS_MANY `CurrencyConverter`(s) each of which represent a conversion rate at a particular point in time for the currency it belongs to.

One currency must be defined as the basic currency - this is the currency from which all calculations are based on.  The currency model has an instance method called `basic!` which will set this currency as the basic currency.

The currency model has a series of class methods that deal with price conversion between different currencies.

	def convert(value, from, to)
	end
	
	def conversion_to_current(value, options = {})
	end
	
	def conversion_from_current(value, options = {})
	end
	
The `CurrencyConverter` model is a very thin model which simply stores the values to provide historic snapshots of conversion rates.

There's also numerous model decorators that are provided to override price getters ensuring a converted price can be returned.  The `variant_decorator.rb` is a good example of this which overrides `price_in`.

Price in normally just searches for an entry in the prices table - however the newly decorated version of the method searches and if not found creates a new entry in the prices table.

The `product_decorator.rb` basically just overrides the definition of available now… WHY?

The gem also adds a `multi_currency` mixin which makes use of meta-programming to allow any attribute that returns a price/amount to be returned in the current currency.

	Spree::Adjustment.class_eval do
	  extend Spree::MultiCurrency
	  multi_currency :amount
	end
	
This means you can call the `amount` method on the an adjustments instance and the returned value will be in the current currency - not the default currency.