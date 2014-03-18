# encoding: utf-8

Spree::OrderContents.class_eval do

  def set_currency
    self.currency = 'GBP'
  end

end
